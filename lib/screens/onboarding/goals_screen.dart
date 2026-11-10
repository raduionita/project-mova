import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/goal_display.dart';
import '../../models/goal.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_multi_select.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 6: training goals. Selection order decides the primary
/// goal, and at least one goal is required.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, this.onRoute});

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  static final List<AppMultiSelectOption<Goal>> _options =
      <AppMultiSelectOption<Goal>>[
        for (final goal in Goal.values)
          AppMultiSelectOption<Goal>(
            value: goal,
            label: goalLabel(goal),
            description: goalDescription(goal),
            assetIcon: goalIcon(goal),
          ),
      ];

  late List<Goal> _goals;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _goals = List<Goal>.of(context.read<OnboardingProvider>().draft.goals);
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
    if (_isBusy || _goals.isEmpty) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();

    await onboarding.setGoals(_goals);
    final next = OnboardingFlow.nextRoute(Routes.onboardingGoals)!;
    onboarding.syncStep(OnboardingFlow.stepFor(next));
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(context, next);
  }

  void _back(BuildContext context) {
    final previous = OnboardingFlow.previousRoute(Routes.onboardingGoals)!;
    context.read<OnboardingProvider>().syncStep(
      OnboardingFlow.stepFor(previous),
    );
    _open(context, previous);
  }

  Widget _buildOptions() {
    return AppMultiSelect<Goal>(
      options: _options,
      selected: _goals,
      onChanged: (goals) => setState(() => _goals = goals),
      labelStyle: AppOnboardingType.choiceTitle,
      descriptionStyle: AppOnboardingType.choiceDesc,
      iconSize: 22,
      iconBoxSize: 40,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2l,
        vertical: AppSpacing.x2l,
      ),
      spacing: AppSpacing.xl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'What are you training for?',
      subtitle: 'Pick all that apply. The first is your primary goal.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingGoals),
      onBack: () => _back(context),
      onContinue: _goals.isEmpty ? null : _continue,
      continueEnabled: _goals.isNotEmpty,
      isBusy: _isBusy,
      child: _buildOptions(),
    );
  }
}
