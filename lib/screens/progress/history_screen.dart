import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/date_keys.dart';
import '../../common/formatters.dart';
import '../../models/unit_preferences.dart';
import '../../models/workout_session.dart';
import '../../navigation/routes.dart';
import '../../providers/history_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/clock.dart';
import '../../services/workout_calculator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_tag.dart';

/// Completed workout history grouped by month.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.clock});

  final Clock? clock;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime get _now => (widget.clock ?? const SystemClock()).now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final history = context.read<HistoryProvider>();
    final progress = context.read<ProgressProvider>();
    await Future.wait<void>(<Future<void>>[
      if (history.workouts.isEmpty && !history.isLoading) history.load(),
      progress.load(),
    ]);
  }

  int _prCount(ProgressProvider progress, String sessionId) {
    return progress.prs.values
        .where((record) => record.sessionId == sessionId)
        .length;
  }

  Widget _buildRow(
    WorkoutSession session,
    ProgressProvider progress,
    WeightUnit unit,
  ) {
    final date = session.completedAt ?? session.startedAt;
    final duration = WorkoutCalculator.sessionDurationSeconds(session, _now);
    final volume = WorkoutCalculator.volumeKg(session.exercises);
    final prs = _prCount(progress, session.id);
    return AppCard(
      onTap: () =>
          Navigator.of(context)
              .pushNamed(Routes.progressHistoryDetail(session.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  session.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              if (prs > 0) ...<Widget>[
                const SizedBox(width: AppSpacing.md),
                AppTag(
                  label: prs == 1 ? '1 PR' : '$prs PRs',
                  variant: AppTagVariant.gold,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatShortDate(date),
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${formatDuration(duration)} · ${formatVolume(volume, unit: unit)}',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildGroups(
    List<WorkoutSession> workouts,
    ProgressProvider progress,
    WeightUnit unit,
  ) {
    final groups = <String, List<WorkoutSession>>{};
    for (final workout in workouts) {
      final key = DateKeys.monthKey(workout.completedAt ?? workout.startedAt);
      groups.putIfAbsent(key, () => <WorkoutSession>[]).add(workout);
    }
    final months = groups.keys.toList(growable: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final month in months) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                formatMonthYear(DateTime.parse('$month-01')),
                style: AppTypography.label.copyWith(color: AppColors.muted),
              ),
            ),
            for (
              var index = 0;
              index < groups[month]!.length;
              index++
            ) ...<Widget>[
              if (index > 0) const SizedBox(height: AppSpacing.md),
              _buildRow(groups[month]![index], progress, unit),
            ],
            const SizedBox(height: AppSpacing.x3l),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final progress = context.watch<ProgressProvider>();
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    final workouts = history.workouts;

    Widget body;
    if (history.isLoading && workouts.isEmpty) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.lime),
      );
    } else if (workouts.isEmpty) {
      body = AppEmptyState(
        icon: Icons.history,
        title: 'No workouts yet',
        message: 'Finish a workout to see it here.',
        actionLabel: 'Start your first workout',
        onAction: () =>
            Navigator.of(context).pushReplacementNamed(Routes.today),
      );
    } else {
      body = _buildGroups(workouts, progress, unit);
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
              const AppBackBar(label: 'Progress'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Workout history',
                style: AppTypography.h1.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                workouts.length == 1
                    ? '1 completed workout'
                    : '${workouts.length} completed workouts',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.x2l),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
