
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';

class CallKitService {
  static final Uuid _uuid = Uuid();

  /// Listen for actions (Accept/Decline)
  static void init({
    required Function(String meetingId, String callerId, String callerName)
        onCallAccepted,
    required Function(String callerId) onCallEnded,
  }) {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;

      switch (event.event) {
        case Event.actionCallAccept:
          // 1. Determine data
          final data = event.body['extra'];
          final meetingId = data['meetingId'];
          final callerId = data['callerId'];
          final callerName = data['callerName'];

          // 2. IMPORTANT: Wait for app to be in foreground before navigating
          // This fixes the "screen not showing" issue
          onCallAccepted(meetingId, callerId, callerName);
          break;

        case Event.actionCallDecline:
        case Event.actionCallEnded:
          final data = event.body['extra'] ?? {};
          final callerId = data['callerId'] as String? ?? "";
          onCallEnded(callerId);
          break;

        default:
          break;
      }
    });
  }

  /// Show the Native Call UI
  static Future<void> showIncomingCall({
    required String callerName,
    required String callerId,
    required String meetingId,
    String? avatarUrl,
  }) async {
    final String callUUID = _uuid.v4();

    final params = CallKitParams(
      id: callUUID,
      nameCaller: callerName,
      appName: 'Defcomm',
      avatar: avatarUrl ?? 'https://i.pravatar.cc/100', // Puts image on lock screen
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
      extra: <String, dynamic>{
        'meetingId': meetingId,
        'callerId': callerId,
        'callerName': callerName,
      },
      headers: <String, dynamic>{'apiKey': 'Abc@123!', 'platform': 'flutter'},
      
      // 🎨 CUSTOMIZE ANDROID UI HERE
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1B5E20', // Your App's Green Color
        // backgroundUrl: 'https://your-server.com/call_bg.png', // Optional bg image
        actionColor: '#4CAF50',
        textColor: '#FFFFFF',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
  }

  // 🛠 NEW: Helper to check if app was opened by a call
  static Future<void> checkAndNavigationForCall(
      Function(String, String, String) onNavigate) async {
    // Get current active calls reported by native side
    var calls = await FlutterCallkitIncoming.activeCalls();
    if (calls is List && calls.isNotEmpty) {
      final callData = calls.first;
      final data = callData['extra'];
      if (data != null) {
        final meetingId = data['meetingId'];
        final callerId = data['callerId'];
        final callerName = data['callerName'];
        
        // Trigger navigation
        onNavigate(meetingId, callerId, callerName);
      }
    }
  }
}