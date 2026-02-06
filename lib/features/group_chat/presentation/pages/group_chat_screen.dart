import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/pusher/pusher_service.dart';
import 'package:defcomm/core/services/friendly_errors.dart';
import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/features/calling/call_control_constants.dart';
import 'package:defcomm/features/chat_details/presentation/widgets/shield_message_wrapper.dart';
import 'package:defcomm/features/group_calling/core/group_call_constants.dart';
import 'package:defcomm/features/group_calling/domain/repositories/group_call_repository.dart';
import 'package:defcomm/features/group_calling/domain/usecase/start_group_call.dart';
import 'package:defcomm/features/group_calling/presentation/bloc/group_call_bloc.dart';
import 'package:defcomm/features/group_calling/presentation/bloc/group_call_events.dart';
import 'package:defcomm/features/group_calling/presentation/pages/group_call_screen.dart';
import 'package:defcomm/features/group_chat/presentation/models/group_membr_ui.dart';
import 'package:defcomm/features/group_chat/presentation/widgets/group_invite_bubble.dart';
import 'package:defcomm/features/group_chat/presentation/widgets/group_message_input.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_embers_state.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_mebers_event.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_member_bloc.dart';
import 'package:defcomm/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:defcomm/features/settings/presentation/bloc/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../groups/domain/entities/group_entity.dart'; 
import '../bloc/group_chat_bloc.dart';
import '../bloc/group_chat_event.dart';
import '../bloc/group_chat_state.dart';
import '../../domain/entities/group_chat_message.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupEntity? group;

  final String groupIdEn;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.group,
    required this.groupIdEn,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _scrollController = ScrollController();

  StreamSubscription? _connectivitySubscription;

  String get groupUserIdEn => widget.group!.groupId; 

  final Set<String> _processedAutoRingIds = {};


  String? _currentlyRevealedId;

  

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    context.read<GroupChatBloc>().add(GroupMessagesFetched(groupUserIdEn));

    context.read<GroupMembersBloc>().add(FetchGroupMembers(groupUserIdEn));

    if (serviceLocator.isRegistered<PusherService>()) {
      final pusher = serviceLocator<PusherService>();

      pusher.setActiveChat(groupUserIdEn);

      pusher.subscribeToGroupChannel(groupUserIdEn);
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint("🌐 Network restored in Group Chat: Syncing...");

        context.read<GroupChatBloc>().add(GroupMessagesFetched(groupUserIdEn));

        if (serviceLocator.isRegistered<PusherService>()) {
          serviceLocator<PusherService>().reconnect();
          serviceLocator<PusherService>().subscribeToGroupChannel(
            groupUserIdEn,
          );
        }
      }
    });
  }

  void _onScroll() {
    final state = context.read<GroupChatBloc>().state;
    if (!_scrollController.hasClients) return;
    final atTop =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent;
    if (atTop && state is GroupChatLoaded && !state.hasReachedMax) {
      context.read<GroupChatBloc>().add(GroupMessagesFetched(groupUserIdEn));
    }
  }

  @override
  void dispose() {
    if (serviceLocator.isRegistered<PusherService>()) {
      final pusher = serviceLocator<PusherService>();

      pusher.setActiveChat(null);

      // pusher.unsubscribeFromGroupChannel(groupUserIdEn);
    }

    _connectivitySubscription?.cancel();

    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }


 
  void _toggleReveal(String messageId) {
    setState(() {
      
      if (_currentlyRevealedId == messageId) {
      _currentlyRevealedId = null; 
    } else {
      _currentlyRevealedId = messageId;
    }
    });
  }

  void _joinCall(String roomId, {bool isAutoRing = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<GroupCallBloc>(
          create: (_) => GroupCallBloc(
            startGroupCall: serviceLocator<StartGroupCall>(),
            repository: serviceLocator<GroupCallRepository>(),
            callManager: serviceLocator<CallManager>(),
            currentUserId:
                'CURRENT_USER_ID',
          ),
          child: GroupCallScreen(
            groupId: widget.groupIdEn,
            roomId: roomId,
            isCreator: false, 
            groupName: widget.groupName,
            displayName: "Me", 
            autoJoin: !isAutoRing,
          ),
        ),
      ),
    );
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
            Column(
              children: [
                _buildAppBar(context),
                const SizedBox(height: 8),

                Expanded(
                  child: Stack(
                    children: [

                      Positioned.fill(
        child: Image.asset(
            'images/waterMark.png', 
            fit: BoxFit.cover,           ),
      ),
      
                      BlocConsumer<GroupChatBloc, GroupChatState>(
                        listener: (context, state) {
                          if (state is GroupChatFailure) {
                            Fluttertoast.showToast(msg: "Could not sync messages");
                          }
                      
                          if (state is GroupChatLoaded) {
                            if (state.messages.isNotEmpty) {
                              final latest = state.messages.first;
                              final content = latest.message ?? "";
                      
                              final isInvite = content.isGroupCallInvite;
                              final isNotMe = !latest.isMyChat;
                      
                              final now = DateTime.now();
                              final msgTime =
                                  DateTime.tryParse(latest.createdAt) ?? now;
                              final isRecent =
                                  now.difference(msgTime).inSeconds.abs() < 15;
                              //
                              final messageId =
                                  latest.id ?? latest.hashCode.toString();
                              //
                      
                              if (isInvite && isNotMe && isRecent) {
                                _processedAutoRingIds.add(messageId);
                      
                                final roomId = content.extractRoomId;
                      
                                _joinCall(roomId, isAutoRing: true);
                              }
                            }
                          }
                        },
                        builder: (context, state) {
                          if (state is GroupChatFailure) {
                            return Center(child: _buildErrorView(state.message));
                          }
                      
                          if (state is GroupChatLoaded) {
                            if (state.messages.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No messages in this group yet.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                      
                            return BlocBuilder<SettingsBloc, SettingsState>(
                              builder: (context, settingsState) {
                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  itemCount: state.hasReachedMax
                                      ? state.messages.length
                                      : state.messages.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index >= state.messages.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                      
                                    final message = state.messages[index];
                                    final content = message.message ?? "";
                      
                                    if (content.isGroupControlSignal ||
                                        content.isGroupCallEnded || content.contains("__DEFCOMM_GROUP_CALL_ENDED_v1__")) {
                                      return const SizedBox.shrink();
                                    }
                      
                                    if (content.isGroupCallInvite) {
                                      final bool isEndedLocally = state.endedCallIds.contains(message.id);
                                      return GroupCallInviteBubble(
                                        isEnded: isEndedLocally,
                                        message: message,
                                        onJoin: () {
                                          final roomId = content.extractRoomId;
                                          _joinCall(roomId, isAutoRing: false);
                                        },
                                      );
                                    }
                      
                                    final callStatusText = getCallStatusMessage(
                                      content,
                                    );
                                    if (callStatusText != null) {
                                      return _buildSystemMessage(callStatusText);
                                    }
                      
                                    final isMe = message.isMyChat;
                                    final messageId =
                                        message.id ??
                                        message.senderId ??
                                        message.hashCode.toString();
                      
                                    final bool showUserDetails =
                                        (index == state.messages.length - 1 ||
                                        state.messages[index + 1].senderId !=
                                            message.senderId);
                      
                                    final bool isPrivacyModeOn =
                                        settingsState.hideMessages;
                                    final bool isRevealedLocally = _currentlyRevealedId == messageId; 
                                    final bool shouldMaskContent =
                                        isPrivacyModeOn && !isRevealedLocally;
                      
                                    final messageWidget = _buildMessageBubble(
                                      message: message,
                                      isMe: isMe,
                                      showUserHeader: showUserDetails,
                                      isHidden: shouldMaskContent,
                                    );
                      
                                    if (isPrivacyModeOn) {
                                      return ShieldMessageWrapper(
                                        revealMethod:
                                            settingsState.shieldRevealMethod,
                                        messageId: messageId,
                                        onReveal: () {
                                          _toggleReveal(messageId);
                                        },
                                        child: messageWidget,
                                      );
                                    } else {
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

                BlocBuilder<GroupMembersBloc, GroupMembersState>(
                  builder: (context, membersState) {
                    List<GroupMemberUi> uiMembers = [];

                    if (membersState is GroupMembersLoaded) {
                      uiMembers = membersState.members
                          .where((m) => (m.memberIdEncrypt ?? '').isNotEmpty)
                          .map(
                            (m) => GroupMemberUi(
                              id: m
                                  .memberIdEncrypt!, 
                              displayName:
                                  (m.memberName ?? '').trim().isNotEmpty
                                  ? m.memberName!.trim()
                                  : 'Unknown user',
                            ),
                          )
                          .toList();
                    }

                    return GroupMessageInput(
                      groupUserIdEn: groupUserIdEn,
                      members: uiMembers,
                    );
                  },
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const BackButton(color: Colors.white),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: Text(
                  widget.group!.groupName.isNotEmpty
                      ? widget.group!.groupName[0].toUpperCase()
                      : 'G',
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group!.groupName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Group chat',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () async {
              final callManager = serviceLocator<CallManager>();
              if (!callManager.startCall()) {
                Fluttertoast.showToast(msg: 'Another call is in progress');
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider<GroupCallBloc>(
                    create: (_) => GroupCallBloc(
                      startGroupCall: serviceLocator<StartGroupCall>(),
                      repository: serviceLocator<GroupCallRepository>(),
                      callManager: serviceLocator<CallManager>(),
                      currentUserId: 'mm',
                      
                    ),
                    child: GroupCallScreen(
                      groupId: widget.groupIdEn,
                      roomId: "",
                      isCreator: true,
                      groupName: widget.groupName,
                      displayName: "You",
                    ),
                  ),
                ),
              );
            },
            icon: Icon(Icons.call, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required GroupChatMessage message,
    required bool isMe,
    required bool showUserHeader,
    required bool isHidden,
  }) {
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAxisAlign = isMe
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
    final contentText = isHidden ? '*********' : (message.message ?? '');

    return Padding(
      padding: EdgeInsets.only(bottom: showUserHeader ? 10 : 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (showUserHeader)
            Padding(
              padding: EdgeInsets.only(
                left: isMe ? 0 : 40,
                right: isMe ? 40 : 0,
                bottom: 2,
              ),
              child: Text(
                message.senderName,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
              ),
            ),
          Row(
            mainAxisAlignment: mainAxisAlign,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.settingAccountGreen
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: alignment,
                    children: [
                      if (message.tagMessageText != null &&
                          message.tagMessageText!.trim().isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message.tagMessageText!,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      // Actual message
                      Text(
                        contentText,
                        // message.message ?? '',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
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
            color: Colors.black26, 
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
              Icons.wifi_off_rounded, 
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

            Text(
              friendlyMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // 4. Retry Button
            SizedBox(
              width: 140,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  
                  context.read<GroupChatBloc>().add(
                    GroupMessagesFetched(groupUserIdEn),
                  );
                  context.read<GroupMembersBloc>().add(
                    FetchGroupMembers(groupUserIdEn),
                  );

                  if (serviceLocator.isRegistered<PusherService>()) {
                    serviceLocator<PusherService>().setActiveChat(
                      groupUserIdEn,
                    );
                  }
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
