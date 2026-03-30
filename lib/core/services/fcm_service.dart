import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:defcomm/core/constants/base_url.dart';
import 'package:defcomm/core/services/ccallkit_service.dart';

// ─── Notification Channel IDs (WhatsApp-style) ───
const String _msgChannelId = 'defcomm_messages';
const String _msgChannelName = 'Messages';
const String _msgChannelDesc = 'New message notifications';

const String _callChannelId = 'defcomm_calls';
const String _callChannelName = 'Calls';
const String _callChannelDesc = 'Incoming call notifications';

const String _groupChannelId = 'defcomm_groups';
const String _groupChannelName = 'Group Messages';
const String _groupChannelDesc = 'Group message notifications';

// ─── Helper: create & init local notifications plugin ───
Future<FlutterLocalNotificationsPlugin> _initLocalNotifications() async {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
  await plugin.initialize(initSettings);

  // Create high-priority channels (like WhatsApp)
  final androidPlugin =
      plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _msgChannelId,
        _msgChannelName,
        description: _msgChannelDesc,
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
        enableLights: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _callChannelId,
        _callChannelName,
        description: _callChannelDesc,
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
        enableLights: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _groupChannelId,
        _groupChannelName,
        description: _groupChannelDesc,
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
        enableLights: true,
      ),
    );
  }

  return plugin;
}

// ─── Show a heads-up message notification (WhatsApp style) ───
Future<void> _showMessageNotification(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body, {
  String chatId = '',
  bool isGroup = false,
}) async {
  final String channelId = isGroup ? _groupChannelId : _msgChannelId;
  final String channelName = isGroup ? _groupChannelName : _msgChannelName;

  // Use chatId hashCode for notification ID so same chat stacks/updates
  final int notifId = chatId.isNotEmpty
      ? chatId.hashCode
      : DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    channelId,
    channelName,
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    category: AndroidNotificationCategory.message,
    visibility: NotificationVisibility.public,
    fullScreenIntent: true,
    styleInformation: BigTextStyleInformation(body, contentTitle: title),
  );

  final DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  await plugin.show(
    notifId,
    title,
    body,
    NotificationDetails(android: androidDetails, iOS: iosDetails),
    payload: jsonEncode({
      'kind': isGroup ? 'group' : 'user',
      'chatIdEn': chatId,
      'chatName': title,
    }),
  );
}


