
// --- NEW WIDGET: GradientCircularProgressIndicator ---
import 'dart:math';

import 'package:flutter/material.dart';

class GradientCircularProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Gradient gradient;

  const GradientCircularProgressIndicator({
    Key? key,
    required this.progress,
    required this.size,
    this.strokeWidth = 10.0,
    this.backgroundColor = Colors.grey,
    required this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GradientCircularProgressPainter(
        progress: progress,
        strokeWidth: strokeWidth,
        backgroundColor: backgroundColor,
        gradient: gradient,
      ),
    );
  }
}

// --- NEW PAINTER: The logic for drawing the gradient circle ---
class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Gradient gradient;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw the background track
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 2. Draw the gradient progress arc
    final foregroundPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round // Gives the rounded ends
      ..shader = gradient.createShader(rect);

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      rect,
      -pi / 2, // Start from the top
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Repaint whenever properties change
  }
}
