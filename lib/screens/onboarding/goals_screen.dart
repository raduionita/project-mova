import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/goal.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_icons.dart';
import '../../widgets/app_tile_grid.dart';
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
  static const List<AppTileOption<Goal>> _options = <AppTileOption<Goal>>[
    AppTileOption<Goal>(
      value: Goal.buildMuscle,
      label: 'Build muscle',
      assetIcon: AppIcons.dumbbell,
    ),
    AppTileOption<Goal>(
      value: Goal.getStronger,
      label: 'Get stronger',
      assetIcon: AppIcons.trophy,
    ),
    AppTileOption<Goal>(
      value: Goal.loseWeight,
      label: 'Lose weight',
      assetIcon: AppIcons.flame,
    ),
    AppTileOption<Goal>(
      value: Goal.stayHealthy,
      label: 'Stay healthy',
      assetIcon: AppIcons.heart,
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
      child: AppTileGrid<Goal>(
        options: _options,
        selected: _goals,
        onChanged: (goals) => setState(() => _goals = goals),
      ),
    );
  }
}
