import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/unit_preferences.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/unit_conversion_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 5: body height. The value is shown in the chosen body unit
/// and stored in centimeters. Skip stores zero.
class HeightScreen extends StatefulWidget {
  const HeightScreen({super.key, this.onRoute});

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  static const int _minCm = 120;
  static const int _maxCm = 230;
  static const int _defaultCm = 175;

  final UnitConversionService _conversion = const UnitConversionService();

  late final HeightUnit _unit;
  late int _cm;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<OnboardingProvider>().draft;
    _unit = draft.unitPreferences.heightUnit;
    final saved = draft.heightCm.round();
    _cm = saved >= _minCm && saved <= _maxCm ? saved : _defaultCm;
  }

  void _open(BuildContext context, String route) {
    final handler = widget.onRoute;
    if (handler != null) {
      handler(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  void _handleChanged(double cm) {
    setState(() => _cm = cm.round().clamp(_minCm, _maxCm));
  }

  Future<void> _continue({bool skip = false}) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();

    await onboarding.setHeightCm(skip ? 0 : _cm.toDouble());
    final advanced = await onboarding.next();
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(
      context,
      advanced
          ? OnboardingFlow.nextRoute(Routes.onboardingHeight)!
          : Routes.onboardingHeight,
    );
  }

  void _back(BuildContext context) {
    _open(context, OnboardingFlow.previousRoute(Routes.onboardingHeight)!);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Your height',
      subtitle: 'Used for body measurements and progress context.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingHeight),
      onBack: () => _back(context),
      onContinue: _isBusy ? null : () => _continue(),
      isBusy: _isBusy,
      onSkip: _isBusy ? null : () => _continue(skip: true),
      skipLabel: 'Skip for now',
      child: _VerticalHeightRoller(
        valueCm: _cm.toDouble(),
        minCm: _minCm.toDouble(),
        maxCm: _maxCm.toDouble(),
        unit: _unit,
        conversion: _conversion,
        onChanged: _handleChanged,
      ),
    );
  }
}

class _VerticalHeightRoller extends StatefulWidget {
  const _VerticalHeightRoller({
    required this.valueCm,
    required this.minCm,
    required this.maxCm,
    required this.unit,
    required this.conversion,
    required this.onChanged,
  });

  final double valueCm;
  final double minCm;
  final double maxCm;
  final HeightUnit unit;
  final UnitConversionService conversion;
  final ValueChanged<double> onChanged;

  @override
  State<_VerticalHeightRoller> createState() => _VerticalHeightRollerState();
}

class _VerticalHeightRollerState extends State<_VerticalHeightRoller> {
  static const double _pixelsPerStep = 10;

  late double _current;
  double _accumulated = 0;

  @override
  void initState() {
    super.initState();
    _current = _clamp(widget.valueCm);
  }

  @override
  void didUpdateWidget(covariant _VerticalHeightRoller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.valueCm != oldWidget.valueCm) {
      _current = _clamp(widget.valueCm);
    }
  }

  double _clamp(double cm) => cm.clamp(widget.minCm, widget.maxCm).toDouble();

  void _emit(double raw) {
    final next = _clamp(raw.roundToDouble());
    if (next == _current) {
      return;
    }
    setState(() => _current = next);
    widget.onChanged(next);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _accumulated += -details.delta.dy;
    final steps = (_accumulated / _pixelsPerStep).truncate();
    if (steps == 0) {
      return;
    }
    _accumulated -= steps * _pixelsPerStep;
    _emit(_current + steps);
  }

  void _handleTapDown(TapDownDetails details, double height) {
    final steps = ((height / 2 - details.localPosition.dy) / _pixelsPerStep)
        .round();
    _emit(_current + steps);
  }

  String _formatValue(double cm) {
    if (widget.unit == HeightUnit.cm) {
      return cm.toStringAsFixed(0);
    }
    return widget.conversion.cmToIn(cm).toStringAsFixed(1);
  }

  String _unitLabel() => widget.conversion.heightLabel(widget.unit);

  String _spokenValue(double cm) => '${_formatValue(cm)} ${_unitLabel()}';

  Widget _buildNumber() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              _formatValue(_current),
              style: AppTypography.h1.copyWith(
                fontSize: 38,
                color: AppColors.text,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _unitLabel(),
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Drag to adjust',
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      value: _spokenValue(_current),
      increasedValue: _spokenValue(_current + 1),
      decreasedValue: _spokenValue(_current - 1),
      onIncrease: () => _emit(_current + 1),
      onDecrease: () => _emit(_current - 1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onVerticalDragStart: (_) => _accumulated = 0,
        onVerticalDragUpdate: _handleDragUpdate,
        onTapDown: (details) => _handleTapDown(details, 180),
        child: SizedBox(
          height: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 54,
                height: 176,
                child: CustomPaint(
                  painter: _VerticalRulerPainter(
                    value: _current,
                    min: widget.minCm,
                    max: widget.maxCm,
                    pixelsPerStep: _pixelsPerStep,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x3l),
              _buildNumber(),
            ],
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
    required this.pixelsPerStep,
  });

  final double value;
  final double min;
  final double max;
  final double pixelsPerStep;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width / 2),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF131C2E));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke,
    );

    final ratio = max == min ? 0.0 : (value - min) / (max - min);
    final fillHeight = size.height * ratio.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRRect(rect);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - fillHeight, size.width, fillHeight),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x0AB7F24C), Color(0x3DB7F24C)],
        ).createShader(Offset.zero & size),
    );
    canvas.restore();

    final centerY = size.height / 2;
    final halfSteps = (size.height / 2 / pixelsPerStep).ceil() + 1;
    final firstStep = ((value - min) / pixelsPerStep).floor() - halfSteps;
    final lastStep = ((value - min) / pixelsPerStep).ceil() + halfSteps;
    final tickPaint = Paint()
      ..color = const Color(0xFF33405C)
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = const Color(0xFF4A5A7C)
      ..strokeWidth = 1;

    for (var step = firstStep; step <= lastStep; step++) {
      final tickValue = min + step;
      if (tickValue < min || tickValue > max) {
        continue;
      }
      final y = centerY - (tickValue - value) * pixelsPerStep;
      final major = step % 5 == 0;
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
  }

  @override
  bool shouldRepaint(covariant _VerticalRulerPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.pixelsPerStep != pixelsPerStep;
  }
}
