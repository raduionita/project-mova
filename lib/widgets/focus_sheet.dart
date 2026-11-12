import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/focus_area.dart';
import '../providers/exercise_provider.dart';
import '../providers/plan_provider.dart';
import '../providers/workout_provider.dart';
import '../services/focus_suggestion_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_icon.dart';
import '../widgets/exercise_picker_sheet.dart';

/// Opens the one-time focus drawer for an empty workout.
Future<void> showFocusSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panel,
    builder: (_) => const FocusSheet(),
  );
}

/// Focus chooser with faded, quick-add exercise suggestions.
class FocusSheet extends StatefulWidget {
  const FocusSheet({super.key});

  @override
  State<FocusSheet> createState() => _FocusSheetState();
}

class _FocusSheetState extends State<FocusSheet> {
  FocusArea _focus = FocusArea.all;

  List<Exercise> _suggestions(
    ExerciseProvider provider,
    WorkoutProvider workout,
  ) {
    final plan = _readPlan();
    return const FocusSuggestionService().suggest(
      focus: _focus,
      exercises: provider.exercises,
      availableEquipment: plan?.plan?.availableEquipment,
      excludedExerciseIds:
          workout.activeSession?.exercises
              .map((exercise) => exercise.exerciseId)
              .toSet() ??
          const <String>{},
    );
  }

  PlanProvider? _readPlan() {
    try {
      return context.read<PlanProvider>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  Future<void> _add(Exercise exercise) async {
    await addExercisesToWorkout(context, <Exercise>[exercise]);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _browse(WorkoutProvider workout) async {
    final plan = _readPlan();
    final result = await showExercisePicker(
      context,
      mode: ExercisePickerMode.session,
      multiSelect: true,
      availableEquipment: plan?.plan?.availableEquipment,
      excludedExerciseIds:
          workout.activeSession?.exercises
              .map((exercise) => exercise.exerciseId)
              .toSet() ??
          const <String>{},
      initialFocusMuscles: _focus == FocusArea.all ? null : _focus.muscles,
      focusLabel: _focus == FocusArea.all ? null : _focus.label,
      title: 'Add exercise',
    );
    if (result == null || result.exercises.isEmpty || !mounted) {
      return;
    }
    await addExercisesToWorkout(context, result.exercises);
    if (mounted) {
      setState(() {});
    }
  }

  List<Widget> _buildFocusChips() {
    return <Widget>[
      for (final focus in FocusArea.values)
        AppChip(
          key: Key('focus-option-${focus.name}'),
          label: focus.label,
          selected: _focus == focus,
          onTap: () => setState(() => _focus = focus),
        ),
    ];
  }

  List<Widget> _buildSuggestions(List<Exercise> suggestions) {
    if (suggestions.isEmpty) {
      return <Widget>[
        Text(
          'No suggestions match your equipment. Browse the library instead.',
          style: AppTypography.body.copyWith(color: AppColors.muted),
        ),
      ];
    }
    return <Widget>[
      for (final exercise in suggestions)
        AppCard(
          key: Key('focus-suggestion-${exercise.id}'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          onTap: () => _add(exercise),
          child: Opacity(
            opacity: 0.72,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        exercise.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStrong.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${exercise.primaryMuscle} · ${exercise.equipment}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('focus-add-${exercise.id}'),
                  onPressed: () => _add(exercise),
                  tooltip: 'Add ${exercise.name}',
                  icon: const AppIcon(
                    asset: AppIcons.plus,
                    size: 20,
                    color: AppColors.lime,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildHeader() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Choose a focus',
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
        ),
        IconButton(
          key: const Key('focus-close'),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
          icon: const AppIcon(asset: AppIcons.close, color: AppColors.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final workout = context.watch<WorkoutProvider>();
    final suggestions = _suggestions(provider, workout);
    final height = MediaQuery.sizeOf(context).height * 0.86;
    return SafeArea(
      key: const Key('focus-sheet'),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2l,
                AppSpacing.md,
                AppSpacing.sm,
                0,
              ),
              child: _buildHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
              child: Text(
                'Pick what you want to train. Mova suggests a few exercises '
                'you can add right away.',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _buildFocusChips(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${_focus.label} suggestions',
                      style: AppTypography.title.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Text(
                    'Tap to add',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final item in _buildSuggestions(suggestions)) ...[
                      item,
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2l,
                AppSpacing.md,
                AppSpacing.x2l,
                AppSpacing.x2l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppButton(
                    key: const Key('focus-browse'),
                    label: 'Browse exercises',
                    variant: AppButtonVariant.ghost,
                    assetIcon: AppIcons.search,
                    onPressed: () => _browse(workout),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    key: const Key('focus-done'),
                    label: 'Done',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
