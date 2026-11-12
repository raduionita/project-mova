import 'package:flutter/material.dart';

import '../models/weight_entry.dart';
import '../theme/app_colors.dart';

/// Simple line chart for the local weight log.
///
/// Entries must be ordered oldest first. A single entry renders as one point.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.entries, this.height = 150});

  final List<WeightEntry> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final values = entries
        .map((entry) => entry.weightKg)
        .toList(growable: false);
    final min = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a < b ? a : b);
    final max = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    final label = values.isEmpty
        ? 'No weight entries yet'
        : values.length == 1
        ? 'One weight entry: ${values.first.toStringAsFixed(1)} kilograms'
        : 'Weight trend, ${values.length} entries. Lowest '
              '${min.toStringAsFixed(1)} kilograms, highest '
              '${max.toStringAsFixed(1)} kilograms, latest '
              '${values.last.toStringAsFixed(1)} kilograms.';
    return Semantics(
      label: label,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: WeightChartPainter(values: values),
          size: Size.infinite,
        ),
      ),
    );
  }
}

/// Paints a lime polyline with dots and three quiet guide lines.
class WeightChartPainter extends CustomPainter {
  WeightChartPainter({required this.values});

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final guide = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var index = 0; index < 3; index++) {
      final y = size.height * (index + 1) / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }
    if (values.isEmpty) {
      return;
    }

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.1 ? 1.0 : max - min;
    final padding = 8.0;
    final usableWidth = size.width - padding * 2;
    final usableHeight = size.height - padding * 2;

    Offset pointAt(int index) {
      final x = values.length == 1
          ? size.width / 2
          : padding + usableWidth * index / (values.length - 1);
      final ratio = (values[index] - min) / range;
      final y = padding + usableHeight * (1 - ratio);
      return Offset(x, y);
    }

    final line = Paint()
      ..color = AppColors.lime
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = AppColors.lime;

    if (values.length > 1) {
      final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
      for (var index = 1; index < values.length; index++) {
        final point = pointAt(index);
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, line);
    }
    for (var index = 0; index < values.length; index++) {
      canvas.drawCircle(pointAt(index), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant WeightChartPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) {
      return true;
    }
    for (var index = 0; index < values.length; index++) {
      if (oldDelegate.values[index] != values[index]) {
        return true;
      }
    }
    return false;
  }
}
