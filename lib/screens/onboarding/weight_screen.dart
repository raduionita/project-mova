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
import '../../widgets/app_ruler_slider.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 4: body weight. The value is shown in the chosen weight
/// unit and stored in kilograms. Skip stores zero.
class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key, this.onRoute});

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  static const double _minKg = 30;
  static const double _maxKg = 250;
  static const double _defaultKg = 78;

  final UnitConversionService _conversion = const UnitConversionService();

  late final WeightUnit _unit;
  late double _kg;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<OnboardingProvider>().draft;
    _unit = draft.unitPreferences.weightUnit;
    final saved = draft.bodyWeightKg;
    _kg = saved > 0 ? saved.clamp(_minKg, _maxKg).toDouble() : _defaultKg;
  }

  double get _displayStep => _conversion.weightIncrement(_unit);

  double get _displayMin {
    final raw = _unit == WeightUnit.kg ? _minKg : _conversion.kgToLb(_minKg);
    return (raw / _displayStep).round() * _displayStep;
  }

  double get _displayMax {
    final raw = _unit == WeightUnit.kg ? _maxKg : _conversion.kgToLb(_maxKg);
    return (raw / _displayStep).round() * _displayStep;
  }

  /// The stored kilograms snapped to the display step so the ruler and the
  /// stored value agree.
  double get _displayValue {
    final raw = _unit == WeightUnit.kg ? _kg : _conversion.kgToLb(_kg);
    return (raw / _displayStep).round() * _displayStep;
  }

  void _open(BuildContext context, String route) {
    final handler = widget.onRoute;
    if (handler != null) {
      handler(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  void _handleChanged(double displayValue) {
    final kg = _unit == WeightUnit.kg
        ? displayValue
        : _conversion.lbToKg(displayValue);
    setState(() {
      _kg = _conversion.roundInputKg(kg.clamp(_minKg, _maxKg).toDouble());
    });
  }

  Future<void> _continue({bool skip = false}) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();

    await onboarding.setBodyWeightKg(skip ? 0 : _kg);
    final advanced = await onboarding.next();
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(
      context,
      advanced
          ? OnboardingFlow.nextRoute(Routes.onboardingWeight)!
          : Routes.onboardingWeight,
    );
  }

  void _back(BuildContext context) {
    _open(context, OnboardingFlow.previousRoute(Routes.onboardingWeight)!);
  }

  String _formatDisplay(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  Widget _buildRangeRow() {
    final label = _conversion.weightLabel(_unit);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            '${_formatDisplay(_displayMin)} $label',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          Text(
            '${_formatDisplay(_displayMax)} $label',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Your weight',
      subtitle: 'Used for strength score and body-weight exercises.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingWeight),
      onBack: () => _back(context),
      onContinue: _isBusy ? null : () => _continue(),
      isBusy: _isBusy,
      onSkip: _isBusy ? null : () => _continue(skip: true),
      skipLabel: 'Skip for now',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppRulerSlider(
            value: _displayValue,
            min: _displayMin,
            max: _displayMax,
            step: _displayStep,
            unitLabel: _conversion.weightLabel(_unit),
            onChanged: _handleChanged,
          ),
          _buildRangeRow(),
        ],
      ),
    );
  }
}
