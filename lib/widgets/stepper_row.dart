import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Bounded plus and minus row from DESIGN.md section 8.5.
class StepperRow extends StatefulWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
    this.unitLabel,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;
  final String? unitLabel;

  @override
  State<StepperRow> createState() => _StepperRowState();
}

class _StepperRowState extends State<StepperRow> {
  Timer? _repeatTimer;

  bool get _canDecrease =>
      widget.onChanged != null && widget.value > widget.min;

  bool get _canIncrease =>
      widget.onChanged != null && widget.value < widget.max;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  void _change(int delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    if (next != widget.value) {
      widget.onChanged?.call(next);
    }
  }

  void _startRepeat(int delta) {
    _repeatTimer?.cancel();
    _repeatTimer = Timer(const Duration(milliseconds: 400), () {
      _change(delta);
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _change(delta);
      });
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  Widget _buildStepButton({
    required IconData icon,
    required String semanticLabel,
    required bool enabled,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final radius = BorderRadius.circular(AppRadii.sm);
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Listener(
          onPointerUp: (_) => _stopRepeat(),
          onPointerCancel: (_) => _stopRepeat(),
          child: Material(
            color: AppColors.surfaceAlt,
            shape: RoundedRectangleBorder(borderRadius: radius),
            child: InkWell(
              borderRadius: radius,
              overlayColor: const WidgetStatePropertyAll(
                AppColors.pressedSurface,
              ),
              onTap: enabled ? onTap : null,
              onLongPress: enabled ? onLongPress : null,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  icon,
                  size: 18,
                  color: enabled ? AppColors.text : AppColors.textDisabled,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valueText = '${widget.value}${widget.unitLabel ?? ''}';
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.stepperHorizontal,
        vertical: AppSpacing.stepperVertical,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ),
          _buildStepButton(
            icon: Icons.remove,
            semanticLabel: 'Decrease ${widget.label}',
            enabled: _canDecrease,
            onTap: () => _change(-1),
            onLongPress: () => _startRepeat(-1),
          ),
          SizedBox(
            width: 56,
            child: Text(
              valueText,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontFeatures: AppTypography.metric.fontFeatures,
              ),
            ),
          ),
          _buildStepButton(
            icon: Icons.add,
            semanticLabel: 'Increase ${widget.label}',
            enabled: _canIncrease,
            onTap: () => _change(1),
            onLongPress: () => _startRepeat(1),
          ),
        ],
      ),
    );
  }
}
