import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/formatters.dart';
import '../../models/app_settings.dart';
import '../../models/plan_day.dart';
import '../../models/step_entry.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';
import '../../navigation/routes.dart';
import '../../providers/plan_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/steps_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/clock.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/manual_steps_sheet.dart';
import '../../widgets/plan_overview_sheet.dart';

const List<String> _weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Today screen with planned, rest, and no-plan states plus workout actions.
/// Today overview with the next session, daily steps, and reminders.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.clock});

  final Clock? clock;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  DateTime get _now => (widget.clock ?? const SystemClock()).now();

  Timer? _dayTimer;
  bool _warningDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleDayRollover();
      _loadSteps();
    });
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
      _scheduleDayRollover();
      _loadSteps();
    }
  }

  void _scheduleDayRollover() {
    if (!mounted) {
      return;
    }
    _dayTimer?.cancel();
    final now = _now;
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);
    _dayTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted) {
        return;
      }
      setState(() {});
      _scheduleDayRollover();
    });
  }

  Future<void> _loadSteps() async {
    if (!mounted) {
      return;
    }
    final steps = context.read<StepsProvider>();
    await steps.load();
    if (!mounted) {
      return;
    }
    final health = context.read<SettingsProvider>().settings.healthProvider;
    final connected =
        health == HealthProvider.appleHealth ||
        health == HealthProvider.healthConnect;
    if (connected) {
      await steps.syncHealth(enabled: true);
    }
  }

  Future<void> _addSteps() async {
    await ManualStepsSheet.show(context);
  }

  Widget _buildStepsCard() {
    final provider = context.watch<StepsProvider>();
    final entry = provider.todayEntry;
    final hasSteps = entry != null && entry.steps > 0;
    final isHealth = entry?.source == StepSource.health;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.limeSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.xl),
                ),
                child: const Icon(
                  Icons.directions_walk,
                  size: 20,
                  color: AppColors.lime,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Steps today',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      hasSteps ? formatSteps(entry.steps) : 'No steps yet',
                      style:
                          (hasSteps
                                  ? AppTypography.metric
                                  : AppTypography.bodyStrong)
                              .copyWith(color: AppColors.text),
                    ),
                  ],
                ),
              ),
              if (entry != null && hasSteps)
                AppTag(
                  label: isHealth ? 'Health' : 'Manual',
                  variant: isHealth
                      ? AppTagVariant.lime
                      : AppTagVariant.neutral,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('today-add-steps'),
              onPressed: _addSteps,
              icon: const Icon(Icons.add, size: 18),
              label: Text(hasSteps ? 'Update steps' : 'Add steps'),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: AppColors.lime,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PlanDay? _dayFor(TrainingPlan plan, DateTime now) {
    for (final day in plan.days) {
      if (day.weekday == now.weekday) {
        return day;
      }
    }
    return null;
  }

  String _weekLabel(TrainingPlan plan, DateTime now) {
    final generated = DateTime(
      plan.generatedAt.year,
      plan.generatedAt.month,
      plan.generatedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final elapsed = today.difference(generated).inDays;
    final week = elapsed < 0 ? 1 : elapsed ~/ 7 + 1;
    return '${_weekdayNames[now.weekday - 1]} · Week $week';
  }

  Future<void> _startFromPlan(PlanDay day) async {
    final workout = context.read<WorkoutProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final started = await workout.startFromPlanDay(day);
    if (!mounted) {
      return;
    }
    if (!started) {
      messenger.showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not start workout.')),
      );
      return;
    }
    Navigator.of(context).pushNamed(Routes.logger);
  }

  Future<void> _startEmpty() {
    return _runStart((workout) => workout.startEmpty());
  }

  Future<void> _startWalk() {
    return _runStart((workout) => workout.startWalk());
  }

  Future<void> _runStart(Future<bool> Function(WorkoutProvider) start) async {
    final workout = context.read<WorkoutProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final started = await start(workout);
    if (!mounted) {
      return;
    }
    if (!started) {
      messenger.showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not start workout.')),
      );
      return;
    }
    Navigator.of(context).pushNamed(Routes.logger);
  }

  Future<void> _resumeSession() async {
    final workout = context.read<WorkoutProvider>();
    final session = workout.activeSession;
    if (session == null) {
      return;
    }
    if (session.status == SessionStatus.paused) {
      final messenger = ScaffoldMessenger.of(context);
      final resumed = await workout.resume();
      if (!mounted) {
        return;
      }
      if (!resumed) {
        messenger.showSnackBar(
          SnackBar(content: Text(workout.error ?? 'Could not resume workout.')),
        );
        return;
      }
    }
    if (mounted) {
      Navigator.of(context).pushNamed(Routes.logger);
    }
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        AppButton(
          label: 'Empty workout',
          icon: Icons.add,
          variant: AppButtonVariant.ghost,
          fullWidth: false,
          onPressed: _startEmpty,
        ),
        AppButton(
          label: 'Walk',
          icon: Icons.directions_walk,
          variant: AppButtonVariant.ghost,
          fullWidth: false,
          onPressed: _startWalk,
        ),
        AppButton(
          label: 'Routine',
          icon: Icons.format_list_bulleted,
          variant: AppButtonVariant.ghost,
          fullWidth: false,
          onPressed: () => Navigator.of(context).pushNamed(Routes.routines),
        ),
      ],
    );
  }

  Widget _buildSessionCard(WorkoutSession session) {
    final paused = session.status == SessionStatus.paused;
    return AppCard(
      featured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  session.name,
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              AppTag(
                label: paused ? 'Paused' : 'In progress',
                variant: paused ? AppTagVariant.gold : AppTagVariant.lime,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            paused
                ? 'Resume where you left off.'
                : 'Your workout is still running.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: paused ? 'Resume workout' : 'Continue workout',
            icon: Icons.play_arrow,
            onPressed: _resumeSession,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({String? label}) {
    return Row(
      children: <Widget>[
        AppTag(label: label ?? _weekdayNames[_now.weekday - 1]),
        const Spacer(),
        IconButton(
          key: const Key('today-reminders'),
          tooltip: 'Workout reminders',
          onPressed: () => Navigator.of(context).pushNamed(Routes.meSettings),
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.muted,
          ),
        ),
        IconButton(
          tooltip: 'Edit plan',
          onPressed: () => PlanOverviewSheet.show(context),
          icon: const Icon(
            Icons.edit_calendar_outlined,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner(String warning) {
    return Container(
      key: const Key('today-storage-warning'),
      padding: const EdgeInsets.only(
        left: AppSpacing.xl,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.orangeBorder50),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.orange,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              warning,
              style: AppTypography.caption.copyWith(color: AppColors.text),
            ),
          ),
          IconButton(
            key: const Key('today-storage-warning-dismiss'),
            tooltip: 'Dismiss warning',
            onPressed: () => setState(() => _warningDismissed = true),
            icon: const Icon(Icons.close, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(PlanDay day, {required bool canStart}) {
    return AppCard(
      featured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  day.name,
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const AppTag(label: 'Planned', variant: AppTagVariant.lime),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            day.muscleGroups.join(' · '),
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${day.exercises.length} exercises · ~${day.estimatedMinutes} min',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          if (canStart) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Start workout',
              icon: Icons.play_arrow,
              onPressed: () => _startFromPlan(day),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestCard() {
    return AppCard(
      featured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Rest day',
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const AppTag(label: 'Recovery', variant: AppTagVariant.gold),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Recover and come back stronger.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(TrainingPlan plan) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppStatTile(
            value: '${plan.days.length}',
            label: 'training days',
            icon: Icons.calendar_month_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: plan.isFallback ? 'Starter' : 'Custom',
            label: 'plan',
            icon: Icons.auto_awesome_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanned(
    PlanDay day,
    TrainingPlan plan,
    WorkoutSession? session,
  ) {
    final canStart = session == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (session != null) ...<Widget>[
          _buildSessionCard(session),
          const SizedBox(height: AppSpacing.x2l),
        ],
        _buildWorkoutCard(day, canStart: canStart),
        const SizedBox(height: AppSpacing.x2l),
        _buildStepsCard(),
        if (canStart) ...<Widget>[
          const SizedBox(height: AppSpacing.x2l),
          _buildQuickActions(),
        ],
        const SizedBox(height: AppSpacing.x2l),
        _buildStats(plan),
      ],
    );
  }

  Widget _buildRest(TrainingPlan plan, WorkoutSession? session) {
    final canStart = session == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (session != null) ...<Widget>[
          _buildSessionCard(session),
          const SizedBox(height: AppSpacing.x2l),
        ],
        _buildRestCard(),
        const SizedBox(height: AppSpacing.x2l),
        _buildStepsCard(),
        if (canStart) ...<Widget>[
          const SizedBox(height: AppSpacing.x2l),
          _buildQuickActions(),
        ],
        const SizedBox(height: AppSpacing.x2l),
        _buildStats(plan),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanProvider>();
    final workout = context.watch<WorkoutProvider>();
    final plan = planProvider.plan;
    final session = workout.activeSession;
    final now = _now;
    final storageWarning = context.watch<SettingsProvider>().storageWarning;
    final warning = _warningDismissed ? null : storageWarning;

    if (plan == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2l,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(),
                if (warning != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  _buildWarningBanner(warning),
                ],
                if (session != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.x2l),
                  _buildSessionCard(session),
                ],
                const SizedBox(height: AppSpacing.x2l),
                _buildStepsCard(),
                const Expanded(
                  child: AppEmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'No plan yet',
                    message:
                        'Finish onboarding to build your weekly training plan.',
                  ),
                ),
                if (session == null) _buildQuickActions(),
              ],
            ),
          ),
        ),
      );
    }

    final day = _dayFor(plan, now);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2l,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(label: _weekLabel(plan, now)),
              if (warning != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                _buildWarningBanner(warning),
              ],
              const SizedBox(height: AppSpacing.x3l),
              Expanded(
                child: SingleChildScrollView(
                  child: day == null
                      ? _buildRest(plan, session)
                      : _buildPlanned(day, plan, session),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
