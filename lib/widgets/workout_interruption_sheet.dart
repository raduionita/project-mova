import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Choice made in the workout interruption sheet.
enum WorkoutInterruptionAction { pause, discard }

/// Opens the interruption sheet for an active workout.
Future<WorkoutInterruptionAction?> showWorkoutInterruptionSheet(
  BuildContext context, {
  required int completedSets,
}) {
  return showModalBottomSheet<WorkoutInterruptionAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.x3l)),
    ),
    builder: (_) => WorkoutInterruptionSheet(completedSets: completedSets),
  );
}

/// Sheet that protects an in-progress workout from an accidental exit.
class WorkoutInterruptionSheet extends StatelessWidget {
  const WorkoutInterruptionSheet({super.key, required this.completedSets});

  final int completedSets;

  Future<void> _confirmDiscard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final count = completedSets == 0
            ? 'No completed sets will be saved.'
            : completedSets == 1
            ? 'You will lose 1 completed set.'
            : 'You will lose $completedSets completed sets.';
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.x2l),
          ),
          title: Text(
            'Discard this workout?',
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
          content: Text(
            '$count This cannot be undone.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Keep workout',
                style: AppTypography.label.copyWith(color: AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Discard',
                style: AppTypography.label.copyWith(color: AppColors.orange),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(WorkoutInterruptionAction.discard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3l,
        AppSpacing.x2l,
        AppSpacing.x3l,
        AppSpacing.x3l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: Container(
              width: AppSpacing.x6l,
              height: AppSpacing.xs,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x2l),
          Text(
            'Workout in progress',
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Keep training, pause and exit, or discard this workout.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.x3l),
          AppButton(
            label: 'Keep training',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Pause and exit',
            variant: AppButtonVariant.ghost,
            onPressed: () =>
                Navigator.of(context).pop(WorkoutInterruptionAction.pause),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Discard workout',
            variant: AppButtonVariant.destructive,
            onPressed: () => _confirmDiscard(context),
          ),
        ],
      ),
    );
  }
}