// ─── TOP-LEVEL BACKGROUND HANDLER ───
// Runs in its own isolate when app is killed OR screen is off (Doze).
// FCM high-priority DATA messages bypass Doze — this is the ONLY reliable
// delivery path when the screen is off, exactly like WhatsApp.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Required for any Flutter plugin to work in a background isolate.
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  debugPrint('\n' + '='*60);
  debugPrint('📩 FCM BACKGROUND HANDLER FIRED');
  debugPrint('   Message ID: ${message.messageId}');
  debugPrint('   Data keys: ${message.data.keys.toList()}');
  debugPrint('   Data: ${message.data}');
  debugPrint('   Notification title: ${message.notification?.title}');
  debugPrint('   Notification body: ${message.notification?.body}');
  debugPrint('='*60);

  // ── Step 0: Acquire wake lock immediately ────────────────────────────────
  // Turns the screen on before we attempt to show any UI.
  try {
    await const MethodChannel('come.deffcom.chatapp/oem_battery')
        .invokeMethod('wakeScreen');
  } catch (_) {}

  // ── Step 0b: Show a guaranteed diagnostic notification ─────────────────
  // This fires BEFORE any message-type logic so you can confirm FCM is
  // actually reaching the device. Remove once delivery is confirmed.
  try {
    final diagPlugin = await _initLocalNotifications();
    await diagPlugin.show(
      99999,
      'FCM Received',
      'type=${message.data['message_type'] ?? message.data['type'] ?? 'none'} | keys=${message.data.keys.join(',')}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'defcomm_messages',
          'Messages',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
      ),
    );
  } catch (e) {
    debugPrint('FCM BG: diagnostic notification error: $e');
  }

  final data = message.data;
  final String messageType = data['message_type'] ?? data['type'] ?? '';

  bool handled = false;

  if (messageType == 'call') {
    // ── Incoming Call — show native CallKit / full-screen ring UI ──────────
    handled = true;
    try {
      await CallKitService.showIncomingCall(
        callerName: data['caller_name'] ?? 'Unknown',
        callerId: data['caller_id'] ?? '',
        meetingId: data['meeting_id'] ?? '',
      );
    } catch (e) {
      debugPrint('FCM BG: CallKit error: $e');
    }
  } else if (messageType == 'private_message' ||
      messageType == 'message' ||
      messageType == 'private_group_message' ||
      messageType == 'group_message') {
    // ── Message Notification — ALWAYS show manually ────────────────────────
    handled = true;
    try {
      final bool isGroup = messageType == 'private_group_message' ||
          messageType == 'group_message';
      final String title = message.notification?.title ??
          (isGroup
              ? (data['group_name'] ?? 'Group Message')
              : (data['sender_name'] ?? 'New Message'));
      final String senderName = data['sender_name'] ?? '';
      final String body =
          isGroup && senderName.isNotEmpty ? '$senderName: •••' : '•••';
      final String chatId = isGroup
          ? (data['group_id'] ?? data['chat_id'] ?? '')
          : (data['sender_id'] ?? data['chat_id'] ?? data['receiver_id'] ?? '');

      final plugin = await _initLocalNotifications();
      await _showMessageNotification(
        plugin,
        title,
        body,
        chatId: chatId,
        isGroup: isGroup,
      );
    } catch (e) {
      debugPrint('FCM BG: notification error: $e');
    }
  }

  // ── Fallback: unknown / empty message_type ───────────────────────────────
  // The server may push a generic wake-up FCM whose only job is to wake the
  // device so Pusher can reconnect. Still show a notification so the user
  // knows something arrived, and display it using whatever data we have.
  if (!handled && data.isNotEmpty) {
    try {
      // If any call-related field is present treat it as a call.
      final bool looksLikeCall = data.containsKey('caller_name') ||
          data.containsKey('caller_id') ||
          data.containsKey('meeting_id') ||
          (data['state'] ?? '').toString().contains('call');

      if (looksLikeCall) {
        await CallKitService.showIncomingCall(
          callerName: data['caller_name'] ?? data['sender_name'] ?? 'Unknown',
          callerId: data['caller_id'] ?? data['sender_id'] ?? '',
          meetingId: data['meeting_id'] ?? '',
        );
      } else {
        // Generic message notification
        final plugin = await _initLocalNotifications();
        final String title = message.notification?.title ??
            data['sender_name'] ??
            data['group_name'] ??
            data['title'] ??
            'Defcomm';
        final String body =
            message.notification?.body ?? data['body'] ?? data['message'] ?? '•••';
        final String chatId =
            data['sender_id'] ?? data['group_id'] ?? data['chat_id'] ?? '';
        final bool isGroup = data.containsKey('group_id') ||
            data.containsKey('group_name');
        await _showMessageNotification(
          plugin,
          title,
          body,
          chatId: chatId,
          isGroup: isGroup,
        );
      }
    } catch (e) {
      debugPrint('FCM BG: fallback notification error: $e');
    }
  }

  // ── Always: reconnect Pusher so queued real-time events are delivered ─────
  // After this FCM wake we want Pusher ready for any pending call/message
  // that may arrive over the real-time channel.
  try {
    await GetStorage.init();
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('forcePusherReconnect');
    }
  } catch (_) {}
}

