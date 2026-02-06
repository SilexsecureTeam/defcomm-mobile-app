// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui';
// import 'package:defcomm/features/calling/call_control_constants.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_callkit_incoming/entities/android_params.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/entities/ios_params.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:pusher_client_fixed/pusher_client_fixed.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_client_fixed/pusher_client_fixed.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get_storage/get_storage.dart';


import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_client_fixed/pusher_client_fixed.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get_storage/get_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// CONFIG
const String kAppKey = 'l4ewjdxj5hilgin4smsv';
const String kHost = 'backend.defcomm.ng';
const String kAuthEndpoint = 'https://backend.defcomm.ng/api/broadcasting/auth';

// DEBUG VARIABLES
String _connectionStatus = "Starting...";
String _subscriptionStatus = "Waiting...";
String _lastEvent = "None";

bool _isAppInForeground = false;

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
    description: 'Listening for calls...',
    importance: Importance.low,
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
  DartPluginRegistrant.ensureInitialized();
  try {
    await WakelockPlus.enable();
  } catch (e) {
    print("Wakelock error: $e");
  }

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

  await localNotif
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(messageChannel);

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

  // 3. SAFE DIAGNOSTIC TIMER (Uses separate notification, guaranteed to work)
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    try {
      // Create a specific channel for debug info so it doesn't make noise
      const AndroidNotificationDetails debugDetails =
          AndroidNotificationDetails(
            'defcomm_debug',
            'Debug Status',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true, // Makes it sticky
            autoCancel: false,
          );

      // Show Status in a separate notification (ID 999)
      await localNotif.show(
        999,
        "Pusher Status: $_connectionStatus",
        "Sub: $_subscriptionStatus | Last: $_lastEvent",
        const NotificationDetails(android: debugDetails),
      );

      // Auto-Reconnect Watchdog
      if (_connectionStatus == 'DISCONNECTED' ||
          _connectionStatus.startsWith('ERR')) {
        print("⚠️ Watchdog: Disconnected. Attempting reconnect...");
        final box = GetStorage();
        final token = box.read('accessToken');
        final userId = box.read('userEnId');
        if (token != null && userId != null) {
          connectToPusher(token, userId, []);
        }
      }
    } catch (e) {
      print("Timer Error: $e");
    }
  });


  await GetStorage.init();
  final box = GetStorage();

  // Retry loop: Try 3 times to find the token
  for (int i = 0; i < 3; i++) {
    final String? storedToken = box.read('accessToken');
    final String? storedUserId = box.read('userEnId');
    final List<String> storedGroups =
        (box.read('background_group_ids') as List?)?.cast<String>() ?? [];

    if (storedToken != null && storedUserId != null) {
      await connectToPusher(storedToken, storedUserId, storedGroups);
      _connectionStatus = "Connecting..."; // Update status for user to see
      break; // Exit loop, we found data
    } else {
      _connectionStatus = "No Data (Retry ${i + 1})...";
      await Future.delayed(const Duration(seconds: 2)); // Wait 2s before retry
    }
  }

  // If still failing after retries
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
    _connectionStatus = state?.currentState?.toUpperCase() ?? "UNKNOWN";
    print("📡 State: $_connectionStatus");
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
  try {
    _lastEvent = "1. Raw Data Recv";

    // 1. JSON DECODE
    final payload = jsonDecode(rawData);
    _lastEvent = "2. JSON Decoded";

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

    // CALL LOGIC
    bool isCall = stateStr == 'call';
    if (msgText.contains('__call_control__invite') ||
        msgText.contains('CallControl|Invite'))
      isCall = true;

    if (isCall) {
      if (isMyMsg) {
        _lastEvent = "Ignored: My Call";
        return;
      }

      _lastEvent = "7. Call Detected";
      // ... CallKit Logic ...
      // (Simplified for debug test)
      _lastEvent = "Call UI Triggered";
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

     

      if(!_isAppInForeground) {

         const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'defcomm_msg_channel',
            'Messages',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
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
      } else {
        _lastEvent = "App in Foreground, Notif Skipped";
      }

      

      _lastEvent = "9. SUCCESS";
    } else {
      _lastEvent = "Ignored State: $stateStr";
    }
  } catch (e) {
    _lastEvent = "Err at $_lastEvent: $e";
  }
}
