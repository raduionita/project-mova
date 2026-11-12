import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/routine.dart';
import '../navigation/routes.dart';
import '../providers/routine_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// Opens a routine picker and appends [exercise] to the chosen routine.
Future<void> addExerciseToRoutine(
  BuildContext context,
  Exercise exercise,
) {
  return showAddToRoutineSheet(
    context,
    exercise: exercise,
    onSelect: (routine) async {
      final provider = context.read<RoutineProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final saved = await provider.addExercise(
        routineId: routine.id,
        exerciseId: exercise.id,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Added ${exercise.name} to ${routine.name}.'
                : provider.error ?? 'Could not add to saved workout.',
          ),
        ),
      );
    },
    onCreateRoutine: () =>
        Navigator.of(context).pushNamed(Routes.routineNew),
  );
}

/// Bottom sheet that lists saved routines for adding an exercise.
Future<void> showAddToRoutineSheet(
  BuildContext context, {
  required Exercise exercise,
  required ValueChanged<Routine> onSelect,
  required VoidCallback onCreateRoutine,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.panel,
    builder: (_) => AddToRoutineSheet(
      exercise: exercise,
      onSelect: onSelect,
      onCreateRoutine: onCreateRoutine,
    ),
  );
}

/// Routine choices for adding one exercise.
class AddToRoutineSheet extends StatelessWidget {
  const AddToRoutineSheet({
    super.key,
    required this.exercise,
    required this.onSelect,
    required this.onCreateRoutine,
  });

  final Exercise exercise;
  final ValueChanged<Routine> onSelect;
  final VoidCallback onCreateRoutine;

  void _select(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Widget _buildRoutineRow(BuildContext context, Routine routine) {
    final radius = BorderRadius.circular(AppRadii.md);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.card,
        borderRadius: radius,
        child: InkWell(
          key: Key('add-to-routine-${routine.id}'),
          borderRadius: radius,
          onTap: () => _select(context, () => onSelect(routine)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                const AppIcon(
                  asset: AppIcons.list,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        routine.name,
                        style: AppTypography.bodyStrong.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        routine.exercises.length == 1
                            ? '1 exercise'
                            : '${routine.exercises.length} exercises',
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
    final routines = context.watch<RoutineProvider>().routines;
    return SafeArea(
      key: const Key('add-to-routine-sheet'),
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
                          'Add to saved workout',
                          style: AppTypography.h2.copyWith(
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          exercise.name,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('add-to-routine-close'),
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
              if (routines.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'No saved workouts yet. Create one, then add exercises to it.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                )
              else
                for (final routine in routines)
                  _buildRoutineRow(context, routine),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                key: const Key('add-to-routine-new'),
                onPressed: () =>
                    _select(context, onCreateRoutine),
                icon: const AppIcon(
                  asset: AppIcons.plus,
                  size: 16,
                  color: AppColors.lime,
                ),
                label: Text(
                  'New saved workout',
                  style: AppTypography.label.copyWith(color: AppColors.lime),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.line),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
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
