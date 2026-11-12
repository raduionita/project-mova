import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_choice_card.dart';
import '../../widgets/stepper_row.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 8: average training frequency.
///
/// The plan is an ordered rotation, so this value is a weekly average rather
/// than a fixed set of weekdays.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.onRoute});

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late int _daysPerWeek;
  late bool _planEnabled;
  late bool _editingPlan;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final onboarding = context.read<OnboardingProvider>();
    final storedCount = onboarding.draft.daysPerWeek;
    _daysPerWeek =
        storedCount != null &&
            storedCount >= kMinTrainingDays &&
            storedCount <= kMaxTrainingDays
        ? storedCount
        : 3;
    _editingPlan = onboarding.editingPlan;
    _planEnabled = _editingPlan || onboarding.draft.planEnabled;
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
    final editingPlan = onboarding.editingPlan;

    await onboarding.setPlanEnabled(_planEnabled);
    await onboarding.setSchedule(daysPerWeek: _daysPerWeek);
    final next = editingPlan
        ? Routes.onboardingPlan
        : OnboardingFlow.nextRoute(Routes.onboardingSchedule)!;
    if (editingPlan) {
      onboarding.endPlanEdit();
    }
    onboarding.syncStep(OnboardingFlow.stepFor(next));
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(context, next);
  }

  void _back(BuildContext context) {
    final onboarding = context.read<OnboardingProvider>();
    onboarding.endPlanEdit();
    final previous = OnboardingFlow.previousRoute(Routes.onboardingSchedule)!;
    onboarding.syncStep(OnboardingFlow.stepFor(previous));
    _open(context, previous);
  }

  Widget _buildPlanChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppChoiceCard(
          key: const Key('onboarding-plan-choice'),
          label: 'Plan with Mova',
          description: 'Build a rotation and start the next session in one tap.',
          assetIcon: AppIcons.plan,
          selected: _planEnabled,
          onTap: () => setState(() => _planEnabled = true),
        ),
        const SizedBox(height: AppSpacing.md),
        AppChoiceCard(
          key: const Key('onboarding-track-choice'),
          label: 'Track on my own',
          description: 'Log any workout. Add a rotation later if you want one.',
          assetIcon: AppIcons.plus,
          selected: !_planEnabled,
          onTap: () => setState(() => _planEnabled = false),
        ),
        const SizedBox(height: AppSpacing.x2l),
      ],
    );
  }

  Widget _buildScheduleCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        StepperRow(
          label: 'Days / week',
          value: _daysPerWeek,
          min: kMinTrainingDays,
          max: kMaxTrainingDays,
          labelStyle: AppOnboardingType.caption,
          onChanged: (value) => setState(() => _daysPerWeek = value),
        ),
        const SizedBox(height: AppSpacing.x2l),
        AppCard(
          child: Text(
            'This is your average target, not fixed weekdays. Train on any '
            'day, and any day you do not log counts as rest. Mova rotates '
            'through your sessions so a missed day never breaks the plan.',
            style: AppOnboardingType.caption.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingCard() {
    return AppCard(
      child: Text(
        'You can start any workout from Today. Your history, steps, and '
        'streaks still count. A rotation is optional and can be created '
        'from the Plan screen whenever you want one.',
        style: AppOnboardingType.caption.copyWith(color: AppColors.muted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showChoice = !_editingPlan;
    return OnboardingScaffold(
      title: _planEnabled ? 'How often do you train?' : 'Track on your terms',
      subtitle: _planEnabled
          ? 'An average week, not a fixed schedule.'
          : 'No rotation needed to start.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingSchedule),
      onBack: () => _back(context),
      onContinue: _continue,
      continueEnabled: true,
      isBusy: _isBusy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showChoice) _buildPlanChoice(),
          if (_planEnabled) _buildScheduleCard() else _buildTrackingCard(),
        ],
      ),
    );
  }
}
