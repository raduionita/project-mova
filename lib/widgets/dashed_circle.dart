import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dashes an oval outline around its child.
class DashedCircle extends StatelessWidget {
  const DashedCircle({
    super.key,
    required this.child,
    this.color = AppColors.lime,
    this.strokeWidth = 1.2,
    this.dashLength = 3.4,
    this.gapLength = 2.6,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedCirclePainter(
        color: color,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: child,
    );
  }
}

/// Paints a dashed oval inside the given size.
class DashedCirclePainter extends CustomPainter {
  const DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashLength = 3.4,
    this.gapLength = 2.6,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
