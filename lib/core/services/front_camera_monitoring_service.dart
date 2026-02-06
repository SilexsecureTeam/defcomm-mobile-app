import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

DateTime? _lastRun;

class FrontCameraMonitoringService with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isMonitoring = false;
  bool _processing = false;

  Future<void> start({
    required void Function() onSuspiciousCaptureDetected,
  }) async {
    if (_isMonitoring) return;

    WidgetsBinding.instance.addObserver(this);

    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    _isMonitoring = true;

    _controller!.startImageStream((image) async {
  // throttle to ~2 FPS
  final now = DateTime.now();
  if (_lastRun != null &&
      now.difference(_lastRun!) < const Duration(milliseconds: 500)) {
    return;
  }
  _lastRun = now;

  if (_processing) return;
  _processing = true;

  try {
    final detected = _detectFlashFast(image);
    if (detected) onSuspiciousCaptureDetected();
  } finally {
    _processing = false;
  }
});

  }

  bool _detectFlashFast(CameraImage image) {
  // Use only luminance plane (Y) to reduce work
  final bytes = image.planes[0].bytes;

  final len = bytes.length;

  int bright = 0;
  int sampled = 0;

  // sample every 50th pixel only
  for (int i = 0; i < len; i += 50) {
    sampled++;
    if (bytes[i] > 235) bright++;
  }

  if (sampled == 0) return false;

  final ratio = bright / sampled;

  // ≥ 40% bright in sample -> likely flash/glare / bright phone
  return ratio > 0.40;
}


  Future<void> stop() async {
    if (!_isMonitoring) return;

    WidgetsBinding.instance.removeObserver(this);

    await _controller?.dispose();
    _controller = null;
    _isMonitoring = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      stop();
    } else if (state == AppLifecycleState.resumed) {
      // Optionally restart
    }
  }
}
