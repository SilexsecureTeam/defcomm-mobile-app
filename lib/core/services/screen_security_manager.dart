import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'package:screen_protector/screen_protector.dart';

class ScreenSecurityManager with WidgetsBindingObserver {
  static final ScreenSecurityManager _instance =
      ScreenSecurityManager._internal();

  factory ScreenSecurityManager() => _instance;

  ScreenSecurityManager._internal();

  bool _listenerRegistered = false;

  Future<void> initialize({required VoidCallback onScreenshotAttempt}) async {
    WidgetsBinding.instance.addObserver(this);

    // 🔐 Android: block screenshots globally
    if (Platform.isAndroid) {
      await FlutterWindowManagerPlus.addFlags(
        FlutterWindowManagerPlus.FLAG_SECURE,
      );
    }

    // 👀 iOS (+ Android no-op): detect screenshots
    if (!_listenerRegistered) {
      ScreenProtector.addListener(
        onScreenshotAttempt,
        (isRecording) {
          debugPrint('Screen recording: $isRecording');
        }, // screen recording callback (optional)
      );
      _listenerRegistered = true;
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);

    if (Platform.isAndroid) {
      await FlutterWindowManagerPlus.clearFlags(
        FlutterWindowManagerPlus.FLAG_SECURE,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isAndroid && state == AppLifecycleState.resumed) {
      FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
    }
  }
}
