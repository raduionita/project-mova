import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Circular progress indicator from DESIGN.md section 8.10.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.label,
    required this.valueLabel,
    this.size = 104,
    this.strokeWidth = 12,
  });

  final double value;
  final String label;
  final String valueLabel;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    final innerSize = size - strokeWidth * 2;
    return Semantics(
      label: label,
      value: valueLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: Size.square(size),
                painter: _ProgressRingPainter(
                  progress: progress,
                  strokeWidth: strokeWidth,
                ),
              ),
              Container(
                width: innerSize,
                height: innerSize,
                decoration: const BoxDecoration(
                  color: AppColors.ringInner,
                  shape: BoxShape.circle,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    valueLabel,
                    style: AppTypography.metric.copyWith(color: AppColors.text),
                  ),
                  Text(
                    label.toUpperCase(),
                    style: AppTypography.micro.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final track = Paint()
      ..color = AppColors.ringTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) {
      return;
    }
    final fill = Paint()
      ..color = AppColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
