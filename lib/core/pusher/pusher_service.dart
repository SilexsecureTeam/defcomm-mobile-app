import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/models/typing_status.dart';
import 'package:defcomm/core/notification/local_notifiction.dart';
import 'package:defcomm/core/services/ccallkit_service.dart';
import 'package:defcomm/core/utils/call_manager.dart';
import 'package:defcomm/features/calling/call_control_constants.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_bloc.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_cubit.dart';
import 'package:defcomm/features/calling/presentation/bloc/call_event.dart';
import 'package:defcomm/features/calling/presentation/pages/secure_calling.dart';
import 'package:defcomm/features/chat_details/domain/entities/chat_message.dart';
import 'package:defcomm/features/chat_details/domain/usecases/send_message.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_bloc.dart';
import 'package:defcomm/features/chat_details/presentation/bloc/chat_detail_event.dart';
import 'package:defcomm/features/group_calling/core/group_call_constants.dart';
import 'package:defcomm/features/group_calling/domain/repositories/group_call_repository.dart';
import 'package:defcomm/features/group_calling/presentation/bloc/group_call_bloc.dart';
import 'package:defcomm/features/group_calling/presentation/bloc/group_call_events.dart'
    hide GroupCallBloc, GroupCallEndedEvent;
import 'package:defcomm/features/group_calling/presentation/pages/group_call_screen.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_bloc.dart';
import 'package:defcomm/features/group_chat/presentation/bloc/group_chat_event.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_message_groups.dart';
import 'package:defcomm/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pusher_client_fixed/pusher_client_fixed.dart';
import '../../features/messaging/presentation/bloc/messaging_bloc.dart';
import '../../features/messaging/presentation/bloc/messaging_event.dart';
import '../../features/messaging/domain/entities/message_thread.dart';
import 'package:http/http.dart' as http;

class PusherService {
  PusherClient? _pusher;
  Channel? _channel;
  final String appKey;
  final String cluster;
  final String host;
  final String authEndpoint;
  final String token;
  final AudioPlayer _player = AudioPlayer();

  final MessagingBloc messagingBloc;
  final ChatDetailBloc chatDetailBloc;
  final GroupChatBloc groupChatBloc;
  final LocalNotificationService? localNotificationService;
  final GetMessageJoinedGroups getJoinedGroups;
  final String currentUserId;
  // final http.Client httpClient;
  // final String baseUrl;
  Channel? _groupChannel;

  String _lastConnectionState = 'DISCONNECTED';

  PusherService({
    required this.appKey,
    required this.cluster,
    required this.host,
    required this.authEndpoint,
    required this.token,
    required this.messagingBloc,
    required this.chatDetailBloc,
    required this.groupChatBloc,
    required this.currentUserId,
    this.localNotificationService,
    required this.getJoinedGroups,
    // required this.httpClient,
    // required this.baseUrl,
  });

  String? _activeChatId; // the currently open chat user id (nullable)

  final Set<String> _subscribedGroups = {};

  // Monitor connectivity
  StreamSubscription? _connectivitySubscription;

  final StreamController<TypingStatus> _typingController = StreamController<TypingStatus>.broadcast();

  // 2. Expose Stream Getter
  Stream<TypingStatus> get typingStream => _typingController.stream;

  /// Call this from ChatScreen when opening/closing a chat
  void setActiveChat(String? chatUserId) {
    _activeChatId = chatUserId;
  }

  final Set<String> _processedMessageIds = {};

