import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/formatters.dart';
import '../models/session_exercise.dart';
import '../models/unit_preferences.dart';
import '../models/workout_session.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../services/unit_conversion_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// Opens recent logged sets for one exercise.
Future<void> showExerciseHistorySheet(
  BuildContext context, {
  required String exerciseId,
  required String exerciseName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.panel,
    builder: (_) => ExerciseHistorySheet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
    ),
  );
}

/// Bottom sheet with date, weight, and reps for one exercise.
class ExerciseHistorySheet extends StatelessWidget {
  const ExerciseHistorySheet({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  static const UnitConversionService _units = UnitConversionService();

  final String exerciseId;
  final String exerciseName;

  List<_HistoryEntry> _entries(List<WorkoutSession> workouts) {
    final entries = <_HistoryEntry>[];
    for (final session in workouts) {
      for (final exercise in session.exercises) {
        if (exercise.exerciseId == exerciseId) {
          entries.add(_HistoryEntry(session: session, exercise: exercise));
        }
      }
    }
    return entries;
  }

  Widget _buildSetRow(String label, WeightUnit unit) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: AppColors.muted),
      ),
    );
  }

  Widget _buildEntry(_HistoryEntry entry, WeightUnit unit) {
    final at = entry.session.completedAt ?? entry.session.startedAt;
    final title = entry.session.displayTitle.trim().isEmpty
        ? entry.session.name
        : entry.session.displayTitle;
    final sets = entry.exercise.sets.where((set) => set.completed).toList();
    final visible = sets.isEmpty ? entry.exercise.sets : sets;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                ),
                Text(
                  formatDetailDate(at),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (visible.isEmpty)
              Text(
                'No sets logged.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.muted,
                ),
              )
            else
              for (var index = 0; index < visible.length; index++)
                _buildSetRow(
                  '${index + 1}. '
                  '${_units.displayWeight(visible[index].weightKg, unit)} × '
                  '${visible[index].reps}',
                  unit,
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    final entries = _entries(progress.workouts);
    return SafeArea(
      key: const Key('exercise-history-sheet'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2l,
            AppSpacing.xl,
            AppSpacing.x2l,
            AppSpacing.x2l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                exerciseName,
                style: AppTypography.h2.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Recent sets',
                style: AppTypography.caption.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (entries.isEmpty)
                Text(
                  'No sets logged yet. Finish a workout to see history.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.muted,
                  ),
                )
              else
                for (final entry in entries) _buildEntry(entry, unit),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({required this.session, required this.exercise});

  final WorkoutSession session;
  final SessionExercise exercise;
}
