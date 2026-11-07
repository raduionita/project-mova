import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Vertical ruler slider. The value snaps to [step] and the ruler scrolls
/// under a fixed lime center marker.
class AppVerticalRulerSlider extends StatefulWidget {
  const AppVerticalRulerSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.unitLabel,
    this.valueLabel,
    this.minLabel,
    this.maxLabel,
    this.hint,
    this.enabled = true,
    this.pixelsPerStep = 10,
    this.height = 260,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String? unitLabel;
  final String? valueLabel;
  final String? minLabel;
  final String? maxLabel;
  final String? hint;
  final bool enabled;
  final double pixelsPerStep;
  final double height;

  @override
  State<AppVerticalRulerSlider> createState() => _AppVerticalRulerSliderState();
}

class _AppVerticalRulerSliderState extends State<AppVerticalRulerSlider> {
  final GlobalKey _rulerKey = GlobalKey();

  late double _current;
  double _accumulated = 0;

  @override
  void initState() {
    super.initState();
    _current = _snap(widget.value);
  }

  @override
  void didUpdateWidget(covariant AppVerticalRulerSlider oldWidget) {
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
    _accumulated += -details.delta.dy;
    final steps = (_accumulated / widget.pixelsPerStep).truncate();
    if (steps == 0) {
      return;
    }
    _accumulated -= steps * widget.pixelsPerStep;
    _emit(_current + steps * widget.step);
  }

  void _handleTapDown(TapDownDetails details) {
    final box = _rulerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final local = box.globalToLocal(details.globalPosition);
    if (local.dy < 0 || local.dy > box.size.height) {
      return;
    }
    final steps = ((box.size.height / 2 - local.dy) / widget.pixelsPerStep)
        .round();
    _emit(_current + steps * widget.step);
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _label(double raw) {
    final value = _format(_snap(raw));
    return widget.unitLabel == null ? value : '$value ${widget.unitLabel}';
  }

  Widget _buildValue() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          widget.valueLabel ?? _format(_current),
          style: AppTypography.h1.copyWith(fontSize: 38, color: AppColors.text),
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

  Widget _buildRangeLabel(String label) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(color: AppColors.muted),
    );
  }

  Widget _buildRuler() {
    final unit = widget.unitLabel;
    final minLabel =
        widget.minLabel ??
        (unit == null ? _format(widget.min) : '${_format(widget.min)} $unit');
    final maxLabel =
        widget.maxLabel ??
        (unit == null ? _format(widget.max) : '${_format(widget.max)} $unit');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          key: _rulerKey,
          width: 56,
          height: widget.height,
          child: CustomPaint(
            painter: _VerticalRulerPainter(
              value: _current,
              min: widget.min,
              max: widget.max,
              step: widget.step,
              pixelsPerStep: widget.pixelsPerStep,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        SizedBox(
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildRangeLabel(maxLabel),
              _buildRangeLabel(minLabel),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.valueLabel ?? _format(_current);
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onVerticalDragStart: (_) => _accumulated = 0,
            onVerticalDragUpdate: _handleDragUpdate,
            onTapDown: _handleTapDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildValue(),
                const SizedBox(height: AppSpacing.xl),
                _buildRuler(),
                if (widget.hint != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.hint!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalRulerPainter extends CustomPainter {
  const _VerticalRulerPainter({
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
      Radius.circular(size.width / 2),
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

    final centerY = size.height / 2;
    final halfSteps = (size.height / 2 / pixelsPerStep).ceil() + 1;
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
      final y = centerY + (value - tickValue) / step * pixelsPerStep;
      final major = stepIndex % 5 == 0;
      final width = major ? 19.0 : 11.0;
      canvas.drawLine(
        Offset(size.width / 2 - width / 2, y),
        Offset(size.width / 2 + width / 2, y),
        major ? majorPaint : tickPaint,
      );
    }

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()
        ..color = AppColors.lime
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VerticalRulerPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.step != step ||
        oldDelegate.pixelsPerStep != pixelsPerStep;
  }
}
