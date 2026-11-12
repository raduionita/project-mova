import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../models/focus_area.dart';
import '../../navigation/routes.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/workout_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/add_to_routine_sheet.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/exercise_choice_sheet.dart';
import '../../widgets/exercise_row.dart';

/// Exercise library at `/exercises`. Search, focus filters, and per-row add
/// actions that adapt to whether a workout is active.
class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) {
      return;
    }
    final exercises = context.read<ExerciseProvider>();
    if (exercises.exercises.isEmpty && !exercises.isLoading) {
      await exercises.load();
    }
  }

  Future<void> _handleAdd(Exercise exercise) async {
    final workout = context.read<WorkoutProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (workout.activeSession == null) {
      showExerciseChoiceSheet(
        context,
        exercise: exercise,
        onStartWorkout: () => _startWithExercise(exercise),
        onAddToRoutine: () => addExerciseToRoutine(context, exercise),
        onViewDetails: () =>
            Navigator.of(context).pushNamed(Routes.exerciseDetail(exercise.id)),
      );
      return;
    }
    final added = await workout.addExercise(
      exercise.id,
      exercise: exercise,
    );
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'Added ${exercise.name}.'
              : workout.error ?? 'Could not add ${exercise.name}.',
        ),
      ),
    );
  }

  Future<void> _startWithExercise(Exercise exercise) async {
    final workout = context.read<WorkoutProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final started = await workout.startEmpty();
    if (!started) {
      messenger.showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not start workout.')),
      );
      return;
    }
    final added = await workout.addExercise(
      exercise.id,
      exercise: exercise,
    );
    if (!mounted) {
      return;
    }
    if (!added) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            workout.error ?? 'Could not add ${exercise.name}.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushNamed(Routes.logger);
  }

  void _openWorkout() {
    Navigator.of(context).pushNamed(Routes.logger);
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ExerciseProvider>().clearSearch();
    setState(() {});
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<ExerciseProvider>().clearFilters();
    setState(() {});
  }

  Widget _buildHeader(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Exercises',
          style: AppTypography.h1.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          liveRegion: true,
          child: Text(
            count == 1 ? '1 exercise' : '$count exercises',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      borderSide: const BorderSide(color: AppColors.line),
    );
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        context.read<ExerciseProvider>().search(value);
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      style: AppTypography.body.copyWith(color: AppColors.text),
      cursorColor: AppColors.lime,
      decoration: InputDecoration(
        hintText: 'Search exercises, muscles, equipment',
        hintStyle: AppTypography.body.copyWith(color: AppColors.muted),
        prefixIcon: const AppIcon(
          asset: AppIcons.search,
          size: 20,
          color: AppColors.muted,
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clearSearch,
                tooltip: 'Clear search',
                icon: const AppIcon(
                  asset: AppIcons.close,
                  size: 18,
                  color: AppColors.muted,
                ),
              ),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2l,
          vertical: AppSpacing.xl,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: AppColors.limeBorder45),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ExerciseProvider provider) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        key: const Key('exercise-focus-chips'),
        scrollDirection: Axis.horizontal,
        itemCount: FocusArea.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final focus = FocusArea.values[index];
          final selected = focus == FocusArea.all
              ? provider.focusFilter == null
              : provider.focusFilter == focus;
          return AppChip(
            key: Key('exercise-focus-${focus.name}'),
            label: focus.label,
            selected: selected,
            onTap: () => provider.setFocusFilter(
              focus == FocusArea.all ? null : focus,
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseList(
    List<Exercise> exercises,
    WorkoutProvider workout,
  ) {
    final active = workout.activeSession;
    final activeIds = active == null
        ? const <String>{}
        : active.exercises.map((exercise) => exercise.exerciseId).toSet();
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final added = activeIds.contains(exercise.id);
        return ExerciseRow(
          exercise: exercise,
          isAdded: added,
          onAdd: () => _handleAdd(exercise),
          onView: added ? _openWorkout : null,
          onTap: () => Navigator.of(
            context,
          ).pushNamed(Routes.exerciseDetail(exercise.id)),
        );
      },
    );
  }

  Widget _buildBody(ExerciseProvider provider, WorkoutProvider workout) {
    if (provider.isLoading && provider.exercises.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.lime),
      );
    }
    if (provider.error != null && provider.exercises.isEmpty) {
      return AppEmptyState(
        assetIcon: AppIcons.alert,
        title: 'Could not load exercises',
        message: 'The local exercise library could not be read.',
        actionLabel: 'Try again',
        onAction: provider.load,
      );
    }
    if (provider.exercises.isEmpty) {
      return AppEmptyState(
        assetIcon: AppIcons.dumbbell,
        title: 'No exercises yet',
        message: 'The local exercise library is empty.',
        actionLabel: 'Reload library',
        onAction: provider.load,
      );
    }
    if (provider.filtered.isEmpty) {
      return AppEmptyState(
        assetIcon: AppIcons.search,
        title: 'No exercises found',
        message: 'Try a different search or focus filter.',
        actionLabel: 'Clear filters',
        onAction: _clearFilters,
      );
    }
    return _buildExerciseList(provider.filtered, workout);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final workout = context.watch<WorkoutProvider>();
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
              _buildHeader(provider.filtered.length),
              const SizedBox(height: AppSpacing.x2l),
              _buildSearchField(),
              const SizedBox(height: AppSpacing.sm),
              if (provider.exercises.isNotEmpty) _buildFilterChips(provider),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildBody(provider, workout)),
            ],
          ),
        ),
      ),
    );
  }
}
