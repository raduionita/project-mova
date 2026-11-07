import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/unit_preferences.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/unit_conversion_service.dart';
import '../../widgets/app_vertical_ruler_slider.dart';
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

  String _formatHeight(double cm) {
    if (_unit == HeightUnit.cm) {
      return cm.toStringAsFixed(0);
    }
    return _conversion.cmToIn(cm).toStringAsFixed(1);
  }

  String _rangeLabel(double cm) {
    return '${_formatHeight(cm)} ${_conversion.heightLabel(_unit)}';
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
      child: AppVerticalRulerSlider(
        value: _cm.toDouble(),
        min: _minCm.toDouble(),
        max: _maxCm.toDouble(),
        step: 1,
        unitLabel: _conversion.heightLabel(_unit),
        valueLabel: _formatHeight(_cm.toDouble()),
        minLabel: _rangeLabel(_minCm.toDouble()),
        maxLabel: _rangeLabel(_maxCm.toDouble()),
        hint: 'Drag to adjust',
        onChanged: _handleChanged,
      ),
    );
  }
}
