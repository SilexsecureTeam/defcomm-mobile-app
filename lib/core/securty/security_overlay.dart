import 'dart:ui';
import 'package:flutter/material.dart';

class SecurityOverlay {
  static final SecurityOverlay _instance = SecurityOverlay._internal();

  factory SecurityOverlay() => _instance;

  SecurityOverlay._internal();

  OverlayEntry? _entry;
  bool _visible = false;

  void show(BuildContext context, {String? reason}) {
    if (_visible) return;

    _entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // blur everything
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 48, color: Colors.redAccent),

                  const SizedBox(height: 12),

                  const Text(
                    "Sensitive content hidden",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    reason ?? "Camera activity was detected.",
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: hide,
                    child: const Text(
                      "Continue",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_entry!);
    _visible = true;
  }

  void hide() {
    if (!_visible) return;
    _entry?.remove();
    _entry = null;
    _visible = false;
  }
}
