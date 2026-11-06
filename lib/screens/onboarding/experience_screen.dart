import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/experience_level.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
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
    ({ExperienceLevel level, IconData icon, String description})
  >
  _options = <({ExperienceLevel level, IconData icon, String description})>[
    (
      level: ExperienceLevel.beginner,
      icon: Icons.eco_outlined,
      description: 'New to training or returning after a break.',
    ),
    (
      level: ExperienceLevel.regular,
      icon: Icons.fitness_center,
      description: 'Training consistently for under a year.',
    ),
    (
      level: ExperienceLevel.gymRat,
      icon: Icons.local_fire_department,
      description: 'Years of structured training.',
    ),
    (
      level: ExperienceLevel.veteran,
      icon: Icons.emoji_events_outlined,
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
    final advanced = await onboarding.next();
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(
      context,
      advanced
          ? OnboardingFlow.nextRoute(Routes.onboardingExperience)!
          : Routes.onboardingExperience,
    );
  }

  void _back(BuildContext context) {
    _open(context, OnboardingFlow.previousRoute(Routes.onboardingExperience)!);
  }

  Widget _buildOptions() {
    return Column(
      children: <Widget>[
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppChoiceCard(
              label: _labelFor(option.level),
              description: option.description,
              icon: option.icon,
              selected: _selected == option.level,
              onTap: () => setState(() => _selected = option.level),
            ),
          ),
      ],
    );
  }

  String _labelFor(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.regular:
        return 'Regular';
      case ExperienceLevel.gymRat:
        return 'Gym rat';
      case ExperienceLevel.veteran:
        return 'Veteran';
    }
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