// ─── FCM SERVICE CLASS ───
class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin? _localNotif;

  /// Initialize FCM: permissions, channels, token, listeners.
  /// Token is sent during login — this handles everything else.
  Future<void> init({
    required String authToken,
    Future<void> Function(String?)? onNotificationTap,
  }) async {
    debugPrint("\n" + "="*60);
    debugPrint("🚀 INITIALIZING FCM SERVICE");
    debugPrint("="*60);
    
    // 1. Request permission (iOS + Android 13+)
    debugPrint("📋 Step 1: Requesting notification permissions...");
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    debugPrint("✅ Permission status: ${settings.authorizationStatus}");
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("   ✓ Notifications AUTHORIZED");
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint("   ⚠️ Notifications PROVISIONAL");
    } else {
      debugPrint("   ❌ Notifications DENIED");
    }

    // 2. Set foreground notification presentation (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Create notification channels early (Android)
    _localNotif = await _initLocalNotifications();

    // 4. Get current token and immediately sync to backend
    debugPrint("\n📋 Step 4: Getting FCM token and syncing to backend...");
    final String? fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      debugPrint("✅ FCM Token obtained (length: ${fcmToken.length})");
      debugPrint("");
      debugPrint("🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑");
      debugPrint("FCM TOKEN FOR FIREBASE CONSOLE TEST:");
      debugPrint(fcmToken);
      debugPrint("🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑🔑");
      debugPrint("");
      // Always resync on app start — ensures backend has latest token
      // even when user didn't re-login (token may have rotated)
      await _sendTokenToBackend(fcmToken, authToken);
    } else {
      debugPrint("❌ FAILED to get FCM token!");
    }

    // 5. Listen for token refresh
    debugPrint("\n📋 Step 5: Setting up token refresh listener...");
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint("\n" + "="*60);
      debugPrint("🔄 FCM TOKEN REFRESHED");
      debugPrint("   New Token: $newToken");
      debugPrint("="*60);
      _sendTokenToBackend(newToken, authToken);
    });
    debugPrint("✅ Token refresh listener active");

    // 6. Handle FOREGROUND messages — show notification even while in app
    debugPrint("\n📋 Step 6: Setting up foreground message listener...");
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("\n" + "="*60);
      debugPrint("📩 FCM FOREGROUND MESSAGE RECEIVED");
      debugPrint("   Message ID: ${message.messageId}");
      debugPrint("   Data: ${message.data}");
      debugPrint("="*60);
      _handleForegroundMessage(message);
    });
    debugPrint("✅ Foreground message listener active");

    // 7. Handle notification tap that opened the app from background
    debugPrint("\n📋 Step 7: Setting up notification tap listener...");
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("\n" + "="*60);
      debugPrint("📲 USER TAPPED NOTIFICATION (App in background)");
      debugPrint("   Message ID: ${message.messageId}");
      debugPrint("   Data: ${message.data}");
      debugPrint("="*60);
      if (onNotificationTap != null) {
        final payload = _buildPayloadFromMessage(message.data);
        if (payload != null) {
          debugPrint("   Navigating to: $payload");
          onNotificationTap(payload);
        } else {
          debugPrint("   ⚠️ No payload generated from message data");
        }
      } else {
        debugPrint("   ⚠️ No onNotificationTap callback provided");
      }
    });
    debugPrint("✅ Notification tap listener active");

    // 8. Check if app was opened from a terminated state by a notification
    debugPrint("\n📋 Step 8: Checking for cold-start notification...");
    final RemoteMessage? initialMessage =
        await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("\n" + "="*60);
      debugPrint("🚀 APP OPENED FROM NOTIFICATION (Cold start)");
      debugPrint("   Message ID: ${initialMessage.messageId}");
      debugPrint("   Data: ${initialMessage.data}");
      debugPrint("="*60);
      if (onNotificationTap != null) {
        final payload = _buildPayloadFromMessage(initialMessage.data);
        if (payload != null) {
          debugPrint("   Scheduling navigation to: $payload");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onNotificationTap(payload);
          });
        } else {
          debugPrint("   ⚠️ No payload generated from initial message");
        }
      } else {
        debugPrint("   ⚠️ No onNotificationTap callback provided");
      }
    } else {
      debugPrint("   No initial message (normal app launch)");
    }
    
    debugPrint("\n" + "="*60);
    debugPrint("✅ FCM SERVICE INITIALIZATION COMPLETE");
    debugPrint("="*60 + "\n");
  }

  /// Handle messages received while app is in FOREGROUND.
  ///
  /// Calls   → show CallKit (Pusher may have caught it first; this is the fallback).
  /// Messages → do NOTHING — the foreground PusherService already received the
  ///            same event, updated the chat bloc, and shows a local notification
  ///            only when the chat is not open. Showing an FCM notification here
  ///            too would give the user a duplicate.
  void _handleForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final String messageType = data['message_type'] ?? data['type'] ?? '';

    if (messageType == 'call') {
      await CallKitService.showIncomingCall(
        callerName: data['caller_name'] ?? 'Unknown',
        callerId: data['caller_id'] ?? '',
        meetingId: data['meeting_id'] ?? '',
      );
    }
    // Messages are intentionally ignored here — Pusher handles them in foreground.
  }

  /// Convert FCM message data map into a JSON payload string for navigation
  String? _buildPayloadFromMessage(Map<String, dynamic> data) {
    final String messageType = data['message_type'] ?? data['type'] ?? '';
    if (messageType == 'private_message' || messageType == 'message') {
      // sender_id is the encrypted ID of the person who sent the message.
      // receiver_id is the local user's own ID — never use it for navigation.
      final chatId = data['sender_id'] ?? data['chat_id'] ?? '';
      final title = data['sender_name'] ?? data['title'] ?? '';
      if (chatId.isEmpty) return null;
      return jsonEncode({
        'kind': 'user',
        'chatIdEn': chatId,
        'chatName': title,
      });
    } else if (messageType == 'private_group_message' || messageType == 'group_message') {
      final chatId = data['group_id'] ?? data['chat_id'] ?? '';
      final title = data['group_name'] ?? data['title'] ?? 'Group';
      if (chatId.isEmpty) return null;
      return jsonEncode({
        'kind': 'group',
        'chatIdEn': chatId,
        'chatName': title,
      });
    }
    return null;
  }

  /// Send FCM token to backend — called on login, token refresh, and app start.
  /// Sends both fcm_token and device_token fields since the backend uses both.
  Future<void> _sendTokenToBackend(String fcmToken, String authToken) async {
    debugPrint("\n📤 Sending FCM token to backend...");
    debugPrint("   Token (first 20): ${fcmToken.substring(0, fcmToken.length > 20 ? 20 : fcmToken.length)}...");
    debugPrint("   Token length: ${fcmToken.length}");
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app/configuration'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'device_token': fcmToken,
        }),
      );
      
      debugPrint("📥 FCM token update response: ${response.statusCode}");
      debugPrint("   Response body: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ FCM token sent to backend successfully");
      } else {
        debugPrint("⚠️ FCM token update FAILED: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Failed to send FCM token: $e");
    }
  }
}
