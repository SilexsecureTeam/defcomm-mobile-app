import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pusher_client_fixed/pusher_client_fixed.dart';

// CONFIG
const String kAppKey = 'l4ewjdxj5hilgin4smsv';
const String kHost = 'backend.defcomm.ng';
const String kAuthEndpoint = 'https://backend.defcomm.ng/api/broadcasting/auth';

// DEBUG VARIABLES
String _connectionStatus = "Starting...";
String _subscriptionStatus = "Waiting...";
String _lastEvent = "None";

bool _isAppInForeground = false;

// Module-level reference so _handleBackgroundMessage can signal the UI isolate.
ServiceInstance? _serviceInstance;

Future<void> initializeBackgroundService(
  String token,
  String userId,
  List<String> groupIds,
) async {
  final service = FlutterBackgroundService();

  final box = GetStorage();
  await box.write('accessToken', token);
  await box.write('userEnId', userId);
  await box.write('background_group_ids', groupIds);
  await box.save();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'Defcomm Active',
    description: 'Listening for calls and messages...',
    importance: Importance.high,
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Defcomm Active',
      initialNotificationContent: 'Initializing...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: false, onForeground: onStart),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  _serviceInstance = service;
  DartPluginRegistrant.ensureInitialized();
  // NOTE: WakelockPlus keeps the SCREEN on (FLAG_KEEP_SCREEN_ON), which is
  // useless and drains battery when the screen is already off. A foreground
  // service with PARTIAL_WAKE_LOCK is the correct approach — Android provides
  // it automatically for foreground services. Do NOT call WakelockPlus here.

  // 1. INIT NOTIFICATIONS
  final FlutterLocalNotificationsPlugin localNotif =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await localNotif.initialize(initializationSettings);

  const AndroidNotificationChannel messageChannel = AndroidNotificationChannel(
    'defcomm_msg_channel',
    'Messages',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    enableLights: true,
  );

  service.on('setAsForeground').listen((event) {
    print(
      "👀 Background Service: App is now in FOREGROUND (Muting notifications)",
    );
    _isAppInForeground = true;
  });

  service.on('setAsBackground').listen((event) {
    print(
      "zzz Background Service: App is now in BACKGROUND (Enabling notifications)",
    );
    _isAppInForeground = false;
  });

  try {
    await localNotif
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(messageChannel);
    print("✅ Background Service: Message notification channel created");
  } catch (e) {
    print("⚠️ Background Service: Failed to create message channel: $e");
  }

  print("🔥🔥🔥 BACKGROUND SERVICE STARTED 🔥🔥🔥");

  PusherClient? pusher;

  // 2. CONNECT FUNCTION
  Future<void> connectToPusher(
    String token,
    String userId,
    List<String> groupIds,
  ) async {
    try {
      if (pusher != null) await pusher!.disconnect();
    } catch (_) {}

    print("🔌 Connecting Pusher for $userId...");
    pusher = await _setupPusher(token, userId, groupIds, localNotif);
  }

  // 3. FCM-TRIGGERED PUSHER RECONNECT
  // When FCM wakes the device from Doze, the background handler calls
  // service.invoke('forcePusherReconnect'). This re-establishes the Pusher
  // socket so the device is ready for the next real-time event.
  // (A periodic watchdog timer is NOT used because Android Doze defers
  //  all timers, making them useless exactly when we need them most.)
  service.on('forcePusherReconnect').listen((event) async {
    // Wake the screen immediately so the device stays alive long enough for
    // Pusher to reconnect and deliver any queued call/message events.
    service.invoke('wakeScreen');
    try {
      if (_connectionStatus == 'DISCONNECTED' ||
          _connectionStatus.startsWith('ERR') ||
          _connectionStatus == 'Starting...') {
        final box = GetStorage();
        final token = box.read('accessToken');
        final userId = box.read('userEnId');
        final List<String> groups =
            (box.read('background_group_ids') as List?)?.cast<String>() ?? [];
        if (token != null && userId != null) {
          print("📡 forcePusherReconnect: reconnecting Pusher...");
          await connectToPusher(token, userId, groups);
        }
      } else {
        print("📡 forcePusherReconnect: Pusher already connected ($_connectionStatus), skip");
      }
    } catch (e) {
      print("forcePusherReconnect error: $e");
    }
  });

  try {
    await GetStorage.init();
  } catch (e) {
    print("⚠️ Background Service: GetStorage.init error: $e");
  }
  final box = GetStorage();

  // Retry loop: Try 3 times to find the token
  for (int i = 0; i < 3; i++) {
    try {
      final String? storedToken = box.read('accessToken');
      final String? storedUserId = box.read('userEnId');
      final List<String> storedGroups =
          (box.read('background_group_ids') as List?)?.cast<String>() ?? [];

      print("🔑 Background Service retry $i: token=${storedToken != null}, userId=${storedUserId != null}, groups=${storedGroups.length}");

      if (storedToken != null && storedUserId != null) {
        await connectToPusher(storedToken, storedUserId, storedGroups);
        _connectionStatus = "Connecting...";
        break;
      } else {
        _connectionStatus = "No Data (Retry ${i + 1})...";
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      print("❌ Background Service retry $i error: $e");
    }
  }

  if (_connectionStatus.startsWith("No Data")) {
    _connectionStatus = "Waiting for Login...";
  }

  // 5. LISTEN FOR MAIN APP DATA
  service.on('setUserData').listen((event) async {
    if (event == null) return;
    final token = event['token'] as String?;
    final userId = event['userId'] as String?;
    final groupIds = (event['groupIds'] as List?)?.cast<String>() ?? [];

    if (token != null && userId != null) {
      final box = GetStorage();
      await box.write('accessToken', token);
      await box.write('userEnId', userId);
      await box.write('background_group_ids', groupIds);
      await box.save();
      await connectToPusher(token, userId, groupIds);
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}

Future<PusherClient> _setupPusher(
  String token,
  String userId,
  List<String> groupIds,
  FlutterLocalNotificationsPlugin localNotif,
) async {
  PusherOptions options = PusherOptions(
    host: kHost,
    encrypted: true,
    wssPort: 443,
    auth: PusherAuth(
      kAuthEndpoint,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ),
  );

  PusherClient pusher = PusherClient(kAppKey, options, autoConnect: true);

  pusher.onConnectionStateChange((state) {
    final prev = _connectionStatus;
    _connectionStatus = state?.currentState?.toUpperCase() ?? "UNKNOWN";
    print("📡 State: $_connectionStatus");
    // Immediately try to reconnect the moment the connection drops,
    // rather than waiting for the watchdog cycle.
    if (_connectionStatus == 'DISCONNECTED' && prev != 'DISCONNECTED') {
      Future.delayed(const Duration(seconds: 3), () {
        if (_connectionStatus == 'DISCONNECTED') {
          try {
            pusher.connect();
            print("🔄 Auto-reconnect triggered after disconnect");
          } catch (e) {
            print("⚠️ Auto-reconnect error: $e");
          }
        }
      });
    }
  });

  pusher.onConnectionError((error) {
    _connectionStatus = "ERR: ${error?.code}";
    print("❌ Error: ${error?.message}");
  });

  Channel channel = pusher.subscribe('private-chat.$userId');

  channel.bind('private.message.sent', (PusherEvent? event) {
    _lastEvent = "Msg Recv";
    if (event?.data == null) return;
    _handleBackgroundMessage(event!.data!, userId, localNotif);
  });

  channel.bind('pusher:subscription_succeeded', (_) {
    _subscriptionStatus = "OK ($userId)";
  });
  channel.bind('pusher:subscription_error', (e) {
    _subscriptionStatus = "FAIL (Auth)";
  });

  for (String groupId in groupIds) {
    pusher.subscribe('private-group.$groupId').bind('group.message.sent', (
      PusherEvent? event,
    ) {
      _lastEvent = "Grp Msg";
      if (event?.data == null) return;
      _handleBackgroundMessage(
        event!.data!,
        userId,
        localNotif,
        isGroup: true,
        channelName: event.channelName,
      );
    });
  }

  return pusher;
}

void _handleBackgroundMessage(
  String rawData,
  String myId,
  FlutterLocalNotificationsPlugin localNotif, {
  bool isGroup = false,
  String? channelName,
}) async {
  print("\n" + "="*60);
  print("🔵 BACKGROUND SERVICE - Message Handler");
  print("   Channel: $channelName");
  print("   Is Group: $isGroup");
  print("   My ID: $myId");
  print("="*60);
  
  try {
    _lastEvent = "1. Raw Data Recv";
    print("📦 Raw data received (first 200 chars): ${rawData.substring(0, rawData.length > 200 ? 200 : rawData.length)}...");

    // 1. JSON DECODE
    final payload = jsonDecode(rawData);
    _lastEvent = "2. JSON Decoded";
    print("✅ JSON decoded successfully");

    // 2. ROOT EXTRACTION
    final root = payload['data'] ?? payload;
    _lastEvent = "3. Root Extracted";

    // 3. SOURCE MAPPING
    dynamic source = root['mss'];
    if (source is! Map) {
      if (root['data'] is Map)
        source = root['data'];
      else
        source = root;
    }
    final Map<String, dynamic> baseMap = Map<String, dynamic>.from(source);
    _lastEvent = "4. BaseMap Ready";

    // 4. ID CHECKS
    dynamic candidateId =
        baseMap['user_id'] ?? baseMap['sender_id'] ?? root['sender']?['id'];
    final String msgUserId = (candidateId ?? '').toString();
    final bool isMyMsg = msgUserId == myId;
    _lastEvent = "5. IDs Parsed";

    // 5. TEXT EXTRACTION
    final String msgText = (baseMap['message'] ?? baseMap['body'] ?? '')
        .toString();
    final senderObj = root['sender'];
    final String senderName =
        (senderObj is Map ? (senderObj['name'] ?? 'Unknown') : 'Unknown')
            .toString();
    final String stateStr = (root['state'] ?? '').toString();
    _lastEvent = "6. Text Ready";

    // CALL LOGIC — dismiss UI first if caller ended/rejected/accepted
    if (msgText == '__DEFCOMM_CALL_REJECTED_v1__' ||
        msgText == '__DEFCOMM_CALL_ENDED_v1__' ||
        msgText == 'call_accepted') {
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (e) {
        print('⚠️ endAllCalls error: $e');
      }
      return;
    }

    // Detect call invite by message content OR by mssType='call' with
    // 'voice_call' body (the format sent by RecentCallsScreen._onCallPressed).
    final bool isCall = msgText.contains('__call_control__invite') ||
        msgText.contains('CallControl|Invite') ||
        (msgText == 'voice_call' && stateStr == 'call') ||
        stateStr == 'call';

    print("🔍 Message type check:");
    print("   State: $stateStr");
    print("   Is Call: $isCall");
    print("   Is My Message: $isMyMsg");

    if (isCall) {
      if (isMyMsg) {
        _lastEvent = "Ignored: My Call";
        print("⏭️ Ignoring - this is my own call");
        return;
      }
      // Extract meetingId from the invite prefix if present.
      String meetingId = '';
      if (msgText.contains('__call_control__invite|')) {
        final parts = msgText.split('|');
        if (parts.length >= 2) meetingId = parts[1].trim();
      }
      if (meetingId.isEmpty) {
        meetingId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      print("📞 Call detected — showing CallKit. caller=$senderName meetingId=$meetingId");
      _lastEvent = "Call → CallKit";
      try {
        await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
          id: meetingId,
          nameCaller: senderName,
          appName: 'Defcomm',
          handle: senderName,
          type: 0,
          duration: 30000,
          textAccept: 'Accept',
          textDecline: 'Decline',
          missedCallNotification: const NotificationParams(
            showNotification: true,
            isShowCallback: true,
            subtitle: 'Missed call',
            callbackText: 'Call back',
          ),
          extra: {
            'meetingId': meetingId,
            'callerId': msgUserId,
            'callerName': senderName,
          },
          android: const AndroidParams(
            isCustomNotification: false,
            isShowLogo: false,
            isShowFullLockedScreen: true,
            ringtonePath: 'system_ringtone_default',
            backgroundColor: '#1B5E20',
            actionColor: '#4CAF50',
            textColor: '#FFFFFF',
          ),
          ios: const IOSParams(
            iconName: 'CallKitLogo',
            handleType: '',
            supportsVideo: true,
            maximumCallGroups: 2,
            maximumCallsPerCallGroup: 1,
            ringtonePath: 'system_ringtone_default',
          ),
        ));
      } catch (e) {
        print('❌ background_pusher CallKit error: $e');
      }
      return;
    }

    // CHAT LOGIC
    if (stateStr == 'text' || stateStr == 'callUpdate') {
      if (isMyMsg) {
        _lastEvent = "Ignored: ${stateStr}";
        return;
      }

      _lastEvent = "7. Chat Detected";

      String threadUserId = '';
      String threadUserName = '';
      String kind = 'user';

      final String chatUserType =
          (baseMap['chat_user_type'] ?? root['user_type'] ?? 'user').toString();

      if (isGroup || chatUserType == 'group') {
        kind = 'group';
        if (channelName != null && channelName.contains('private-group.')) {
          threadUserId = channelName.split('.').last;
        }
        if (threadUserId.isEmpty)
          threadUserId = (baseMap['group_to'] ?? baseMap['chat_id'] ?? '')
              .toString();
        threadUserName =
            (baseMap['group_name'] ?? root['group_name'] ?? 'Group').toString();
      } else {
        kind = 'user';
        threadUserId = msgUserId;
        threadUserName = senderName;
      }
      if (threadUserId.isEmpty) threadUserId = myId;
      String body = "******";
      if (kind == 'group') body = "$senderName: ******";

      _lastEvent = "8. Showing Notif";
      
      print("\n💬 Preparing to show notification:");
      print("   App in foreground: $_isAppInForeground");
      print("   Thread User: $threadUserName");
      print("   Thread ID: $threadUserId");
      print("   Kind: $kind");

      if(!_isAppInForeground) {
         print("✅ App is in background - showing notification");
         // Wake the screen so the notification heads-up is visible.
         _serviceInstance?.invoke("wakeScreen");

         const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'defcomm_msg_channel',
            'Messages',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            enableVibration: true,
            playSound: true,
            ticker: 'New message',
          );
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );
        await localNotif.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        threadUserName,
        body,
        platformDetails,
        payload: jsonEncode({
          'kind': kind,
          'chatIdEn': threadUserId,
          'chatName': threadUserName,
        }),
      );

      _lastEvent = "Notif Shown";
      print("✅ Notification displayed successfully");
      } else {
        _lastEvent = "App in Foreground, Notif Skipped";
        print("⏭️ Skipping notification - app is in foreground");
      }

      _lastEvent = "9. SUCCESS";
      print("🏁 Message handling completed successfully\n");
    } else {
      _lastEvent = "Ignored State: $stateStr";
      print("⏭️ Ignoring - unhandled state: $stateStr\n");
    }
  } catch (e, stack) {
    _lastEvent = "Err at $_lastEvent: $e";
    print("❌ ERROR in background message handler:");
    print("   Last event: $_lastEvent");
    print("   Error: $e");
    print("   Stack: $stack");
  }
}
