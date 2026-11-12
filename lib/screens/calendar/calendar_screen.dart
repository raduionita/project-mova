import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/date_keys.dart';
import '../../common/formatters.dart';
import '../../common/week_start_context.dart';
import '../../models/plan_day.dart';
import '../../models/workout_session.dart';
import '../../navigation/routes.dart';
import '../../providers/history_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/clock.dart';
import '../../services/session_suggestion_service.dart';
import '../../services/suggestion_cadence.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/calendar_day_cell.dart';
import '../../widgets/calendar_day_sheet.dart';
import '../../widgets/edit_workout_sheet.dart';
import '../../widgets/choose_session_sheet.dart';
import '../../widgets/dashed_circle.dart';

/// Calendar tab. Shows completed workouts, today, and the next three
/// suggested rotation sessions in a month grid.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.clock});

  final Clock? clock;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;

  DateTime get _now => (widget.clock ?? const SystemClock()).now();

  @override
  void initState() {
    super.initState();
    final now = _now;
    _visibleMonth = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final history = context.read<HistoryProvider>();
    final plan = context.read<PlanProvider>();
    final routines = context.read<RoutineProvider>();
    await Future.wait<void>(<Future<void>>[
      if (history.workouts.isEmpty && !history.isLoading) history.load(),
      if (plan.plan == null && !plan.isLoading) plan.load(),
      if (routines.routines.isEmpty && !routines.isLoading) routines.load(),
    ]);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCurrentMonth(DateTime month) {
    final now = _now;
    return month.year == now.year && month.month == now.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
    });
  }

  Map<String, List<WorkoutSession>> _sessionsByDay(
    List<WorkoutSession> workouts,
  ) {
    final map = <String, List<WorkoutSession>>{};
    for (final session in workouts) {
      if (session.status != SessionStatus.completed) {
        continue;
      }
      final at = session.completedAt ?? session.startedAt;
      map.putIfAbsent(DateKeys.dayKey(at), () => <WorkoutSession>[]).add(
        session,
      );
    }
    for (final sessions in map.values) {
      sessions.sort((a, b) {
        final aAt = a.completedAt ?? a.startedAt;
        final bAt = b.completedAt ?? b.startedAt;
        return aAt.compareTo(bAt);
      });
    }
    return map;
  }

  SessionSuggestion? _suggestion(
    List<WorkoutSession> history,
  ) {
    return const SessionSuggestionService().suggest(
      plan: context.read<PlanProvider>().plan,
      history: history,
      now: _now,
    );
  }

  Map<String, SuggestedSessionDate> _suggestionsByDay(
    SessionSuggestion? suggestion,
  ) {
    final plan = context.read<PlanProvider>().plan;
    if (suggestion == null || plan == null) {
      return const <String, SuggestedSessionDate>{};
    }
    final dates = const SuggestionCadence().next(
      plan: plan,
      startIndex: suggestion.dayIndex,
      from: _now,
      count: 3,
    );
    return <String, SuggestedSessionDate>{
      for (final date in dates) DateKeys.dayKey(date.date): date,
    };
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

  Future<void> _chooseAnotherSession({int? nextIndex}) {
    return showChooseSessionSheet(
      context,
      plan: context.read<PlanProvider>().plan,
      routines: context.read<RoutineProvider>().routines,
      nextIndex: nextIndex,
      onStartPlanDay: _startFromPlan,
      onStartRoutine: (routine) =>
          _runStart((workout) => workout.startFromRoutine(routine)),
      onStartEmpty: () => _runStart((workout) => workout.startEmpty()),
      onStartWalk: () => _runStart((workout) => workout.startWalk()),
    );
  }

  Future<void> _editSession(WorkoutSession session) async {
    final saved = await showEditWorkoutSheet(context, session: session);
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout updated.')),
      );
    }
  }

  Future<void> _openDay(
    DateTime date,
    List<WorkoutSession> sessions,
    SuggestedSessionDate? suggestion,
  ) {
    return showCalendarDaySheet(
      context,
      date: date,
      sessions: sessions,
      isToday: _isSameDay(date, _now),
      suggestion: sessions.isEmpty ? suggestion : null,
      onOpenSession: (session) => Navigator.of(
        context,
      ).pushNamed(Routes.progressHistoryDetail(session.id)),
      onEditSession: _editSession,
      onStartWorkout: () =>
          _chooseAnotherSession(nextIndex: suggestion?.dayIndex),
      onStartSuggestion: _startFromPlan,
      onViewSuggestion: () => Navigator.of(context).pushNamed(Routes.plan),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Calendar',
            style: AppTypography.h1.copyWith(color: AppColors.text),
          ),
        ),
        IconButton(
          key: const Key('calendar-plan'),
          onPressed: () => Navigator.of(context).pushNamed(Routes.plan),
          tooltip: 'Plan',
          icon: const AppIcon(
            asset: AppIcons.plan,
            size: 20,
            color: AppColors.muted,
          ),
        ),
        IconButton(
          key: const Key('calendar-exercises'),
          onPressed: () => Navigator.of(context).pushNamed(Routes.exercises),
          tooltip: 'Exercises',
          icon: const AppIcon(
            asset: AppIcons.dumbbell,
            size: 20,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthBar() {
    return Row(
      children: <Widget>[
        IconButton(
          key: const Key('calendar-prev-month'),
          onPressed: () => _changeMonth(-1),
          tooltip: 'Previous month',
          icon: const AppIcon(
            asset: AppIcons.chevronLeft,
            size: 20,
            color: AppColors.muted,
          ),
        ),
        Expanded(
          child: Text(
            formatMonthYear(_visibleMonth),
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
        ),
        if (!_isCurrentMonth(_visibleMonth))
          TextButton(
            key: const Key('calendar-today'),
            onPressed: () {
              final now = _now;
              setState(() => _visibleMonth = DateTime(now.year, now.month));
            },
            child: Text(
              'Today',
              style: AppTypography.label.copyWith(color: AppColors.lime),
            ),
          ),
        IconButton(
          key: const Key('calendar-next-month'),
          onPressed: () => _changeMonth(1),
          tooltip: 'Next month',
          icon: const AppIcon(
            asset: AppIcons.chevronRight,
            size: 20,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayRow(int weekStart) {
    final localizations = MaterialLocalizations.of(context);
    final names = localizations.narrowWeekdays;
    return Row(
      key: const Key('calendar-weekdays'),
      children: <Widget>[
        for (final weekday in DateKeys.weekdayOrder(weekStart))
          Expanded(
            child: Center(
              child: Text(
                names[weekday % 7],
                style: AppTypography.micro.copyWith(color: AppColors.muted),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeekRows(
    int weekStart,
    Map<String, List<WorkoutSession>> sessionsByDay,
    Map<String, SuggestedSessionDate> suggestionsByDay,
  ) {
    final daysInMonth = DateKeys.daysInMonth(
      _visibleMonth.year,
      _visibleMonth.month,
    );
    final first = DateTime(_visibleMonth.year, _visibleMonth.month);
    final leading = (first.weekday - weekStart + 7) % 7;
    final total = leading + daysInMonth;
    final weekCount = (total / 7).ceil();
    final now = _now;
    return Column(
      children: <Widget>[
        for (var week = 0; week < weekCount; week++)
          SizedBox(
            height: 62,
            child: Row(
              children: <Widget>[
                for (var slot = 0; slot < 7; slot++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final dayNumber = week * 7 + slot - leading + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        final date = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month,
                          dayNumber,
                        );
                        final key = DateKeys.dayKey(date);
                        final sessions =
                            sessionsByDay[key] ?? const <WorkoutSession>[];
                        final suggestion = suggestionsByDay[key];
                        return CalendarDayCell(
                          date: date,
                          sessions: sessions,
                          isToday: _isSameDay(date, now),
                          isSuggested: suggestion != null,
                          suggestedName: suggestion?.day.name,
                          onTap: () => _openDay(date, sessions, suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    Widget item(String asset, Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(asset: asset, size: 11, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
      );
    }

    return Wrap(
      spacing: AppSpacing.x2l,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        item(AppIcons.plan, AppColors.lime, 'Plan'),
        item(AppIcons.list, AppColors.blue, 'Routine'),
        item(AppIcons.walk, AppColors.gold, 'Walk'),
        item(AppIcons.run, AppColors.blue, 'Run'),
        Row(
          key: const Key('calendar-legend-suggested'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 16,
              height: 16,
              child: CustomPaint(
                painter: DashedCirclePainter(
                  color: AppColors.lime.withValues(alpha: 0.7),
                  dashLength: 2.2,
                  gapLength: 1.8,
                  strokeWidth: 1,
                ),
                child: const Center(
                  child: AppIcon(
                    asset: AppIcons.plan,
                    size: 7,
                    color: AppColors.lime,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Suggested',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final weekStart = effectiveWeekStart(context);
    final sessionsByDay = _sessionsByDay(history.workouts);
    final suggestion = _suggestion(history.workouts);
    final suggestionsByDay = _suggestionsByDay(suggestion);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          key: const Key('calendar-screen'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2l,
            AppSpacing.xl,
            AppSpacing.x2l,
            AppSpacing.x4l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: AppSpacing.sm),
              _buildMonthBar(),
              const SizedBox(height: AppSpacing.sm),
              _buildWeekdayRow(weekStart),
              const SizedBox(height: AppSpacing.xs),
              if (history.isLoading && history.workouts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.x4l),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.lime),
                  ),
                )
              else
                _buildWeekRows(weekStart, sessionsByDay, suggestionsByDay),
              const SizedBox(height: AppSpacing.x2l),
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }
}
