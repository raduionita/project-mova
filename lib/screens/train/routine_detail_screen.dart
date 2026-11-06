import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/routine.dart';
import '../../models/routine_exercise.dart';
import '../../navigation/routes.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/workout_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';

/// Saved routine details with editing and one-tap starts.
class RoutineDetailScreen extends StatefulWidget {
  const RoutineDetailScreen({super.key, required this.routineId});

  final String routineId;

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final routines = context.read<RoutineProvider>();
    final exercises = context.read<ExerciseProvider>();
    await Future.wait<void>(<Future<void>>[
      if (routines.routines.isEmpty && !routines.isLoading) routines.load(),
      if (exercises.exercises.isEmpty && !exercises.isLoading) exercises.load(),
    ]);
  }

  Future<void> _startRoutine(Routine routine) async {
    final workout = context.read<WorkoutProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final started = await workout.startFromRoutine(routine);
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

  Future<void> _confirmDelete(Routine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.x2l),
          ),
          title: Text(
            'Delete routine?',
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
          content: Text(
            'Delete "${routine.name}"? This cannot be undone.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: AppTypography.label.copyWith(color: AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: AppTypography.label.copyWith(color: AppColors.orange),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final provider = context.read<RoutineProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await provider.delete(widget.routineId);
    if (!mounted) {
      return;
    }
    if (!deleted) {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not delete routine.')),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  String _repsLabel(RoutineExercise exercise) {
    if (exercise.repsLow == exercise.repsHigh) {
      return '${exercise.repsLow} reps';
    }
    return '${exercise.repsLow}-${exercise.repsHigh} reps';
  }

  Widget _buildExerciseRow(
    int index,
    RoutineExercise routineExercise,
    String name,
  ) {
    final rest = routineExercise.restSeconds > 0
        ? ' · Rest ${routineExercise.restSeconds}s'
        : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: AppSpacing.x4l,
          height: AppSpacing.x4l,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.limeSoft,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Text(
            '${index + 1}',
            style: AppTypography.micro.copyWith(color: AppColors.lime),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${routineExercise.sets} sets · '
                '${_repsLabel(routineExercise)}$rest',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList(
    List<RoutineExercise> exercises,
    ExerciseProvider library,
  ) {
    if (exercises.isEmpty) {
      return const AppEmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'No exercises yet',
        message: 'Edit this routine to add exercises.',
      );
    }
    final ordered = <RoutineExercise>[...exercises]
      ..sort((a, b) => a.order.compareTo(b.order));
    return AppCard(
      child: Column(
        children: <Widget>[
          for (var index = 0; index < ordered.length; index++) ...<Widget>[
            if (index > 0)
              const Divider(height: AppSpacing.x3l, color: AppColors.line),
            _buildExerciseRow(
              index,
              ordered[index],
              library.byId(ordered[index].exerciseId)?.name ??
                  'Unknown exercise',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(Routine routine, ExerciseProvider library) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  routine.name,
                  style: AppTypography.h1.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  routine.exercises.length == 1
                      ? '1 exercise'
                      : '${routine.exercises.length} exercises',
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.x3l),
                _buildExerciseList(routine.exercises, library),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Start now', onPressed: () => _startRoutine(routine)),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Edit routine',
          variant: AppButtonVariant.ghost,
          onPressed: () =>
              Navigator.of(context).pushNamed(Routes.routineEdit(routine.id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Delete routine',
          variant: AppButtonVariant.destructive,
          onPressed: () => _confirmDelete(routine),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final routines = context.watch<RoutineProvider>();
    final library = context.watch<ExerciseProvider>();
    final routine = routines.routines
        .where((item) => item.id == widget.routineId)
        .firstOrNull;
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
              const AppBackBar(label: 'Routines'),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: routine == null
                    ? (routines.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.lime,
                              ),
                            )
                          : const AppEmptyState(
                              icon: Icons.search_off,
                              title: 'Routine not found',
                              message: 'This routine is no longer saved on this device.',
                            ))
                    : _buildContent(routine, library),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
