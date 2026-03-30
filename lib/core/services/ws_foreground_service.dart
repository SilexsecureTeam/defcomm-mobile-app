import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:defcomm/features/calling/call_control_constants.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

const _kAppKey  = 'l4ewjdxj5hilgin4smsv';
const _kWsUrl   = 'wss://backend.defcomm.ng/app/$_kAppKey'
    '?protocol=7&client=flutter-ws&version=1.0&flash=false';
const _kAuthUrl = 'https://backend.defcomm.ng/api/broadcasting/auth';
const _kMsgChannelId = 'defcomm_ws_messages';
const _kSvcChannelId = 'defcomm_ws_service';

// ── Entry-point (must be top-level for the background isolate) ────────────────
@pragma('vm:entry-point')
void wsServiceEntryPoint() {
  FlutterForegroundTask.setTaskHandler(WsTaskHandler());
}

// ── Public helpers ────────────────────────────────────────────────────────────

void initWsForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: _kSvcChannelId,
      channelName: 'Defcomm Active',
      channelDescription: 'Keeps secure connection alive for messages & calls',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<ServiceRequestResult> startWsForegroundService() async {
  if (await FlutterForegroundTask.isRunningService) {
    return FlutterForegroundTask.restartService();
  }
  return FlutterForegroundTask.startService(
    serviceId: 1001,
    // Fix Android 14 crash: strictly specify FGS type
    serviceTypes: [ForegroundServiceTypes.dataSync],
    notificationTitle: 'Defcomm Active',
    notificationText: 'Secure connection active',
    callback: wsServiceEntryPoint,
  );
}

Future<ServiceRequestResult> stopWsForegroundService() =>
    FlutterForegroundTask.stopService();

void updateWsServiceUserData({
  required String token,
  required String userId,
  required List<String> groupIds,
}) {
  FlutterForegroundTask.sendDataToTask({
    'action': 'setUserData',
    'token': token,
    'userId': userId,
    'groupIds': groupIds,
  });
}

// ── Task handler (runs in background isolate) ─────────────────────────────────
class WsTaskHandler extends TaskHandler {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  String _token   = '';
  String _userId  = '';
  List<String> _groupIds = [];
  String? _socketId;
  bool _intentionalClose = false;
  int  _retryCount       = 0;
  bool _isConnected      = false;
  bool _isAppForeground  = false;

  final _notif = FlutterLocalNotificationsPlugin();

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();
    await _initNotifications();

    await GetStorage.init();
    final box = GetStorage();
    _token    = box.read<String>('accessToken') ?? '';
    _userId   = box.read<String>('userEnId')    ?? '';
    _groupIds = (box.read('background_group_ids') as List? ?? [])
        .map((e) => e.toString())
        .toList();

    print('WS onStart: userId=$_userId groups=${_groupIds.length}');
    if (_token.isNotEmpty && _userId.isNotEmpty) await _connect();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _intentionalClose = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    try { _channel?.sink.close(); } catch (_) {}
    print('WS onDestroy');
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final action = data['action'] as String? ?? '';
    if (action == 'appForeground') { _isAppForeground = true; return; }
    if (action == 'appBackground') { _isAppForeground = false; return; }
    if (action != 'setUserData') return;

    _token    = (data['token']  as String?) ?? _token;
    _userId   = (data['userId'] as String?) ?? _userId;
    _groupIds = ((data['groupIds'] as List?) ?? _groupIds)
        .map((e) => e.toString())
        .toList();

    final box = GetStorage();
    box.write('accessToken', _token);
    box.write('userEnId', _userId);
    box.write('background_group_ids', _groupIds);

