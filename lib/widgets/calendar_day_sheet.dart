import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../common/formatters.dart';
import '../models/plan_day.dart';
import '../models/unit_preferences.dart';
import '../models/workout_session.dart';
import '../providers/settings_provider.dart';
import '../services/suggestion_cadence.dart';
import '../services/unit_conversion_service.dart';
import '../services/workout_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_icon.dart';
import 'app_tag.dart';

final DateFormat _dayTitleFormat = DateFormat('EEEE, MMM d', 'en_US');

/// Opens the calendar day detail for a logged, rest, or suggested day.
Future<void> showCalendarDaySheet(
  BuildContext context, {
  required DateTime date,
  required List<WorkoutSession> sessions,
  required bool isToday,
  SuggestedSessionDate? suggestion,
  required ValueChanged<WorkoutSession> onOpenSession,
  required ValueChanged<WorkoutSession> onEditSession,
  required VoidCallback onStartWorkout,
  required ValueChanged<PlanDay> onStartSuggestion,
  required VoidCallback onViewSuggestion,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.panel,
    builder: (_) => CalendarDaySheet(
      date: date,
      sessions: sessions,
      isToday: isToday,
      suggestion: suggestion,
      onOpenSession: onOpenSession,
      onEditSession: onEditSession,
      onStartWorkout: onStartWorkout,
      onStartSuggestion: onStartSuggestion,
      onViewSuggestion: onViewSuggestion,
    ),
  );
}

/// Day detail with logged sessions, rest copy, or the next suggested session.
class CalendarDaySheet extends StatelessWidget {
  const CalendarDaySheet({
    super.key,
    required this.date,
    required this.sessions,
    required this.isToday,
    required this.onOpenSession,
    required this.onEditSession,
    required this.onStartWorkout,
    required this.onStartSuggestion,
    required this.onViewSuggestion,
    this.suggestion,
  });

  final DateTime date;
  final List<WorkoutSession> sessions;
  final bool isToday;
  final SuggestedSessionDate? suggestion;
  final ValueChanged<WorkoutSession> onOpenSession;
  final ValueChanged<WorkoutSession> onEditSession;
  final VoidCallback onStartWorkout;
  final ValueChanged<PlanDay> onStartSuggestion;
  final VoidCallback onViewSuggestion;

  bool get _isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isBefore(today);
  }

  void _select(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Widget _buildHeader(BuildContext context) {
    final subtitle = sessions.isEmpty
        ? (suggestion == null ? 'Rest day' : 'Suggested session')
        : (sessions.length == 1 ? '1 workout logged' : '${sessions.length} workouts logged');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x2l,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _dayTitleFormat.format(date),
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('calendar-day-close'),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
            icon: const AppIcon(asset: AppIcons.close, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRow(
    BuildContext context,
    WorkoutSession session,
    WeightUnit unit,
    DistanceUnit distanceUnit,
  ) {
    final at = session.completedAt ?? session.startedAt;
    final duration = WorkoutCalculator.sessionDurationSeconds(
      session,
      DateTime.now(),
    );
    final volume = WorkoutCalculator.volumeKg(session.exercises);
    final distance = session.distanceMeters;
    final isActivity =
        session.source == SessionSource.run ||
        session.source == SessionSource.walk;
    final detail = isActivity && distance != null && distance > 0
        ? UnitConversionService().displayDistance(distance / 1000, distanceUnit)
        : formatVolume(volume, unit: unit);
    final title = session.displayTitle.trim().isEmpty
        ? session.name
        : session.displayTitle;
    final source = session.sourceLabel.trim().isEmpty
        ? _sourceName(session.source)
        : session.sourceLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () => _select(context, () => onOpenSession(session)),
        child: Row(
          children: <Widget>[
            AppIcon(
              asset: _sourceIcon(session.source),
              size: 22,
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
                    '$source · ${_timeLabel(context, at)} · '
                    '${formatDuration(duration)} · $detail',
                    maxLines: 2,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              key: Key('calendar-day-edit-${session.id}'),
              tooltip: 'Edit workout',
              onPressed: () => _select(
                context,
                () => onEditSession(session),
              ),
              icon: const AppIcon(
                asset: AppIcons.edit,
                size: 18,
                color: AppColors.muted,
              ),
            ),
            const AppIcon(
              asset: AppIcons.chevronRight,
              size: 16,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(BuildContext context, DateTime date) {
    return TimeOfDay.fromDateTime(date).format(context);
  }

  Widget _buildSuggestion(BuildContext context) {
    final suggested = suggestion;
    if (suggested == null) {
      return const SizedBox.shrink();
    }
    final day = suggested.day;
    final muscles = day.muscleGroups.isEmpty
        ? '${day.exercises.length} exercises'
        : day.muscleGroups.join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          featured: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppTag(label: 'Suggested', variant: AppTagVariant.lime),
              const SizedBox(height: AppSpacing.sm),
              Text(
                day.name,
                style: AppTypography.h2.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$muscles · ~${day.estimatedMinutes} min',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          key: const Key('calendar-day-view-suggestion'),
          label: 'View session',
          variant: AppButtonVariant.ghost,
          assetIcon: AppIcons.plan,
          onPressed: () => _select(context, onViewSuggestion),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const Key('calendar-day-start-suggestion'),
          label: 'Start now',
          assetIcon: AppIcons.play,
          onPressed: () => _select(
            context,
            () => onStartSuggestion(day),
          ),
        ),
      ],
    );
  }

  Widget _buildRest(BuildContext context) {
    final message = isToday
        ? 'Nothing logged yet today. Training is never blocked.'
        : _isPast
        ? 'No workout logged. Unlogged days count as rest.'
        : 'Rest days are flexible. You can train anyway.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          child: Row(
            children: <Widget>[
              Container(
                width: AppSpacing.x5l,
                height: AppSpacing.x5l,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                child: const AppIcon(
                  asset: AppIcons.seedling,
                  size: 18,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.body.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
        if (isToday || !_isPast) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const Key('calendar-day-start-workout'),
            label: 'Start workout',
            assetIcon: AppIcons.play,
            onPressed: () => _select(context, onStartWorkout),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final preferences = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences;
    final unit = preferences.weightUnit;
    final distanceUnit = preferences.distanceUnit;
    return SafeArea(
      key: const Key('calendar-day-sheet'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.x2l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x2l,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (sessions.isNotEmpty)
                      for (final session in sessions)
                        _buildSessionRow(context, session, unit, distanceUnit),
                    if (sessions.isNotEmpty && isToday) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        key: const Key('calendar-day-start-workout'),
                        label: 'Start workout',
                        assetIcon: AppIcons.play,
                        onPressed: () => _select(context, onStartWorkout),
                      ),
                    ],
                    if (sessions.isEmpty) _buildSuggestion(context),
                    if (sessions.isEmpty && suggestion == null)
                      _buildRest(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _sourceName(SessionSource source) {
  switch (source) {
    case SessionSource.plan:
      return 'Plan';
    case SessionSource.routine:
      return 'Routine';
    case SessionSource.walk:
      return 'Walk';
    case SessionSource.run:
      return 'Run';
    case SessionSource.empty:
      return 'Empty';
  }
}

String _sourceIcon(SessionSource source) {
  switch (source) {
    case SessionSource.plan:
      return AppIcons.plan;
    case SessionSource.routine:
      return AppIcons.list;
    case SessionSource.walk:
      return AppIcons.walk;
    case SessionSource.run:
      return AppIcons.run;
    case SessionSource.empty:
      return AppIcons.dumbbell;
  }
}
