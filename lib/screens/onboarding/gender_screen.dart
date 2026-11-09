import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gender.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_choice_card.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 2: gender selection. Selection is required.
class GenderScreen extends StatefulWidget {
  const GenderScreen({super.key, this.onRoute});

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  Gender? _gender;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _gender = context.read<OnboardingProvider>().draft.gender;
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
    final gender = _gender;
    if (gender == null || _isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();
    await onboarding.setGender(gender);
    final next = OnboardingFlow.nextRoute(Routes.onboardingGender)!;
    onboarding.syncStep(OnboardingFlow.stepFor(next));
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(context, next);
  }

  void _back(BuildContext context) {
    final previous = OnboardingFlow.previousRoute(Routes.onboardingGender)!;
    context.read<OnboardingProvider>().syncStep(
      OnboardingFlow.stepFor(previous),
    );
    _open(context, previous);
  }

  Widget _buildOption({
    required Gender gender,
    required String label,
    required String description,
    required String assetIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppChoiceCard(
        label: label,
        description: description,
        assetIcon: assetIcon,
        labelStyle: AppOnboardingType.choiceTitle,
        descriptionStyle: AppOnboardingType.choiceDesc,
        selected: _gender == gender,
        onTap: () => setState(() => _gender = gender),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'How do you identify?',
      subtitle: 'This helps us set reference values for your metrics.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingGender),
      onBack: () => _back(context),
      onContinue: _continue,
      continueEnabled: _gender != null,
      isBusy: _isBusy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildOption(
            gender: Gender.male,
            label: 'Male',
            description: 'Use male reference values.',
            assetIcon: AppIcons.male,
          ),
          _buildOption(
            gender: Gender.female,
            label: 'Female',
            description: 'Use female reference values.',
            assetIcon: AppIcons.female,
          ),
          _buildOption(
            gender: Gender.other,
            label: 'Other',
            description: 'Skip the reference adjustment.',
            assetIcon: AppIcons.other,
          ),
        ],
      ),
    );
  }
}
