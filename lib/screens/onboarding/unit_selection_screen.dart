import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/unit_preferences.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_segmented_control.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 1: weight, distance, and body size units.
class UnitSelectionScreen extends StatefulWidget {
  const UnitSelectionScreen({super.key, this.onRoute});

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen> {
  late UnitPreferences _units;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _units = context.read<OnboardingProvider>().draft.unitPreferences;
  }

  void _open(BuildContext context, String route) {
    final handler = widget.onRoute;
    if (handler != null) {
      handler(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _continue() async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();
    final settings = context.read<SettingsProvider>();

    await onboarding.setUnits(_units);
    await settings.setUnitPreferences(_units);
    final advanced = await onboarding.next();
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(
      context,
      advanced
          ? OnboardingFlow.nextRoute(Routes.onboardingUnits)!
          : Routes.onboardingUnits,
    );
  }

  void _back(BuildContext context) {
    _open(context, OnboardingFlow.previousRoute(Routes.onboardingUnits)!);
  }

  Widget _buildUnitRow(String label, Widget control) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x3l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.md),
          control,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Choose your units',
      subtitle: 'You can change these later in Settings.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingUnits),
      onBack: () => _back(context),
      onContinue: _continue,
      isBusy: _isBusy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildUnitRow(
            'Weight',
            AppSegmentedControl<WeightUnit>(
              options: const <AppSegmentOption<WeightUnit>>[
                AppSegmentOption<WeightUnit>(value: WeightUnit.kg, label: 'kg'),
                AppSegmentOption<WeightUnit>(value: WeightUnit.lb, label: 'lb'),
              ],
              selected: _units.weightUnit,
              onChanged: (unit) =>
                  setState(() => _units = _units.copyWith(weightUnit: unit)),
            ),
          ),
          _buildUnitRow(
            'Distance',
            AppSegmentedControl<DistanceUnit>(
              options: const <AppSegmentOption<DistanceUnit>>[
                AppSegmentOption<DistanceUnit>(
                  value: DistanceUnit.km,
                  label: 'km',
                ),
                AppSegmentOption<DistanceUnit>(
                  value: DistanceUnit.mi,
                  label: 'mi',
                ),
              ],
              selected: _units.distanceUnit,
              onChanged: (unit) =>
                  setState(() => _units = _units.copyWith(distanceUnit: unit)),
            ),
          ),
          _buildUnitRow(
            'Body size',
            AppSegmentedControl<HeightUnit>(
              options: const <AppSegmentOption<HeightUnit>>[
                AppSegmentOption<HeightUnit>(value: HeightUnit.cm, label: 'cm'),
                AppSegmentOption<HeightUnit>(
                  value: HeightUnit.inches,
                  label: 'in',
                ),
              ],
              selected: _units.heightUnit,
              onChanged: (unit) =>
                  setState(() => _units = _units.copyWith(heightUnit: unit)),
            ),
          ),
        ],
      ),
    );
  }
}
