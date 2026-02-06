


import 'package:defcomm/core/services/security_reporter.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/material.dart';

DateTime? _lastCameraLog;

Future<void> logCameraEventSecurely() async {
  final now = DateTime.now();

  if (_lastCameraLog != null &&
      now.difference(_lastCameraLog!) < const Duration(seconds: 10)) {
    return;
  }

  _lastCameraLog = now;

  try {
    final success = await serviceLocator<SecurityReporter>().report(
      screen: "camera_detected",
    );

    debugPrint(
      success
          ? "✅ Camera event logged"
          : "⚠️ Camera event log failed",
    );
  } catch (e) {
    debugPrint("❌ Camera log error: $e");
  }
}