    print('WS credentials updated, reconnecting');
    _reconnect(immediate: true);
  }

  // ── WebSocket connect ───────────────────────────────────────────────────────

  Future<void> _connect() async {
    _intentionalClose = false;
    try {
      print('WS connecting...');
      _channel = WebSocketChannel.connect(Uri.parse(_kWsUrl));
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      _retryCount = 0;
      _isConnected = true;
      FlutterForegroundTask.updateService(
        notificationTitle: 'Defcomm Active',
        notificationText: 'Secure connection established',
      );
    } catch (e) {
      print('WS connect error: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final frame = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final event   = (frame['event']   as String?) ?? '';
      final channel = (frame['channel'] as String?) ?? '';

      dynamic data = frame['data'];
      if (data is String && data.isNotEmpty) {
        try { data = jsonDecode(data); } catch (_) {}
      }

      switch (event) {
        case 'pusher:connection_established':
          _socketId = (data is Map) ? data['socket_id']?.toString() : null;
          final timeout = (data is Map)
              ? ((data['activity_timeout'] as num?)?.toInt() ?? 120)
              : 120;
          print('WS connected, socketId=$_socketId');
          _startPingTimer(timeout);
          _subscribeAll();
          break;

        case 'pusher:ping':
          _send({'event': 'pusher:pong', 'data': {}});
          break;

        case 'pusher:pong':
          print('WS pong received');
          break;

        case 'pusher_internal:subscription_succeeded':
        case 'pusher:subscription_succeeded':
          print('WS subscribed: $channel');
          break;

        case 'pusher:subscription_error':
          print('WS subscription error on $channel: $data');
          break;

        case 'private.message.sent':
          _handleMessage(data, channel: channel, isGroup: false);
          break;

        case 'group.message.sent':
          _handleMessage(data, channel: channel, isGroup: true);
          break;

        default:
          break;
      }
    } catch (e) {
      print('WS parse error: $e | raw=$raw');
    }
  }

  void _onError(Object error) {
    print('WS error: $error');
    _isConnected = false;
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  void _onDone() {
    print('WS closed (intentional=$_intentionalClose)');
    _isConnected = false;
    _pingTimer?.cancel();
    if (!_intentionalClose) _scheduleReconnect();
  }

  // ── Reconnection (exponential backoff) ──────────────────────────────────────

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delay = _backoffDelay();
    print('WS reconnecting in ${delay.inSeconds}s (attempt $_retryCount)');
    FlutterForegroundTask.updateService(
      notificationTitle: 'Defcomm Active',
      notificationText: 'Reconnecting...',
    );
    _reconnectTimer = Timer(delay, () {
      _retryCount++;
      _connect();
    });
  }

  void _reconnect({bool immediate = false}) {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    try { _channel?.sink.close(); } catch (_) {}
    _retryCount = 0;
    if (immediate) {
      _connect();
    } else {
      _scheduleReconnect();
    }
  }

  Duration _backoffDelay() {
    final seconds = _retryCount < 6 ? (2 << _retryCount).clamp(2, 60) : 60;
    return Duration(seconds: seconds);
  }

  // ── Pusher channel subscription ─────────────────────────────────────────────

  Future<void> _subscribeAll() async {
    if (_socketId == null || _token.isEmpty || _userId.isEmpty) return;
    await _subscribeTo('private-chat.$_userId');
    for (final gId in _groupIds) {
      await _subscribeTo('private-group.$gId');
    }
  }

  Future<void> _subscribeTo(String channelName) async {
    if (_socketId == null) return;
    try {
      final resp = await http.post(
        Uri.parse(_kAuthUrl),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'channel_name=$channelName&socket_id=$_socketId',
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        print('WS auth failed for $channelName: ${resp.statusCode}');
        return;
      }
      final authData = jsonDecode(resp.body) as Map<String, dynamic>;
      final auth = (authData['auth'] as String?) ?? '';
      _send({
        'event': 'pusher:subscribe',
        'data': {'auth': auth, 'channel': channelName},
      });
    } catch (e) {
      print('WS subscribeTo error ($channelName): $e');
    }
  }

  // ── Heartbeat ───────────────────────────────────────────────────────────────

  void _startPingTimer(int activityTimeoutSecs) {
    _pingTimer?.cancel();
    final interval = Duration(seconds: (activityTimeoutSecs ~/ 2).clamp(15, 60));
    _pingTimer = Timer.periodic(interval, (_) {
      if (_isConnected) {
        _send({'event': 'pusher:ping', 'data': {}});
      }
    });
  }

  // ── Message handler ─────────────────────────────────────────────────────────

  void _handleMessage(
    dynamic data, {
    required String channel,
    required bool isGroup,
  }) {
    try {
      final Map<String, dynamic> payload =
          data is Map ? Map<String, dynamic>.from(data) : {};

      final root     = (payload['data'] is Map ? payload['data'] : payload) as Map<dynamic, dynamic>;
      dynamic source = root['mss'] ?? root['data'] ?? root;
      final baseMap  = source is Map
          ? Map<String, dynamic>.from(source)
          : <String, dynamic>{};

      final stateStr  = (root['state'] ?? baseMap['state'] ?? '').toString();
      final senderObj = root['sender'];
      final String senderId = (senderObj is Map
              ? (senderObj['id'] ?? senderObj['user_id'])
              : (baseMap['user_id'] ?? baseMap['sender_id'] ?? ''))
          .toString();
      final String senderName =
          (senderObj is Map ? (senderObj['name'] ?? 'Unknown') : 'Unknown')
              .toString();
      final bool isMyMsg = senderId == _userId;
      final String msgText =
          (baseMap['message'] ?? baseMap['body'] ?? '').toString();

      // ── Call invite ──────────────────────────────────────────────────────
      if (msgText.startsWith(kCallControlInvitePrefix) && !isMyMsg) {
        final parts    = msgText.split('|');
        final meetingId = parts.length >= 2 ? parts[1].trim() : '';
        _showCallNotification(
          callerId: senderId,
          callerName: senderName,
          meetingId: meetingId,
        );
        return;
      }

      // ── End call signals ─────────────────────────────────────────────────
      if (msgText == kCallControlRejected || msgText == kCallControlEnded) {
        FlutterForegroundTask.sendDataToMain({'event': 'endCalls'});
        return;
      }
      if (msgText == kCallControlAccepted) return;

      // ── Chat messages only ───────────────────────────────────────────────
      if (stateStr != 'text') return;
      if (isMyMsg) return;

      if (isGroup || (baseMap['chat_user_type'] ?? '') == 'group') {
        final groupName = (baseMap['group_name'] ??
                root['group_name'] ??
                'Group')
            .toString();
        final groupId = channel.contains('private-group.')
            ? channel.split('.').last
            : (baseMap['group_to'] ?? baseMap['chat_id'] ?? '').toString();
        _showMessageNotification(
          title: groupName,
          body: '$senderName: ******',
          chatIdEn: groupId,
          isGroup: true,
        );
      } else {
        _showMessageNotification(
          title: senderName,
          body: '******',
          chatIdEn: senderId,
          isGroup: false,
        );
      }
    } catch (e) {
      print('WS _handleMessage error: $e');
    }
  }

  // ── Local notifications ─────────────────────────────────────────────────────

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(
      const InitializationSettings(android: androidInit),
    );
    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _kMsgChannelId,
            'Messages',
            description: 'Incoming message notifications',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
            showBadge: true,
          ),
        );
  }

  Future<void> _showMessageNotification({
    required String title,
    required String body,
    required String chatIdEn,
    required bool isGroup,
  }) async {
    // Skip message notifications when app is in foreground — chat UI handles them.
    if (_isAppForeground) return;
    try {
      FlutterForegroundTask.sendDataToMain({'event': 'wakeScreen'});
      await _notif.show(
        chatIdEn.hashCode.abs() % 100000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _kMsgChannelId,
            'Messages',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            enableVibration: true,
            playSound: true,
          ),
        ),
        payload: jsonEncode({
          'kind': isGroup ? 'group' : 'user',
          'chatIdEn': chatIdEn,
        }),
      );
    } catch (e) {
      print('WS showMessageNotification error: $e');
    }
  }

  Future<void> _showCallNotification({
    required String callerId,
    required String callerName,
    required String meetingId,
  }) async {
    // When the app is in the foreground, Pusher handles the CallKit UI.
    // Only show from the WS service when screen is off / app is backgrounded.
    if (_isAppForeground) return;
    // Signal the main isolate to wake the screen via WakePlugin → WakeScreenReceiver.
    // This fires first so the WakeLock is acquired before the CallKit UI is shown.
    FlutterForegroundTask.sendDataToMain({'event': 'wakeScreen'});
    // Also signal the main isolate to show CallKit if it is active.
    FlutterForegroundTask.sendDataToMain({
      'event': 'incomingCall',
      'callerId': callerId,
      'callerName': callerName,
      'meetingId': meetingId,
    });
    // Primary: call CallKit directly from this isolate.
    // DartPluginRegistrant.ensureInitialized() in onStart wires up all
    // platform channels so this works even when the main isolate is paused.
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
        id: meetingId.isNotEmpty
            ? meetingId
            : DateTime.now().millisecondsSinceEpoch.toString(),
        nameCaller: callerName,
        appName: 'Defcomm',
        handle: callerName,
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
          'callerId': callerId,
          'callerName': callerName,
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
      print('WS CallKit error: $e');
    }
  }

  // ── WebSocket send ──────────────────────────────────────────────────────────

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (e) {
      print('WS send error: $e');
    }
  }
}
