import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exercise.dart';
import '../../navigation/routes.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/workout_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/exercise_row.dart';
import '../../widgets/routine_row.dart';

/// Train tab exercise library. Lists the local exercise seed library, filters
/// by name, muscle, or equipment, and adds an exercise to the active workout.
class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key});

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
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
    final routines = context.read<RoutineProvider>();
    await Future.wait<void>(<Future<void>>[
      if (exercises.exercises.isEmpty && !exercises.isLoading) exercises.load(),
      if (routines.routines.isEmpty && !routines.isLoading) routines.load(),
    ]);
  }

  Future<void> _handleAdd(Exercise exercise) async {
    final workout = context.read<WorkoutProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (workout.activeSession == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Start a workout to add ${exercise.name}.')),
      );
      return;
    }
    final added = await workout.addExercise(exercise.id);
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

  Widget _buildHeader(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Train', style: AppTypography.h1.copyWith(color: AppColors.text)),
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
      onChanged: (value) => context.read<ExerciseProvider>().search(value),
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

  void _clearSearch() {
    _searchController.clear();
    context.read<ExerciseProvider>().clearSearch();
  }

  List<String> _muscleOptions(List<Exercise> exercises) {
    final muscles = <String>[];
    for (final exercise in exercises) {
      if (!muscles.contains(exercise.primaryMuscle)) {
        muscles.add(exercise.primaryMuscle);
      }
    }
    return muscles;
  }

  Widget _buildFilterChips(ExerciseProvider provider) {
    final muscles = _muscleOptions(provider.exercises);
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: muscles.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppChip(
              label: 'All',
              selected: provider.muscleFilter == null,
              onTap: () => provider.setMuscleFilter(null),
            );
          }
          final muscle = muscles[index - 1];
          return AppChip(
            label: muscle,
            selected: provider.muscleFilter == muscle,
            onTap: () => provider.setMuscleFilter(muscle),
          );
        },
      ),
    );
  }

  Widget _buildRoutineSection(RoutineProvider routines) {
    final saved = routines.routines.take(2).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'My routines',
              style: AppTypography.title.copyWith(color: AppColors.text),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(Routes.routines),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.lime,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, AppSpacing.x5l),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: AppTypography.label.copyWith(color: AppColors.lime),
              ),
            ),
          ],
        ),
        if (saved.isEmpty)
          Text(
            'No routines yet.',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          )
        else
          for (final routine in saved) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            RoutineRow(
              routine: routine,
              onTap: () =>
                  Navigator.of(context)
                      .pushNamed(Routes.routineDetail(routine.id)),
            ),
          ],
      ],
    );
  }

  Widget _buildExerciseList(List<Exercise> exercises) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return ExerciseRow(
          exercise: exercise,
          onTap: () =>
              Navigator.of(context)
                  .pushNamed(Routes.exerciseDetail(exercise.id)),
          onAdd: () => _handleAdd(exercise),
        );
      },
    );
  }

  Widget _buildBody(ExerciseProvider provider) {
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
        message: 'Try a different search or muscle filter.',
        actionLabel: 'Clear filters',
        onAction: _clearFilters,
      );
    }
    return _buildExerciseList(provider.filtered);
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<ExerciseProvider>().clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final routines = context.watch<RoutineProvider>();
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
              _buildRoutineSection(routines),
              const SizedBox(height: AppSpacing.x2l),
              Expanded(child: _buildBody(provider)),
            ],
          ),
        ),
      ),
    );
  }
}
