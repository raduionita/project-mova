import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/formatters.dart';
import '../../models/exercise.dart';
import '../../models/personal_record.dart';
import '../../models/unit_preferences.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/unit_conversion_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/exercise_picker_sheet.dart';

/// Exercise details. Renders instructions, muscle and equipment tags, and the
/// previous best set. The add actions are enabled by TRN-21.
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  static const UnitConversionService _units = UnitConversionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }
    final exercises = context.read<ExerciseProvider>();
    final progress = context.read<ProgressProvider>();
    await Future.wait<void>(<Future<void>>[
      if (exercises.exercises.isEmpty && !exercises.isLoading) exercises.load(),
      progress.load(),
    ]);
  }

  Widget _buildBackBar() {
    return const AppBackBar(label: 'Exercise');
  }

  Widget _buildTags(Exercise exercise) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        AppTag(label: exercise.primaryMuscle, variant: AppTagVariant.lime),
        for (final muscle in exercise.secondaryMuscles) AppTag(label: muscle),
        AppTag(label: exercise.equipment),
      ],
    );
  }

  Widget _buildBestCard(
    PersonalRecord? record,
    UnitConversionService units,
    WeightUnit unit,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Previous best',
            style: AppTypography.label.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (record == null)
            Text(
              'First time? Log a set to start tracking.',
              style: AppTypography.body.copyWith(color: AppColors.muted),
            )
          else ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  '${units.displayWeight(record.weightKg, unit)} × ${record.reps}',
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
                const Spacer(),
                Text(
                  formatDetailDate(record.achievedAt),
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Estimated 1RM ${units.displayWeight(record.bestE1rmKg, unit)}',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstruction(int index, String instruction) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.limeSoft,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Text(
            '${index + 1}',
            style: AppTypography.micro.copyWith(color: AppColors.lime),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Text(
            instruction,
            style: AppTypography.body.copyWith(color: AppColors.text),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(Exercise exercise) {
    if (exercise.instructions.isEmpty) {
      return Text(
        'No instructions yet.',
        style: AppTypography.body.copyWith(color: AppColors.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var index = 0; index < exercise.instructions.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x2l),
            child: _buildInstruction(index, exercise.instructions[index]),
          ),
      ],
    );
  }

  Future<void> _openPicker(Exercise exercise) async {
    final result = await showExercisePicker(
      context,
      mode: ExercisePickerMode.session,
      initialExerciseIds: <String>{exercise.id},
    );
    if (result == null || result.exercises.isEmpty || !mounted) {
      return;
    }
    await addExercisesToWorkout(context, result.exercises);
  }

  Widget _buildActions(Exercise exercise, bool canAdd) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x2l,
        AppSpacing.xl,
        AppSpacing.x2l,
        AppSpacing.x2l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppButton(
            label: 'Add to workout',
            onPressed: canAdd ? () => _openPicker(exercise) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Exercise exercise, bool canAdd) {
    final progress = context.watch<ProgressProvider>();
    final settings = context.watch<SettingsProvider>();
    final unit = settings.settings.unitPreferences.weightUnit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x2l,
              AppSpacing.md,
              AppSpacing.x2l,
              AppSpacing.x4l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  exercise.name,
                  style: AppTypography.h1.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildTags(exercise),
                const SizedBox(height: AppSpacing.x3l),
                _buildBestCard(progress.prs[exercise.id], _units, unit),
                const SizedBox(height: AppSpacing.x4l),
                Text(
                  'Instructions',
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.x2l),
                _buildInstructions(exercise),
              ],
            ),
          ),
        ),
        _buildActions(exercise, canAdd),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = context.watch<ExerciseProvider>();
    final workout = context.watch<WorkoutProvider>();
    final exercise = exercises.byId(widget.exerciseId);
    final canAdd = workout.activeSession != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildBackBar(),
            Expanded(
              child: exercise == null
                  ? (exercises.isLoading || exercises.exercises.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.lime,
                            ),
                          )
                        : const AppEmptyState(
                            icon: Icons.fitness_center_outlined,
                            title: 'Exercise not found',
                            message:
                                'This exercise is no longer in the local '
                                'library.',
                          ))
                  : _buildContent(exercise, canAdd),
            ),
          ],
        ),
      ),
    );
  }
}
