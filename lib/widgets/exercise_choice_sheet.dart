import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// Actions offered when an exercise is added without an active workout.
Future<void> showExerciseChoiceSheet(
  BuildContext context, {
  required Exercise exercise,
  required VoidCallback onStartWorkout,
  required VoidCallback onAddToRoutine,
  required VoidCallback onViewDetails,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.panel,
    builder: (_) => ExerciseChoiceSheet(
      exercise: exercise,
      onStartWorkout: onStartWorkout,
      onAddToRoutine: onAddToRoutine,
      onViewDetails: onViewDetails,
    ),
  );
}

/// Bottom sheet that turns an exercise into a workout, a routine entry, or a
/// detail visit.
class ExerciseChoiceSheet extends StatelessWidget {
  const ExerciseChoiceSheet({
    super.key,
    required this.exercise,
    required this.onStartWorkout,
    required this.onAddToRoutine,
    required this.onViewDetails,
  });

  final Exercise exercise;
  final VoidCallback onStartWorkout;
  final VoidCallback onAddToRoutine;
  final VoidCallback onViewDetails;

  void _select(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Widget _buildOption(
    BuildContext context, {
    required Key key,
    required String asset,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(AppRadii.md);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.card,
        borderRadius: radius,
        child: InkWell(
          key: key,
          borderRadius: radius,
          onTap: () => _select(context, onTap),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: AppSpacing.x5l,
                  height: AppSpacing.x5l,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: AppIcon(
                    asset: asset,
                    size: 18,
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.bodyStrong.copyWith(
                          color: AppColors.text,
                        ),
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
                const AppIcon(
                  asset: AppIcons.chevronRight,
                  size: 16,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('exercise-choice-sheet'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x2l,
          AppSpacing.xl,
          AppSpacing.x2l,
          AppSpacing.x2l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        exercise.name,
                        style: AppTypography.h2.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${exercise.primaryMuscle} · ${exercise.equipment}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('exercise-choice-close'),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const AppIcon(
                    asset: AppIcons.close,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildOption(
              context,
              key: const Key('exercise-choice-start'),
              asset: AppIcons.play,
              title: 'Start workout with this',
              subtitle: 'Opens a new session with 3 sets ready',
              onTap: onStartWorkout,
            ),
            _buildOption(
              context,
              key: const Key('exercise-choice-routine'),
              asset: AppIcons.list,
              title: 'Add to saved workout',
              subtitle: 'Append it to a saved workout',
              onTap: onAddToRoutine,
            ),
            _buildOption(
              context,
              key: const Key('exercise-choice-details'),
              asset: AppIcons.history,
              title: 'View details',
              subtitle: 'Instructions, muscles, and previous sets',
              onTap: onViewDetails,
            ),
          ],
        ),
      ),
    );
  }
}
