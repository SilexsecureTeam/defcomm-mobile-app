import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init(
    Future<void> Function(String?) onNotificationTap,
  ) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        await onNotificationTap(resp.payload);
      },
    );

    // Explicitly create the channel used by showNotification() so
    // lockscreenVisibility is set before any notification is shown.
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'defcomm_chat_channel',
          'Defcomm Chat',
          description: 'Chat & group notifications',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
          enableLights: true,
        ),
      );
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    bool isGroup = false,
    String? chatIdEn,
  }) async {
    debugPrint("\n" + "="*60);
    debugPrint("🔔 LOCAL NOTIFICATION SERVICE - showNotification()");
    debugPrint("   ID: $id");
    debugPrint("   Title: $title");
    debugPrint("   Body: $body");
    debugPrint("   Is Group: $isGroup");
    debugPrint("   Chat ID: $chatIdEn");
    debugPrint("   Payload: $payload");
    debugPrint("="*60);
    
    try {
      final androidDetails = AndroidNotificationDetails(
        'defcomm_chat_channel',
        'Defcomm Chat',
        channelDescription: 'Chat & group notifications',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
        fullScreenIntent: true,

        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText:
              isGroup ? 'New message in $title' : 'New message from $title',
        ),

        timeoutAfter: 15000,
        groupKey: chatIdEn ?? 'defcomm_chat',
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      
      debugPrint("✅ Local notification displayed successfully");
    } catch (e, stack) {
      debugPrint("❌ ERROR showing local notification: $e");
      debugPrint("Stack: $stack");
      rethrow;
    }
  }
}
