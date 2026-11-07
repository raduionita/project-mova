import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Horizontal ruler slider. The value snaps to [step] and the ruler scrolls
/// under a fixed lime center marker.
class AppRulerSlider extends StatefulWidget {
  const AppRulerSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.unitLabel,
    this.enabled = true,
    this.pixelsPerStep = 12,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String? unitLabel;
  final bool enabled;
  final double pixelsPerStep;

  @override
  State<AppRulerSlider> createState() => _AppRulerSliderState();
}

class _AppRulerSliderState extends State<AppRulerSlider> {
  late double _current;
  double _accumulated = 0;

  @override
  void initState() {
    super.initState();
    _current = _snap(widget.value);
  }

  @override
  void didUpdateWidget(covariant AppRulerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _current = _snap(widget.value);
    }
  }

  double _snap(double raw) {
    if (widget.step <= 0) {
      return raw.clamp(widget.min, widget.max).toDouble();
    }
    final steps = ((raw - widget.min) / widget.step).round();
    return (widget.min + steps * widget.step)
        .clamp(widget.min, widget.max)
        .toDouble();
  }

  void _emit(double raw) {
    final next = _snap(raw);
    if (next == _current) {
      return;
    }
    setState(() => _current = next);
    widget.onChanged(next);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _accumulated += details.delta.dx;
    final steps = (_accumulated / widget.pixelsPerStep).truncate();
    if (steps == 0) {
      return;
    }
    _accumulated -= steps * widget.pixelsPerStep;
    _emit(_current + steps * widget.step);
  }

  void _handleTapDown(TapDownDetails details, double width) {
    final steps =
        ((details.localPosition.dx - width / 2) / widget.pixelsPerStep).round();
    _emit(_current + steps * widget.step);
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  Widget _buildValue() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          _format(_current),
          style: AppTypography.h1.copyWith(fontSize: 36, color: AppColors.text),
        ),
        if (widget.unitLabel != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              widget.unitLabel!,
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRuler(double width) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragStart: (_) => _accumulated = 0,
      onHorizontalDragUpdate: _handleDragUpdate,
      onTapDown: (details) => _handleTapDown(details, width),
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: CustomPaint(
          painter: _RulerPainter(
            value: _current,
            min: widget.min,
            max: widget.max,
            step: widget.step,
            pixelsPerStep: widget.pixelsPerStep,
          ),
        ),
      ),
    );
  }

  String _label(double raw) {
    final value = _format(_snap(raw));
    return widget.unitLabel == null ? value : '$value ${widget.unitLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final value = _format(_current);
    return Semantics(
      slider: true,
      enabled: widget.enabled,
      value: widget.unitLabel == null ? value : '$value ${widget.unitLabel}',
      increasedValue: _label(_current + widget.step),
      decreasedValue: _label(_current - widget.step),
      onIncrease: widget.enabled ? () => _emit(_current + widget.step) : null,
      onDecrease: widget.enabled ? () => _emit(_current - widget.step) : null,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildValue(),
              const SizedBox(height: AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) =>
                    _buildRuler(constraints.maxWidth),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  const _RulerPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.pixelsPerStep,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final double pixelsPerStep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadii.lg - 3),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF151D30));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke,
    );

    if (step <= 0 || pixelsPerStep <= 0) {
      return;
    }

    final centerX = size.width / 2;
    final halfSteps = (size.width / 2 / pixelsPerStep).ceil() + 1;
    final firstStep = ((value - min) / step).floor() - halfSteps;
    final lastStep = ((value - min) / step).ceil() + halfSteps;

    final tickPaint = Paint()
      ..color = const Color(0xFF33405C)
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = const Color(0xFF4A5A7C)
      ..strokeWidth = 1;

    canvas.save();
    canvas.clipRRect(rect);
    for (var stepIndex = firstStep; stepIndex <= lastStep; stepIndex++) {
      final tickValue = min + stepIndex * step;
      if (tickValue < min || tickValue > max) {
        continue;
      }
      final x = centerX + (tickValue - value) / step * pixelsPerStep;
      final major = stepIndex % 5 == 0;
      final height = major ? 19.0 : 11.0;
      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        major ? majorPaint : tickPaint,
      );
    }

    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      Paint()
        ..color = AppColors.lime
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.step != step ||
        oldDelegate.pixelsPerStep != pixelsPerStep;
  }
}
