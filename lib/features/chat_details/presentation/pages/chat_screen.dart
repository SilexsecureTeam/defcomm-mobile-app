import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/models/typing_status.dart';
import 'package:defcomm/core/pusher/pusher_service.dart';
import 'package:defcomm/core/services/friendly_errors.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/core/utils/call_utils.dart';
import 'package:defcomm/features/calling/call_control_constants.dart';
import 'package:defcomm/features/calling/domain/repositories/call_repository.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_bloc.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_cubit.dart';
import 'package:defcomm/features/calling/presentation/pages/secure_calling.dart';
import 'package:defcomm/features/calling/presentation/pages/secure_calling_1.dart';
import 'package:defcomm/features/chat_details/data/models/chat_messge_model.dart';
import 'package:defcomm/features/chat_details/data/models/chat_user_model.dart';
import 'package:defcomm/features/chat_details/domain/entities/chat_message.dart';
import 'package:defcomm/features/chat_details/domain/usecases/send_message.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_bloc.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_event.dart';
import 'package:defcomm/features/chat_details/presentation/widgets/__message_input_field.dart';
import 'package:defcomm/features/chat_details/presentation/widgets/chat_message_bubble.dart';
import 'package:defcomm/features/chat_details/presentation/widgets/reading_options_dialog.dart';
import 'package:defcomm/features/chat_details/presentation/widgets/shield_message_wrapper.dart';
import 'package:defcomm/features/secure_comms/presentation/pages/secure_comms_screen.dart';
import 'package:defcomm/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:defcomm/features/settings/presentation/bloc/settings_state.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final box = GetStorage();
  final _scrollController = ScrollController();
  bool _isPlacingCall = false;

  StreamSubscription? _connectivitySubscription;

  String get myUserId => box.read("userEnId");

  final Map<String, bool> _isHiddenByMessageId = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final bloc = context.read<ChatDetailBloc>();
    // bloc.add(ChatReset());
    bloc.add(MessagesFetched(widget.user.id));

    if (serviceLocator.isRegistered<PusherService>()) {
      serviceLocator<PusherService>().setActiveChat(widget.user.id);
    }

     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // If we have ANY connection (mobile, wifi, ethernet, etc.)
      // and it is NOT 'none'
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint("🌐 Network restored: Retrying chat sync...");
        
        // Trigger the fetch again.
        // The Bloc's _isFetching flag prevents spamming if it's already running.
        bloc.add(MessagesFetched(widget.user.id));
        
        // Optional: Re-subscribe to Pusher if needed
        if (serviceLocator.isRegistered<PusherService>()) {
          serviceLocator<PusherService>().reconnect(); // Assuming you have a reconnect method
        }
      }
    });
  }

  bool _isHidden(String messageId) {
    return _isHiddenByMessageId[messageId] ?? true;
  }

  void _onScroll() {
    final state = context.read<ChatDetailBloc>().state;
    if (_isAtTop && state is ChatDetailLoaded && !state.hasReachedMax) {
      context.read<ChatDetailBloc>().add(MessagesFetched(widget.user.id));
    }
  }

  bool get _isAtTop {
    if (!_scrollController.hasClients) return false;
    return _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent;
  }

  @override
  void dispose() {
    if (serviceLocator.isRegistered<PusherService>()) {
      serviceLocator<PusherService>().setActiveChat(null);
    }

    _connectivitySubscription?.cancel();
    
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  final Set<String> _revealedMessageIds = {};

  String? _currentlyRevealedId;



  // 2. CHANGE THE TOGGLE FUNCTION
  void _toggleReveal(String messageId) {
    setState(() {
      // if (_revealedMessageIds.contains(messageId)) {
      //   _revealedMessageIds.remove(messageId); // Hide it again
      // } else {
      //   _revealedMessageIds.add(messageId); // Reveal it
      // }
      if (_currentlyRevealedId == messageId) {
      // If clicking the one currently open, close it.
      _currentlyRevealedId = null; 
    } else {
      // Otherwise, open this one (and implicitly close the previous one)
      _currentlyRevealedId = messageId;
    }
    });
  }


  void _onCallPressed() async {
    final callManager = serviceLocator<CallManager>();

    // Try to acquire global call lock
    final acquired = callManager.startCall();
    if (!acquired) {
      Fluttertoast.showToast(msg: 'A call is already in progress');
      debugPrint('Call blocked: another call is in progress');
      return;
    }

    // Make sure to release the lock if anything fails below:
    var lockReleased = false;
    void releaseLockIfNeeded() {
      if (!lockReleased) {
        lockReleased = true;
        callManager.endCall();
      }
    }

    final myIdEn = box.read("userEnId") as String;
    final otherIdEn = widget.user.id;


    try {

      final callRepo = serviceLocator<CallRepository>();
      final String roomId = await callRepo.createMeetingId();

      debugPrint("✅ VideoSDK Room Ready: $roomId");

      final myIdEn = box.read("userEnId") as String;
      final otherIdEn = widget.user.id;
      final sendMessageUseCase = serviceLocator<SendMessage>();


      await sendMessageUseCase(
        SendMessageParams(
          message: "$kCallControlInvitePrefix$roomId",
          isFile: false,
          chatUserType: 'user',
          currentChatUser: otherIdEn,
          chatId: null,
          mssType: 'call',
        ),
      );
    } catch (e) {
      debugPrint('Error sending call signal: $e');
      // release lock because we couldn't notify backend
      releaseLockIfNeeded();
      return;
    }

    //  // using the call bloc

    // push call UI and keep lock until call screen is popped or CallEnded happens
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'secure_call'),
            builder: (_) => BlocProvider.value(
              value: serviceLocator<CallBloc>(),
              child: SecureCallingScreen(
                isCaller: true,
                meetingId: null,
                otherUserName: widget.user.name,
                peerIdEn: widget.user.id,
              ),
            ),
          ),
        )
        .then((_) {
          // When call screen popped, ensure lock is released
          releaseLockIfNeeded();
        });
  }

  void _toggleHidden(String messageId) {
    setState(() {
      final cur = _isHiddenByMessageId[messageId] ?? true;
      _isHiddenByMessageId[messageId] = !cur;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tertiaryGreen,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.dashboardBackgroundColor,
              ),
            ),
            Positioned.fill(
        child: Image.asset(
            'images/waterMark.png', 
            fit: BoxFit.cover, 
          ),
      ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 5.0,
                    right: 8.0,
                  ),
                  child: _buildCustomAppBar(
                    context,
                    widget.user.name,
                    _onCallPressed,
                  ),
                ),
                _buildSectionHeader(),

                Expanded(
                  // 1. First BlocBuilder listens to Chat Data
                  child: Stack(
                    
                    children: [

                       
                      BlocBuilder<ChatDetailBloc, ChatDetailState>(
                        builder: (context, chatState) {
                          // if (chatState is ChatDetailInitial ||
                          //     chatState is ChatDetailLoading) {
                          //   return const Center(
                          //     child: CircularProgressIndicator(),
                          //   );
                          // }
                                      
                          if (chatState is ChatDetailFailure) {
                            // debugPrint("error: ${chatState.message}");
                            // Fluttertoast.showToast(msg: "Something went wrong");
                            // return   _buildErrorView(chatState.message);
                            // Center(
                            //   child: Text(
                            //     chatState.message,
                            //     style: const TextStyle(color: Colors.red),
                            //   ),
                            // );
                      
                            Fluttertoast.showToast(
                            msg: 
                                 "Offline: Showing cached messages" ,
                                
                            toastLength: Toast.LENGTH_SHORT,
                            // textColor: Colors.white,
                          );
                          }
                                      
                          if (chatState is ChatDetailLoaded) {
                            final messages = chatState.messages;
                            if (messages.isEmpty) {
                              return const Center(
                                child: Text("No messages here yet."),
                              );
                            }
                                      
                            // 2. Second BlocBuilder listens to Settings (Shield Method)
                            return BlocBuilder<SettingsBloc, SettingsState>(
                              builder: (context, settingsState) {
                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  itemCount: chatState.hasReachedMax
                                      ? messages.length
                                      : messages.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index >= messages.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                      
                                    final message = messages[index];
                                    final content =
                                        message.message ??
                                        ""; // Get content safely
                                      
                                    // --- 1. CHECK FOR CALL STATUS MESSAGES ---
                                    final callStatusText = getCallStatusMessage(
                                      content,
                                    );
                                      
                                    if (callStatusText != null) {
                                      // If it is a call log, return the system widget directly.
                                      // We usually DO NOT hide these with the shield.
                                      return _buildSystemMessage(callStatusText);
                                    }
                                      
                                    final isMe = message.isMyChat;
                                    final messageId =
                                        message.id ??
                                        message.senderId ??
                                        message.hashCode.toString();
                                      
                                    final bool showUserDetails =
                                        (index == messages.length - 1 ||
                                        messages[index + 1].senderId !=
                                            message.senderId);
                                      
                                    // 3. Use the ShieldMessageWrapper
                                    // This determines if it should be Tap, LongPress, or Swipe
                                    // based on 'settingsState.shieldRevealMethod'
                                      
                                    final bool isPrivacyModeOn =
                                        settingsState.hideMessages;
                                      
                                    // final bool shouldMaskContent =
                                    //     isPrivacyModeOn && !_isHidden(messageId);
                                      
                                    final bool isGlobalHideOn =
                                        settingsState.hideMessages;
                                      
                                    
                      
                                        final bool isRevealedLocally = _currentlyRevealedId == messageId; 
                                    final bool shouldMaskContent =
                                        isGlobalHideOn && !isRevealedLocally;
                                      
                                    final messageWidget = _buildMessageGroup(
                                      message: message,
                                      isMe: isMe,
                                      showUserDetails: showUserDetails,
                                      user: isMe
                                          ? ChatUser(
                                              id: myUserId,
                                              name: 'You',
                                              imageUrl: '',
                                              role: '',
                                            )
                                          : widget.user,
                                      isHidden:
                                          shouldMaskContent, // <--- Pass the calculated value here
                                    );
                                      
                                    // 3. CONDITIONALLY WRAP
                                    // Only apply the Shield Gesture if the Global Privacy Setting is ON.
                                    if (isPrivacyModeOn) {
                                      // Privacy Mode is ON: Wrap in Shield to allow peeking
                                      return ShieldMessageWrapper(
                                        revealMethod: settingsState
                                            .shieldRevealMethod, // e.g., Tap, LongPress
                                        messageId: messageId,
                                        onReveal: () {
                                          _toggleReveal(
                                            messageId,
                                          ); // This adds ID to local list -> Reveals it
                                        },
                                        child: messageWidget,
                                      );
                                    } else {
                                      // Privacy Mode is OFF: Just show the widget (User turned it off in Settings)
                                      return messageWidget;
                                    }
                                  },
                                );
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),

                BlocBuilder<ChatDetailBloc, ChatDetailState>(
                  buildWhen: (prev, curr) =>
                      prev is ChatDetailLoaded &&
                      curr is ChatDetailLoaded &&
                      prev.isTyping != curr.isTyping,
                  builder: (context, state) {
                    if (state is ChatDetailLoaded && state.isTyping) {
                      final firstName =
                          widget.user.name.split(' ').firstOrNull ??
                          widget.user.name;

                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 4.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$firstName is typing...',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

//                 StreamBuilder<TypingStatus>(
//   stream: serviceLocator<PusherService>().typingStream,
//   builder: (context, snapshot) {
//     bool isTyping = false;

//     // Check if the event matches THIS chat user
//     if (snapshot.hasData && snapshot.data!.userId == widget.user.id) {
//       isTyping = snapshot.data!.isTyping;
//     }

//     if (!isTyping) return const SizedBox.shrink();

//     final firstName = widget.user.name.split(' ').firstOrNull ?? widget.user.name;
//     return Padding(
//       padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 4.0),
//       child: Text(
//         '$firstName is typing...',
//         style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic),
//       ),
//     );
//   },
// ),

                MessageInputField(
                  chatUserId: widget.user.id,
                  userName: widget.user.name,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(height: 20, width: 4, color: Colors.greenAccent),
          const SizedBox(width: 8),
          Text(
            'SECURE MESSAGING',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) {
                  // Pass the EXISTING SettingsBloc to the dialog
                  return BlocProvider.value(
                    value: context.read<SettingsBloc>(),
                    child: const ReadingOptionsDialog(),
                  );
                },
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(8.0), // Larger touch area
              child: Icon(Icons.more_vert, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar(
    BuildContext context,
    String? name,
    Function()? onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      color: AppColors.primaryGradientEnd,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('images/profile_img.png'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name ?? "",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'user',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
      
            child: IconButton(onPressed: onTap, icon: Icon(Icons.call)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageGroup({
    required ChatMessage message,
    required bool isMe,
    required bool showUserDetails,
    required ChatUser user,
    required bool isHidden,
    Function()? onToggleHidden,
  }) {
    const double avatarAndPaddingWidth = 50.0;

    // The avatar widget itself
    final avatar = CircleAvatar(
      radius: 20,
      backgroundImage: AssetImage(user.imageUrl),
    );

    final avatarSpacer = SizedBox(width: avatarAndPaddingWidth);

    return Padding(
      padding: EdgeInsets.only(bottom: showUserDetails ? 10.0 : 4.0),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showUserDetails)
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : avatarAndPaddingWidth,
                right: isMe ? avatarAndPaddingWidth : 0,
                bottom: 4,
              ),
              child: Row(
                mainAxisAlignment: isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.roboto(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: ChatMessageBubble(
                  message: message,
                  isMe: isMe,
                  isHidden: isHidden,
                  //  onToggleHidden: onToggleHidden ?? () {
                  // Fluttertoast.showToast(msg: "encryted error", timeInSecForIosWeb: 5);
                  // },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black26, // Semi-transparent dark background
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.call, size: 14, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String rawError) {
  final friendlyMessage = getUserFriendlyError(rawError);

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Icon
          Icon(
            Icons.wifi_off_rounded, // Or Icons.error_outline
            size: 60,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          
          // 2. Title
          Text(
            "oops!",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 3. Description
          Text(
            friendlyMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // 4. Retry Button
          SizedBox(
            width: 140,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), // Your App Green
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              onPressed: () {
                // TRIGGER THE LOAD EVENT AGAIN
                // Assuming your event is named GetChatMessages or similar
                // You need to pass the conversation ID or User again
                final chatId = widget.user.id ?? ''; // Ensure you have the ID
                context.read<ChatDetailBloc>().add(MessagesFetched(widget.user.id)); 
                context.read<ChatDetailBloc>().add(ChatReset()); 

              },
              child: Text(
                "Retry",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}




// 
//