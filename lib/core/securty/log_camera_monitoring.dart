import 'package:defcomm/core/services/security_reporter.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

DateTime? _lastCameraLog;

Future<void> logCameraEventSecurely() async {
  final now = DateTime.now();

  // prevent logs more often than once per 10 seconds
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
          ? "✅ Camera event security log sent"
          : "⚠️ Failed to log camera event",
    );
  } catch (e) {
    debugPrint("❌ Camera event log error: $e");
  }
}