  Future<void> init() async {
    if (_pusher != null) return;
    // disconnect();

    final bool usingCustomHost =
        host.isNotEmpty &&
        !host.contains('pusher.com') &&
        !host.contains('mt1');

    // IMPORTANT: set auth in PusherOptions BEFORE creating the client
    final options = usingCustomHost
        ? PusherOptions(
            // use wsHost for custom/self-hosted servers
            host: host,
            // if your server uses a custom port for wss, set wssPort: 6001 (example)
            // wssPort: 6001,
            encrypted: true,
            auth: PusherAuth(
              authEndpoint,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            ),
          )
        : PusherOptions(
            cluster: cluster,
            encrypted: true,
            auth: PusherAuth(
              authEndpoint,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            ),
          );

    _pusher = PusherClient(
      appKey,
      options,
      autoConnect:
          false, // create client but connect manually so we can log/connect lifecycle
      enableLogging: kDebugMode,
    );

    debugPrint(
      'PusherService.init: usingCustomHost=$usingCustomHost, appKey=$appKey, host=$host, cluster=$cluster',
    );

    // connect explicitly (this will use the auth provided above)
    try {
      _pusher!.connect();
    } catch (e, st) {
      debugPrint('Pusher connect error: $e\n$st');
    }

    // Optional: listen to connection changes (debugging)
    try {
      _pusher!.onConnectionStateChange((state) {
        _lastConnectionState = state?.currentState ?? 'UNKNOWN';
        debugPrint('Pusher connection state changed: $_lastConnectionState');
        debugPrint('Pusher connection state changed: ${state!.currentState}');
      });
      _pusher!.onConnectionError((err) {
        debugPrint(
          'Pusher onError: ${err!.message}, code: ${err.code}, exception: ${err.exception}',
        );
      });
    } catch (_) {
      // Not all versions expose these callbacks in exactly the same names; ignore if absent.
    }

    try {
      await _pusher!.connect();
    } catch (e) {
      debugPrint("Pusher connect error: $e");
    }

    await _resyncAllSubscriptions();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      // If we have internet and Pusher is disconnected (or we just came back online)
      if (!results.contains(ConnectivityResult.none)) {
        debugPrint("🌐 Internet Restored. Re-syncing Pusher...");
        reconnect();
      }
    });
  }

  Future<void> _resyncAllSubscriptions() async {
    debugPrint("🔄 Resyncing all Pusher subscriptions...");

    // A. Subscribe to User Channel
    subscribeToUserChannel(currentUserId);

    // B. Fetch and Subscribe to Groups
    try {
      final result = await getJoinedGroups();

      result.fold(
        (failure) =>
            debugPrint("⚠️ Failed to fetch groups for Pusher (likely offline)"),
        (groups) {
          for (final group in groups) {
            if (group.groupId.isNotEmpty) {
              subscribeToGroupChannel(group.groupId);
            }
          }
        },
      );
    } catch (e) {
      debugPrint("❌ Error resyncing groups: $e");
    }
  }

  void reconnect() {
    debugPrint("🔄 PusherService: Attempting to reconnect...");

    // 1. Show User Feedback
    Fluttertoast.showToast(msg: "Reconnecting...", textColor: Colors.white);

    // 2. If client doesn't exist, initialize it (which handles connect)
    if (_pusher == null) {
      init();
      // After init, we must re-subscribe.
      // Since we have currentUserId in the class, we can do this automatically.
      subscribeToUserChannel(currentUserId);
      return;
    }

    // 3. If client exists, just connect
    try {
      _pusher!.connect();
    } catch (_) {}

    // 👇 CRITICAL: Re-run the fetch & subscribe logic
    // This ensures if we failed at startup, we try again now.
    _resyncAllSubscriptions();
  }

  void subscribeToUserChannel(String userId) {
    if (_pusher == null) init();

    try {
      // Use normal subscribe(); auth was already set on the options
      _channel = _pusher!.subscribe('private-chat.$userId');

      // Bind to the event you need
      _channel?.bind('private.message.sent', (PusherEvent? e) {
        debugPrint('PUSHER RAW EVENT (private.message.sent): ${e?.data}');
        if (e?.data == null) return;
        _handlePrivateMessageSent(e!.data!);
      });

      // Most important: bind subscription_error to see auth/server failures
      _channel?.bind('pusher:subscription_error', (PusherEvent? e) {
        debugPrint('Pusher subscription_error: ${e?.data}');
        // e?.data often contains server response explaining why auth failed
      });

      // Also bind generic pusher:subscription_succeeded to know success (helpful for debug)
      _channel?.bind('pusher:subscription_succeeded', (PusherEvent? e) {
        debugPrint(
          'Pusher subscription_succeeded for private-chat.$userId: ${e?.data}',
        );
      });

      debugPrint(
        'PusherService.subscribeToUserChannel: attempted subscribe to private-chat.$userId',
      );
    } catch (e, st) {
      debugPrint('PusherService.subscribeToUserChannel error: $e\n$st');
    }
  }

  //   //  Original pusher

  // Keep track of the group channel separately so we don't overwrite _channel (user channel)
  // Channel? _groupChannel;

  void subscribeToGroupChannel(String groupIdEn) {
    // Ensure initialized
    if (_pusher == null) init();

    // 4️⃣ FIX: Use local variable to check state.
    // If disconnected, force a reconnect before trying to subscribe.
    if (_lastConnectionState == 'DISCONNECTED') {
      debugPrint(
        "Pusher is DISCONNECTED. Reconnecting before group subscribe...",
      );
      try {
        _pusher?.connect();
      } catch (_) {}
    }

    // ⚠️ Check your backend channel naming!
    // Often it is 'private-group.ID' or 'private-groups.ID'
    final String channelName = 'private-group.$groupIdEn';

    try {
      debugPrint('Pusher: Subscribing to Group Channel: $channelName');

      if (_groupChannel != null && _groupChannel!.name == channelName) {
        // Already subscribed
        return;
      }

      _groupChannel = _pusher!.subscribe(channelName);

      // 2. 🔴 CORRECT EVENT NAME (Matches React Line 124)
      _groupChannel?.bind('group.message.sent', (PusherEvent? e) {
        debugPrint('🎯 MATCHED group.message.sent: ${e?.data}');
        if (e?.data != null) {
          // Parse JSON here because the handler expects a Map
          final decoded = jsonDecode(e!.data!) as Map<String, dynamic>;
          _handleGroupMessageReceived(decoded);
        }
      });

      // Bind success/error for debugging
      _groupChannel?.bind('pusher:subscription_error', (PusherEvent? e) {
        debugPrint('❌ Pusher Group subscription_error: ${e?.data}');
        // If this fires, your Flutter Token is invalid or User isn't in group "6949..."
      });

      _groupChannel?.bind('pusher:subscription_succeeded', (PusherEvent? e) {
        debugPrint('✅ Pusher Group subscription_succeeded: $channelName');
      });
    } catch (e) {
      debugPrint('PusherService.subscribeToGroupChannel error: $e');
    }
  }

  /// Unsubscribe when leaving the screen
  void unsubscribeFromGroupChannel(String groupIdEn) {
    // ⚠️ Must match the channel name used in subscribe
    final String channelName = 'private-group.$groupIdEn';

    try {
      _pusher?.unsubscribe(channelName);
      _groupChannel = null;
      debugPrint('Pusher: Unsubscribed from $channelName');
    } catch (e) {
      debugPrint('Pusher: Failed to unsubscribe from group: $e');
    }
  }

  void _handleGroupMessageReceived(Map<String, dynamic> payload) {
    debugPrint("🔵 Handling GROUP Message...");

    final root = payload['data'] ?? payload;
    final innerData = root['data'] ?? {};

    // 1. EXTRACT IDs
    // The explicit Group ID from backend
    final String backendGroupId =
        (innerData['group_to'] ?? innerData['chat_id'] ?? '').toString();
    // The ID that matched the channel subscription (based on your logs)
    final String channelTargetId =
        (innerData['user_to'] ?? root['receiver']?['id'] ?? '').toString();

    final String senderId =
        (root['sender']?['id'] ?? innerData['user_id'] ?? '').toString();
    final String senderName = (root['sender']?['name'] ?? 'Unknown').toString();

    // 2. CHECK IF CHAT IS OPEN
    bool isChatOpen = false;
    String effectiveGroupId =
        backendGroupId; // We will determine which ID to use

    if (_activeChatId != null) {
      final String currentActive = _activeChatId.toString().trim();

      // Check Primary Group ID
      if (currentActive == backendGroupId.trim()) {
        isChatOpen = true;
        effectiveGroupId = backendGroupId;
      }
      // Check Fallback ID (This is what will fix your issue)
      else if (currentActive == channelTargetId.trim()) {
        isChatOpen = true;
        effectiveGroupId = channelTargetId;
      }
    }

    debugPrint("🔍 Match Result: $isChatOpen (Using ID: $effectiveGroupId)");

    // 3. IF OPEN: SEND TO BLOC
    if (isChatOpen) {
      debugPrint("✅ MATCH! Sending to GroupChatBloc");

      final Map<String, dynamic> messageMap = Map<String, dynamic>.from(
        innerData,
      );

      messageMap['user_id'] = senderId;
      messageMap['user_name'] = senderName;
      // CRITICAL: Overwrite 'group_to' with the ID the UI is expecting to avoid confusion
      messageMap['group_to'] = effectiveGroupId;

      final bool isMe = (senderId == currentUserId);
      messageMap['is_my_chat'] = isMe ? 'yes' : 'no';
      groupChatBloc.add(GroupIncomingMessageReceived(messageMap));
    } else {
      debugPrint("❌ NO MATCH. Treating as background notification.");
    }

    // 4. THREAD / NOTIFICATION LOGIC
    if (senderId != currentUserId) {
      String groupName = (root['group_name'] ?? innerData['group_name'] ?? '')
          .toString();
      if (groupName.isEmpty || groupName == 'null') {
        groupName = "Group Chat";
      }

      // If we found a match (isChatOpen), use that ID.
      // If not, prefer the channelTargetId if it exists, otherwise backendGroupId.
      // This prevents creating a duplicate thread with a different ID.
      final String threadIdToUse = isChatOpen
          ? effectiveGroupId
          : (channelTargetId.isNotEmpty ? channelTargetId : backendGroupId);

      final threadMap = <String, dynamic>{
        'id': threadIdToUse,
        'chat_id': threadIdToUse,
        'chat_user_to_id': threadIdToUse,
        'chat_user_to_name': groupName,
        'chat_user_id': currentUserId,
        'chat_user_type': 'group',
        'is_file': innerData['is_file'] ?? 'no',
        'last_message': "${senderName}: ${innerData['message'] ?? ''}",
        'created_at':
            innerData['created_at'] ?? DateTime.now().toIso8601String(),
      };

      final String targetGroupId = isChatOpen
          ? effectiveGroupId
          : (channelTargetId.isNotEmpty ? channelTargetId : backendGroupId);

      // ONLY increment if the chat is NOT currently open
      if (!isChatOpen) {
        // dispatch event to MessagingBloc
        serviceLocator<MessagingBloc>().add(
          IncomingGroupMessageEvent(groupId: targetGroupId),
        );
      }

      if (localNotificationService != null && !isChatOpen) {
        localNotificationService!.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 100000,
          title: groupName,
          body: "${senderName}: ******",
          payload: jsonEncode({
            'kind': 'group${groupName}',
            'chatIdEn': threadIdToUse,
            'chatName': groupName,
          }),
        );
      }
    }
  }


  void _handlePrivateMessageSent(String rawData) async {
    if (rawData.isEmpty) return;

    dynamic payload;
    try {
      payload = jsonDecode(rawData);
    } catch (e) {
      debugPrint('Pusher payload parse error: $e');
      return;
    }

    // 1. Normalize Root
    final root = payload['data'] ?? payload;
    final stateStr = (root['state'] ?? '').toString();

  


    // In PusherService.dart inside _handlePrivateMessageSent

if (stateStr == 'last_message') {
  debugPrint("Pusher: Received 'last_message' SYNC event.");
  
  final dataList = root['data'];

  if (dataList is List) {
    for (var item in dataList) {
      if (item is Map) {
        try {
          // 1. Create a Mutable Map
          final Map<String, dynamic> threadMap = Map<String, dynamic>.from(item);

          // 2. EXTRACT IDs
          String otherId = (threadMap['chat_user_to_id'] ?? '').toString();
          String otherName = (threadMap['chat_user_to_name'] ?? '').toString();
          
          // Try to find the Sender ID/Name from various common keys
          String senderId = (threadMap['chat_user_id'] ?? threadMap['user_id'] ?? threadMap['sender_id'] ?? '').toString();
          // Note: If your backend doesn't send sender_name, we might default to "Unknown" or keep existing
          String senderName = (threadMap['chat_user_name'] ?? threadMap['sender_name'] ?? threadMap['user_name'] ?? '').toString();

          // 3. THE SWAP LOGIC
          // If the "To" ID is ME, then I am chatting with the "Sender"
          if (otherId == currentUserId) {
             // Validate we actually have sender info before swapping
             if (senderId.isNotEmpty) {
                threadMap['chat_user_to_id'] = senderId; // Swap ID to Joshua
                
                // Only swap name if the backend provided one, otherwise we might need to rely on local cache
                if (senderName.isNotEmpty && senderName != 'null') {
                   threadMap['chat_user_to_name'] = senderName; // Swap Name to Joshua
                }
             }
          }

          // 4. Create Thread with Corrected Data
          final thread = MessageThread.fromMap(threadMap);

          // 5. Dispatch
          messagingBloc.add(
            NewThreadCreatedEvent(
              thread,
              shouldIncrementCount: false,
              shouldResetCount: false,
              useProvidedUnreadCount: true, 
            ),
          );
        } catch (e) {
          debugPrint("Error parsing thread item: $e");
        }
      }
    }
  }
  return; 
}

    // =========================================================
    // ⬇️ LOGIC FOR SINGLE MESSAGES (text, callUpdate, typing)
    // =========================================================

    // 2. Extract Data Map (Handle 'mss' vs 'data' wrapper)
    dynamic source = root['mss'];
    if (source is! Map) {
      if (root['data'] is Map) {
        source = root['data'];
      } else {
        source = root;
      }
    }
    final Map<String, dynamic> baseMap = Map<String, dynamic>.from(source);

    // 3. Duplicate Check
    final String messageId = (baseMap['id'] ?? '').toString();
    if (messageId.isNotEmpty && _processedMessageIds.contains(messageId)) {
      debugPrint("Pusher: Ignored duplicate message ID: $messageId");
      return;
    }
    _processedMessageIds.add(messageId);
    if (_processedMessageIds.length > 50) _processedMessageIds.clear();

    // 4. Extract Objects Safely
    final senderObj = root['sender'];
    final receiverObj = root['receiver'];
    final String myId = currentUserId;

    // Helper to get ID safely without crashing
    String safeGetId(dynamic obj) {
      if (obj is Map) {
        return (obj['id'] ?? obj['user_id'] ?? obj['member_id_encrpt'] ?? '')
            .toString();
      }
      return '';
    }

    final senderId = safeGetId(senderObj);
    final receiverId = safeGetId(receiverObj);
    final bool isMyChat = senderId == myId; // For call control checks

    // ============= 5. Typing Indicators =============
    if (stateStr == 'is_typing' || stateStr == 'not_typing') {
      chatDetailBloc.add(
        UpdateTypingEvent(userId: senderId, isTyping: stateStr == 'is_typing'),
      );

      

      debugPrint("senderId: ${rawData}");
      debugPrint("basemap: ${baseMap}");
      final String actualSenderId = (baseMap['sender_iden'] ?? '').toString();
      

      debugPrint(
        "🔍 Extracted Sender ID for Typing: '$actualSenderId'",
      ); // Debug check

      if (actualSenderId.isNotEmpty) {
        bool isTyping = stateStr == 'is_typing';
        debugPrint(
          "💬 Typing Status Update: User $actualSenderId isTyping=$isTyping",
        );

        // 3. Emit Event
        _typingController.add(
          TypingStatus(userId: actualSenderId, isTyping: isTyping)
        );

        // Auto-reset after 5 seconds (Safety)
        if (isTyping) {
          Future.delayed(const Duration(seconds: 5), () {
             if (!_typingController.isClosed) {
                _typingController.add(TypingStatus(userId: actualSenderId, isTyping: false));
             }
          });
        }
      }

      

      if (actualSenderId.isNotEmpty &&
          serviceLocator.isRegistered<MessagingBloc>()) {
        final messagingBloc = serviceLocator<MessagingBloc>();

        messagingBloc.add(
          UserTypingEvent(actualSenderId, stateStr == 'is_typing'),
        );

        if (stateStr == 'is_typing') {
          Future.delayed(const Duration(seconds: 5), () {
            messagingBloc.add(UserTypingEvent(actualSenderId, false));
          });
        }
      }

      return;
    }

    // if (stateStr == 'is_typing' || stateStr == 'not_typing') {
    // 1. Safe Cast: Ensure the root data is treated as a Map
    // (Replace 'rawData' with 'data' or 'payload' if that matches your variable name)

    // return;

    // }

    // ============= 6. Text / Call Updates =============
    if (stateStr == 'text' || stateStr == 'callUpdate') {
      // ---------------------------------------------------------
      // 🔍 ROBUST ID EXTRACTION (Fixes the "Null" Crash)
      // ---------------------------------------------------------
      dynamic candidateId = baseMap['user_id'];

      // Try fallbacks if user_id is missing
      candidateId ??= baseMap['sender_id'];
      candidateId ??= baseMap['member_id_encrpt'];
      candidateId ??= baseMap['chat_user_id'];

      // Try sender object
      if (candidateId == null && senderObj is Map) {
        candidateId = senderObj['id'] ?? senderObj['user_id'];
      }

      // Try root
      candidateId ??= root['user_id'];

      final String msgUserId = (candidateId ?? '').toString();
      final bool isMyMsg = msgUserId == myId;

      // ---------------------------------------------------------
      // 📞 CALL CONTROL LOGIC (Your Existing Code)
      // ---------------------------------------------------------
      final String msgText = (baseMap['message'] ?? baseMap['body'] ?? '')
          .toString();

      // Invite
      if (msgText.startsWith(kCallControlInvitePrefix)) {
        final parts = msgText.split('|');
        if (parts.length >= 2) {
          final meetingId = parts[1];
          final callerName =
              (senderObj is Map ? (senderObj['name'] ?? 'Unknown') : 'Unknown')
                  .toString();

          if (!isMyChat) {
            // try {
            //   FlutterRingtonePlayer().playRingtone(looping: true);
            // } catch (_) {}

            await CallKitService.showIncomingCall(
              callerName: callerName,
              callerId: senderId,
              meetingId: meetingId,
              avatarUrl: null, // Add avatar URL if you have it in senderObj
            );

            // bool isCallScreenVisible = false;
            // navigatorKey.currentState?.popUntil((route) {
            //   if (route.settings.name == 'secure_call')
            //     isCallScreenVisible = true;
            //   return true;
            // });

            // if (isCallScreenVisible) return;

            // navigatorKey.currentState?.push(
            //   MaterialPageRoute(
            //     settings: const RouteSettings(name: 'secure_call'),
            //     builder: (_) => BlocProvider.value(
            //       value: serviceLocator<CallBloc>(),
            //       child: SecureCallingScreen(
            //         isCaller: false,
            //         meetingId: meetingId,
            //         otherUserName: callerName,
            //         peerIdEn: senderId,
            //       ),
            //     ),
            //   ),
            // );
          }
        }
        return; // Control message, don't show in chat
      }

      // Rejected / Ended
      if (msgText == kCallControlRejected || msgText == kCallControlEnded) {
        await CallKitService.endAllCalls();
        try {
          FlutterRingtonePlayer().stop();
          serviceLocator<CallBloc>().add(const CallEnded());
          navigatorKey.currentState?.popUntil((route) {
            return route.settings.name != 'secure_call';
          });
        } catch (e) {
          debugPrint('Call control cleanup error: $e');
        }
        return;
      }

      if (msgText == kCallControlAccepted) return;

      // ---------------------------------------------------------
      // 💬 CHAT MESSAGE HANDLING
      // ---------------------------------------------------------

      // 1. Determine Chat Type
      final chatUserType =
          (baseMap['chat_user_type'] ?? root['user_type'] ?? '').toString();
      final String groupTo = (baseMap['group_to'] ?? '').toString();
      final String userToEn = (baseMap['user_to'] ?? receiverId).toString();

      // 2. Determine "Conversation ID" (Navigation Key)
      String chatIdForNav;
      if (chatUserType == 'group' && groupTo.isNotEmpty) {
        chatIdForNav = groupTo;
      } else {
        chatIdForNav = isMyMsg ? userToEn : msgUserId;
      }

      final bool isThisChatOpen =
          _activeChatId != null && _activeChatId == chatIdForNav;

      // 3. Build ChatMessage Object
      // Use fallback map if data is missing to prevent crashes
      if (!baseMap.containsKey('sender_id')) {
        baseMap['sender_id'] = msgUserId;
      }
      final chatMessage = ChatMessage.fromMap(baseMap, currentUserId: myId);

      // 4. Update Active Chat Screen
      if (isThisChatOpen) {
        if (chatUserType == 'group') {
          groupChatBloc.add(GroupIncomingMessageReceived(Map<String, dynamic>.from(baseMap)));
        } else {
          chatDetailBloc.add(IncomingMessageEvent(chatMessage));
        }
      }

      // 5. Update Thread List (MessagingScreen)
      String threadUserId;
      String threadUserName;

      if (chatUserType == 'group' && groupTo.isNotEmpty) {
        threadUserId = groupTo;
        debugPrint("group thread user Id: ${threadUserId}");

        threadUserName =
            (baseMap['group_name'] ?? root['group_name'] ?? 'Group').toString();
      } else {
        if (isMyMsg) {
          threadUserId = receiverId;
          threadUserName =
              (receiverObj is Map ? receiverObj['name'] : 'Unknown') ??
              'Unknown';
        } else {
          threadUserId = senderId;
          threadUserName =
              (senderObj is Map ? senderObj['name'] : 'Unknown') ?? 'Unknown';
        }
      }

      // Fallback
      if (threadUserId.isEmpty) threadUserId = chatIdForNav;

      final threadMap = <String, dynamic>{
        'id': baseMap['chat_id'] ?? baseMap['group_to'] ?? threadUserId,
        'chat_id': baseMap['chat_id'] ?? baseMap['group_to'],
        'chat_user_to_id': threadUserId,
        'chat_user_id': myId,
        'chat_user_to_name': threadUserName,
        'is_file': baseMap['is_file'] ?? 'no',
        'last_message': baseMap['message'] ?? baseMap['body'] ?? '',
        'chat_user_type': chatUserType,
        'created_at': baseMap['created_at'] ?? DateTime.now().toIso8601String(),
      };

      final newThread = MessageThread.fromMap(threadMap);

      // messagingBloc.add(
      //   NewThreadCreatedEvent(
      //     newThread,
      //     // Increment count ONLY if: Not my message AND Chat not currently open
      //     shouldIncrementCount: !isMyMsg && !isThisChatOpen,
      //   ),
      // );

       final bool shouldReset = isMyMsg || isThisChatOpen;
      final bool shouldIncrement = !isMyMsg && !isThisChatOpen;

      messagingBloc.add(
        NewThreadCreatedEvent(
          newThread,
          shouldIncrementCount: shouldIncrement,
          shouldResetCount: shouldReset, // 👈 Pass this new flag
        ),
      );

      // 6. Local Notification
      if (localNotificationService != null && !isMyMsg && !isThisChatOpen) {
        await localNotificationService!.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: threadUserName,
          body: "******", // Hiding content for privacy
          payload: jsonEncode({
            'kind': chatUserType == 'group' ? 'group' : 'user',
            'chatIdEn': threadUserId,
            'chatName': threadUserName,
          }),
        );
      }
      return;
    }

    debugPrint('Unhandled pusher state: $stateStr');
  }

 

  Future<void> sendTypingState({
    required String toUserId,
    required bool isTyping,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/messages/typing'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_chat_user': toUserId,
          'typing': isTyping ? 'is_typing' : 'not_typing',
        }),
      );
      debugPrint("sending typing state...");
      debugPrint("sending typing state status code...  ${response.statusCode}");
      debugPrint("current_chat_user:  $toUserId");
    } catch (e) {
      debugPrint('sendTypingState error: $e');
    }
  }

  void disconnect() {
    try {
      _player.stop();
      if (_channel != null) {
        _channel!.unbind('private.message.sent');
        _channel!.unbind('pusher:subscription_error');
      }
      _pusher?.disconnect();
      _pusher = null;
    } catch (e) {
      debugPrint('Pusher disconnect error: $e');
    }
  }

  void dispose() {
    disconnect();
    _player.dispose();
    _connectivitySubscription?.cancel(); // Cancel listener
    _typingController.close();
    _pusher?.disconnect();
    // _groupMessageStreamController.close();
  }
}


