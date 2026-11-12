import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/formatters.dart';
import '../../common/week_start_context.dart';
import '../../models/app_settings.dart';
import '../../models/plan_day.dart';
import '../../models/step_entry.dart';
import '../../models/training_plan.dart';
import '../../models/workout_session.dart';
import '../../navigation/routes.dart';
import '../../providers/history_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/steps_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/clock.dart';
import '../../services/session_suggestion_service.dart';
import '../../services/unit_conversion_service.dart';
import '../../services/week_streak_service.dart';
import '../../services/workout_calculator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/choose_session_sheet.dart';
import '../../widgets/edit_workout_sheet.dart';
import '../../widgets/manual_steps_sheet.dart';
import '../../widgets/streak_badge_row.dart';

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
    final hasActive = context.watch<WorkoutProvider>().activeSession != null;
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
                child: const AppIcon(
                  asset: AppIcons.walk,
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
          Row(
            children: <Widget>[
              Expanded(
                child: TextButton.icon(
                  key: const Key('today-start-walk'),
                  onPressed: hasActive ? null : _startWalk,
                  icon: const AppIcon(
                    asset: AppIcons.walk,
                    size: 18,
                    color: AppColors.lime,
                  ),
                  label: const Text('Start walk'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: AppColors.lime,
                    disabledForegroundColor: AppColors.muted,
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  key: const Key('today-add-steps'),
                  onPressed: _addSteps,
                  icon: const AppIcon(
                    asset: AppIcons.edit,
                    size: 18,
                    color: AppColors.lime,
                  ),
                  label: Text(hasSteps ? 'Edit steps' : 'Add steps'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: AppColors.lime,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<WorkoutSession> _completedToday(
    DateTime now,
    HistoryProvider? history,
  ) {
    if (history == null) {
      return const <WorkoutSession>[];
    }
    return history.workouts
        .where((session) {
          if (session.status != SessionStatus.completed) {
            return false;
          }
          final at = session.completedAt ?? session.startedAt;
          return _isSameDay(at, now);
        })
        .toList(growable: false);
  }

  WorkoutSession? _completedRun(
    DateTime now,
    HistoryProvider? history,
  ) {
    for (final session in _completedToday(now, history)) {
      if (session.source == SessionSource.run) {
        return session;
      }
    }
    return null;
  }

  Future<void> _editWorkout(WorkoutSession session) async {
    final saved = await showEditWorkoutSheet(context, session: session);
    if (!mounted || saved != true) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Workout updated.')));
  }

  String _sessionSummary(WorkoutSession session) {
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    final distanceUnit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .distanceUnit;
    final seconds = WorkoutCalculator.sessionDurationSeconds(session, _now);
    final parts = <String>[formatDuration(seconds)];
    if (session.source == SessionSource.run ||
        session.source == SessionSource.walk) {
      final meters = session.distanceMeters;
      if (meters != null && meters > 0) {
        parts.add(
          const UnitConversionService().displayDistance(
            meters / 1000,
            distanceUnit,
          ),
        );
      }
      return parts.join(' · ');
    }
    final volume = WorkoutCalculator.volumeKg(session.exercises);
    if (volume > 0) {
      parts.add(formatVolume(volume, unit: unit));
    }
    return parts.join(' · ');
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

  Future<void> _chooseAnotherSession({SessionSuggestion? suggestion}) {
    return showChooseSessionSheet(
      context,
      plan: context.read<PlanProvider>().plan,
      routines: context.read<RoutineProvider>().routines,
      nextIndex: suggestion?.dayIndex,
      onStartPlanDay: _startFromPlan,
      onStartRoutine: (routine) =>
          _runStart((workout) => workout.startFromRoutine(routine)),
      onStartEmpty: () => _runStart((workout) => workout.startEmpty()),
      onStartWalk: () => _runStart((workout) => workout.startWalk()),
    );
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
      Navigator.of(
        context,
      ).pushNamed(session.source == SessionSource.run ? Routes.run : Routes.logger);
    }
  }

  Widget _buildRunningCard(WorkoutSession? run) {
    final active = context.watch<WorkoutProvider>().activeSession;
    final canStart = active == null;
    final runActive =
        active != null && active.source == SessionSource.run;
    final distance = run?.distanceMeters;
    final distanceLabel = distance == null || distance <= 0
        ? null
        : const UnitConversionService().displayDistance(
            distance / 1000,
            context
                .watch<SettingsProvider>()
                .settings
                .unitPreferences
                .distanceUnit,
          );
    return AppCard(
      key: const Key('today-running-card'),
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
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.xl),
                ),
                child: const AppIcon(
                  asset: AppIcons.run,
                  size: 20,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      run == null ? 'Running' : 'Ran today',
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      run == null
                          ? 'Track time and distance. No GPS needed.'
                          : _sessionSummary(run),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (distanceLabel != null)
                AppTag(label: distanceLabel, variant: AppTagVariant.neutral),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  key: const Key('today-start-run'),
                  label: runActive
                      ? 'Continue run'
                      : run == null
                      ? 'Start run'
                      : 'Run again',
                  assetIcon: runActive ? AppIcons.play : AppIcons.run,
                  onPressed: runActive
                      ? () => Navigator.of(context).pushNamed(Routes.run)
                      : canStart
                      ? () {
                          Navigator.of(context).pushNamed(Routes.run);
                        }
                      : null,
                ),
              ),
              if (run != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    key: const Key('today-edit-run'),
                    label: 'Edit run',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => _editWorkout(run),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(int dayStreak, int weekStreak) {
    return StreakBadgeRow(dayStreak: dayStreak, weekStreak: weekStreak);
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
            assetIcon: AppIcons.play,
            onPressed: _resumeSession,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({String? label}) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Edit plan',
                onPressed: () => Navigator.of(context).pushNamed(Routes.plan),
                icon: const AppIcon(
                  asset: AppIcons.calendar,
                  size: 20,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              IconButton(
                key: const Key('today-reminders'),
                tooltip: 'Workout reminders',
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.meSettings),
                icon: const AppIcon(
                  asset: AppIcons.bell,
                  size: 20,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          Center(
            child: AppTag(label: label ?? _weekdayNames[_now.weekday - 1]),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakTag(int streak) {
    return AppTag(
      key: const Key('today-streak'),
      label: '$streak day streak',
      variant: AppTagVariant.gold,
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
          const AppIcon(
            asset: AppIcons.alert,
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
            icon: const AppIcon(asset: AppIcons.close, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildNextUpCard(SessionSuggestion suggestion, {int streak = 0}) {
    final day = suggestion.day;
    return AppCard(
      key: const Key('today-next-up'),
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
              if (streak > 0) ...<Widget>[
                _buildStreakTag(streak),
                const SizedBox(width: AppSpacing.sm),
              ],
              const AppTag(label: 'Next up', variant: AppTagVariant.lime),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            suggestion.reason,
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          if (suggestion.recoveryWarning != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              suggestion.recoveryWarning!,
              style: AppTypography.caption.copyWith(color: AppColors.gold),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            day.muscleGroups.join(' · '),
            style: AppTypography.body.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${day.exercises.length} exercises · ~${day.estimatedMinutes} min',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            key: const Key('today-start-workout'),
            label: 'Start workout',
            assetIcon: AppIcons.play,
            onPressed: () => _startFromPlan(day),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const Key('today-choose-session'),
            label: 'Choose another session',
            variant: AppButtonVariant.ghost,
            onPressed: () => _chooseAnotherSession(suggestion: suggestion),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedRow(WorkoutSession session) {
    final title = session.displayTitle.trim().isEmpty
        ? session.name
        : session.displayTitle;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        key: Key('today-completed-row-${session.id}'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: <Widget>[
            const AppIcon(
              asset: AppIcons.check,
              size: 18,
              color: AppColors.lime,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${session.sourceLabel} · ${_sessionSummary(session)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: Key('today-edit-workout-${session.id}'),
              onPressed: () => _editWorkout(session),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: AppColors.lime,
              ),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(
    List<WorkoutSession> sessions,
    SessionSuggestion? suggestion, {
    int streak = 0,
  }) {
    return AppCard(
      key: const Key('today-completed'),
      featured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Trained today',
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (streak > 0) ...<Widget>[
                _buildStreakTag(streak),
                const SizedBox(width: AppSpacing.sm),
              ],
              const AppTag(label: 'Done', variant: AppTagVariant.gold),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            sessions.length == 1
                ? 'Your session is in the books. Nice work.'
                : '${sessions.length} sessions logged today. Nice work.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final session in sessions) _buildCompletedRow(session),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            key: const Key('today-train-again'),
            label: 'Train again',
            assetIcon: AppIcons.play,
            onPressed: suggestion == null
                ? _startEmpty
                : () => _startFromPlan(suggestion.day),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const Key('today-choose-session'),
            label: 'Choose another session',
            variant: AppButtonVariant.ghost,
            onPressed: () => _chooseAnotherSession(suggestion: suggestion),
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
            assetIcon: AppIcons.calendar,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: plan.isFallback ? 'Starter' : 'Custom',
            label: 'plan',
            assetIcon: AppIcons.plan,
          ),
        ),
      ],
    );
  }

  Widget _buildActive(
    TrainingPlan plan,
    WorkoutSession session, {
    required int dayStreak,
    required int weekStreak,
    WorkoutSession? run,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSessionCard(session),
        const SizedBox(height: AppSpacing.x2l),
        _buildStepsCard(),
        const SizedBox(height: AppSpacing.x2l),
        _buildRunningCard(run),
        const SizedBox(height: AppSpacing.x2l),
        _buildBadges(dayStreak, weekStreak),
        const SizedBox(height: AppSpacing.x2l),
        _buildStats(plan),
      ],
    );
  }

  Widget _buildNextUp(
    TrainingPlan plan,
    SessionSuggestion suggestion, {
    required int dayStreak,
    required int weekStreak,
    WorkoutSession? run,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildNextUpCard(suggestion, streak: dayStreak),
        const SizedBox(height: AppSpacing.x2l),
        _buildStepsCard(),
        const SizedBox(height: AppSpacing.x2l),
        _buildRunningCard(run),
        const SizedBox(height: AppSpacing.x2l),
        _buildBadges(dayStreak, weekStreak),
        const SizedBox(height: AppSpacing.x2l),
        _buildStats(plan),
      ],
    );
  }

  Widget _buildCompletedToday(
    TrainingPlan plan,
    List<WorkoutSession> sessions,
    SessionSuggestion? suggestion, {
    required int dayStreak,
    required int weekStreak,
    WorkoutSession? run,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildCompletedCard(
          sessions,
          suggestion,
          streak: dayStreak,
        ),
        const SizedBox(height: AppSpacing.x2l),
        _buildStepsCard(),
        const SizedBox(height: AppSpacing.x2l),
        _buildRunningCard(run),
        const SizedBox(height: AppSpacing.x2l),
        _buildBadges(dayStreak, weekStreak),
        const SizedBox(height: AppSpacing.x2l),
        _buildStats(plan),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanProvider>();
    final workout = context.watch<WorkoutProvider>();
    final history = context.watch<HistoryProvider?>();
    final plan = planProvider.plan;
    final session = workout.activeSession;
    final now = _now;
    final storageWarning = context.watch<SettingsProvider>().storageWarning;
    final warning = _warningDismissed ? null : storageWarning;
    final streak = context.watch<ProgressProvider?>()?.streak ?? 0;
    final completed = _completedToday(now, history);
    final run = _completedRun(now, history);
    final weekStart = effectiveWeekStart(context);
    final target = (plan?.daysPerWeek ?? 3).clamp(1, 7);
    final weekStreak = const WeekStreakService().currentWeekStreak(
      history?.workouts ?? const <WorkoutSession>[],
      now,
      weekStart: weekStart,
      target: target,
    );
    final suggestion = plan == null
        ? null
        : const SessionSuggestionService().suggest(
            plan: plan,
            history: history?.workouts ?? const <WorkoutSession>[],
            now: now,
          );

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
                const SizedBox(height: AppSpacing.x2l),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (session != null) ...<Widget>[
                          _buildSessionCard(session),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildStepsCard(),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildRunningCard(run),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildBadges(streak, weekStreak),
                        ] else if (completed.isNotEmpty) ...<Widget>[
                          _buildCompletedCard(
                            completed,
                            null,
                            streak: streak,
                          ),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildStepsCard(),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildRunningCard(run),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildBadges(streak, weekStreak),
                        ] else ...<Widget>[
                          AppCard(
                            key: const Key('today-no-plan'),
                            featured: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    const AppIcon(
                                      asset: AppIcons.dumbbell,
                                      size: 22,
                                      color: AppColors.lime,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        'Track your training',
                                        style: AppTypography.h2.copyWith(
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No rotation needed. Start with any focus, '
                                  'saved workout, or activity.',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppButton(
                                  key: const Key('today-start-workout'),
                                  label: 'Start workout',
                                  assetIcon: AppIcons.play,
                                  onPressed: _startEmpty,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppButton(
                                  key: const Key('today-choose-session'),
                                  label: 'Choose saved workout',
                                  variant: AppButtonVariant.ghost,
                                  onPressed: _chooseAnotherSession,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildStepsCard(),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildRunningCard(run),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildBadges(streak, weekStreak),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              _buildHeader(label: _weekdayNames[now.weekday - 1]),
              if (warning != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                _buildWarningBanner(warning),
              ],
              const SizedBox(height: AppSpacing.x3l),
              Expanded(
                child: SingleChildScrollView(
                  child: session != null
                      ? _buildActive(
                          plan,
                          session,
                          dayStreak: streak,
                          weekStreak: weekStreak,
                          run: run,
                        )
                      : completed.isNotEmpty
                      ? _buildCompletedToday(
                          plan,
                          completed,
                          suggestion,
                          dayStreak: streak,
                          weekStreak: weekStreak,
                          run: run,
                        )
                      : suggestion == null
                      ? _buildNextUp(
                          plan,
                          SessionSuggestion(
                            day: plan.days.first,
                            dayIndex: 0,
                            reason: 'Start your rotation.',
                          ),
                          dayStreak: streak,
                          weekStreak: weekStreak,
                          run: run,
                        )
                      : _buildNextUp(
                          plan,
                          suggestion,
                          dayStreak: streak,
                          weekStreak: weekStreak,
                          run: run,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
