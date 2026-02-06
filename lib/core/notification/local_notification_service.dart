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
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    bool isGroup = false,
    String? chatIdEn,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'defcomm_chat_channel',
      'Defcomm Chat',
      channelDescription: 'Chat & group notifications',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,

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
  }
}
