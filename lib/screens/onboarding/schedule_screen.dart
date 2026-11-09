import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/day_selector.dart';
import '../../widgets/stepper_row.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 8: weekly schedule. The number of training days must match
/// the selected weekdays.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.onRoute});

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const List<int> _defaultDays = <int>[1, 3, 5];
  static const List<int> _fillOrder = <int>[1, 3, 5, 2, 4, 6, 7];

  late int _daysPerWeek;
  late List<int> _days;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<OnboardingProvider>().draft;
    final storedCount = draft.daysPerWeek;
    _daysPerWeek =
        storedCount != null &&
            storedCount >= kMinTrainingDays &&
            storedCount <= kMaxTrainingDays
        ? storedCount
        : 3;
    final storedDays =
        draft.trainingDays.where((day) => day >= 1 && day <= 7).toSet().toList()
          ..sort();
    _days = _resize(
      storedDays.isEmpty ? _defaultDays : storedDays,
      _daysPerWeek,
    );
  }

  List<int> _resize(List<int> current, int count) {
    final next = current.take(count).toList();
    for (final day in _fillOrder) {
      if (next.length >= count) {
        break;
      }
      if (!next.contains(day)) {
        next.add(day);
      }
    }
    next.sort();
    return next;
  }

  void _setDaysPerWeek(int value) {
    setState(() {
      _daysPerWeek = value;
      _days = _resize(_days, value);
    });
  }

  void _setDays(List<int> next) {
    if (next.length > _daysPerWeek) {
      return;
    }
    setState(() => _days = next);
  }

  void _open(BuildContext context, String route) {
    final handler = widget.onRoute;
    if (handler != null) {
      handler(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  bool get _canContinue => _days.isNotEmpty && _days.length == _daysPerWeek;

  Future<void> _continue() async {
    if (_isBusy || !_canContinue) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();
    final editingPlan = onboarding.editingPlan;

    await onboarding.setSchedule(
      daysPerWeek: _daysPerWeek,
      trainingDays: _days,
    );
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

  String get _helper {
    if (_days.length == _daysPerWeek) {
      return 'Default is 3 days on Monday, Wednesday, and Friday. '
          'The day count must match the selected weekdays.';
    }
    final remaining = _daysPerWeek - _days.length;
    return remaining == 1
        ? 'Select 1 more day to continue.'
        : 'Select $remaining more days to continue.';
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
          onChanged: _setDaysPerWeek,
        ),
        const SizedBox(height: AppSpacing.x2l),
        DaySelector(
          selectedDays: _days,
          textStyle: AppOnboardingType.micro,
          onChanged: _setDays,
        ),
        const SizedBox(height: AppSpacing.x2l),
        AppCard(
          child: Text(
            _helper,
            style: AppOnboardingType.caption.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'How often do you train?',
      subtitle: 'Your plan is built around this week.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingSchedule),
      onBack: () => _back(context),
      onContinue: _canContinue ? _continue : null,
      continueEnabled: _canContinue,
      isBusy: _isBusy,
      child: _buildScheduleCard(),
    );
  }
}
