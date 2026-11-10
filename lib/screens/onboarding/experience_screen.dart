import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/experience_display.dart';
import '../../models/experience_level.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_choice_card.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 7: training experience. One level is required.
class ExperienceScreen extends StatefulWidget {
  const ExperienceScreen({super.key, this.onRoute});

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  @override
  State<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  static const List<
    ({ExperienceLevel level, String assetIcon, String description})
  >
  _options = <({ExperienceLevel level, String assetIcon, String description})>[
    (
      level: ExperienceLevel.beginner,
      assetIcon: AppIcons.seedling,
      description: 'New to training or returning after a break.',
    ),
    (
      level: ExperienceLevel.regular,
      assetIcon: AppIcons.dumbbell,
      description: 'Training consistently for under a year.',
    ),
    (
      level: ExperienceLevel.gymRat,
      assetIcon: AppIcons.flame,
      description: 'Years of structured training.',
    ),
    (
      level: ExperienceLevel.veteran,
      assetIcon: AppIcons.trophy,
      description: 'Advanced, competition-minded.',
    ),
  ];

  ExperienceLevel? _selected;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _selected = context.read<OnboardingProvider>().draft.experienceLevel;
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
    final selected = _selected;
    if (_isBusy || selected == null) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();

    await onboarding.setExperienceLevel(selected);
    final next = OnboardingFlow.nextRoute(Routes.onboardingExperience)!;
    onboarding.syncStep(OnboardingFlow.stepFor(next));
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(context, next);
  }

  void _back(BuildContext context) {
    final previous = OnboardingFlow.previousRoute(Routes.onboardingExperience)!;
    context.read<OnboardingProvider>().syncStep(
      OnboardingFlow.stepFor(previous),
    );
    _open(context, previous);
  }

  Widget _buildOptions() {
    return Column(
      children: <Widget>[
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppChoiceCard(
              label: experienceLevelLabel(option.level),
              description: option.description,
              assetIcon: option.assetIcon,
              labelStyle: AppOnboardingType.choiceTitle,
              descriptionStyle: AppOnboardingType.choiceDesc,
              iconSize: 22,
              iconBoxSize: 40,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x2l,
                vertical: AppSpacing.x2l,
              ),
              selected: _selected == option.level,
              onTap: () => setState(() => _selected = option.level),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'How much experience?',
      subtitle: 'Sets starting volume and exercise selection.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingExperience),
      onBack: () => _back(context),
      onContinue: _selected == null ? null : _continue,
      continueEnabled: _selected != null,
      isBusy: _isBusy,
      child: _buildOptions(),
    );
  }
}
