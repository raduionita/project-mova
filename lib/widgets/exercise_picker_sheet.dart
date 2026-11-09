import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_coordinator.dart';
import '../models/equipment_group.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';
import '../providers/workout_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_chip.dart';
import '../widgets/app_icon.dart';

/// Where the exercise picker was opened from. The mode changes only the primary
/// action; callers own what happens with the returned selection.
enum ExercisePickerMode { browse, session, routine }

/// Exercises chosen in the picker.
class ExercisePickerResult {
  const ExercisePickerResult(this.exercises);

  final List<Exercise> exercises;
}

/// Opens the shared exercise picker as a bottom sheet.
Future<ExercisePickerResult?> showExercisePicker(
  BuildContext context, {
  ExercisePickerMode mode = ExercisePickerMode.browse,
  bool multiSelect = false,
  Set<String> initialExerciseIds = const <String>{},
  List<EquipmentGroup>? availableEquipment,
  Set<String> excludedExerciseIds = const <String>{},
  String? initialMuscle,
  String? title,
}) {
  return showModalBottomSheet<ExercisePickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.x3l)),
    ),
    builder: (_) => ExercisePickerSheet(
      mode: mode,
      multiSelect: multiSelect,
      initialExerciseIds: initialExerciseIds,
      availableEquipment: availableEquipment,
      excludedExerciseIds: excludedExerciseIds,
      initialMuscle: initialMuscle,
      title: title,
    ),
  );
}

/// Adds the selected exercises to the active session, sharing the snackbar
/// feedback used by the Train library and exercise details.
Future<bool> addExercisesToWorkout(
  BuildContext context,
  List<Exercise> exercises,
) async {
  if (exercises.isEmpty) {
    return false;
  }
  final workout = context.read<WorkoutProvider>();
  AppCoordinator? coordinator;
  try {
    coordinator = context.read<AppCoordinator>();
  } on ProviderNotFoundException {
    coordinator = null;
  }
  final messenger = ScaffoldMessenger.of(context);
  if (workout.activeSession == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Start a workout to add exercises.')),
    );
    return false;
  }
  for (final exercise in exercises) {
    final added = coordinator == null
        ? await workout.addExercise(exercise.id)
        : await coordinator.addExerciseToWorkout(exercise.id);
    if (!added) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(workout.error ?? 'Could not add ${exercise.name}.'),
        ),
      );
      return false;
    }
  }
  if (!context.mounted) {
    return false;
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        exercises.length == 1
            ? 'Added ${exercises.single.name}.'
            : 'Added ${exercises.length} exercises.',
      ),
    ),
  );
  return true;
}

/// Searchable, filterable exercise library sheet from DESIGN.md section 10.9.
class ExercisePickerSheet extends StatefulWidget {
  const ExercisePickerSheet({
    super.key,
    this.mode = ExercisePickerMode.browse,
    this.multiSelect = false,
    this.initialExerciseIds = const <String>{},
    this.availableEquipment,
    this.excludedExerciseIds = const <String>{},
    this.initialMuscle,
    this.title,
  });

  final ExercisePickerMode mode;
  final bool multiSelect;
  final Set<String> initialExerciseIds;
  final List<EquipmentGroup>? availableEquipment;
  final Set<String> excludedExerciseIds;
  final String? initialMuscle;
  final String? title;

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  String _query = '';
  String? _muscleFilter;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialExerciseIds);
    _muscleFilter = widget.initialMuscle;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final provider = context.read<ExerciseProvider>();
    if (provider.exercises.isEmpty && !provider.isLoading) {
      await provider.load();
    }
  }

  List<Exercise> _compatible(List<Exercise> exercises) {
    final allowed = widget.availableEquipment == null
        ? null
        : EquipmentGroup.expand(widget.availableEquipment!);
    return exercises
        .where((exercise) {
          if (widget.excludedExerciseIds.contains(exercise.id)) {
            return false;
          }
          return allowed == null || allowed.contains(exercise.equipment);
        })
        .toList(growable: false);
  }

  List<Exercise> _filtered(
    List<Exercise> exercises, {
    bool ignoreMuscle = false,
  }) {
    final query = _query.trim().toLowerCase();
    return exercises
        .where((exercise) {
          if (!ignoreMuscle &&
              _muscleFilter != null &&
              exercise.primaryMuscle.toLowerCase() !=
                  _muscleFilter!.toLowerCase()) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return exercise.name.toLowerCase().contains(query) ||
              exercise.primaryMuscle.toLowerCase().contains(query) ||
              exercise.equipment.toLowerCase().contains(query) ||
              exercise.secondaryMuscles.any(
                (muscle) => muscle.toLowerCase().contains(query),
              );
        })
        .toList(growable: false);
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

  String get _title {
    if (widget.title != null) {
      return widget.title!;
    }
    switch (widget.mode) {
      case ExercisePickerMode.browse:
        return 'Choose exercise';
      case ExercisePickerMode.session:
        return 'Add exercise';
      case ExercisePickerMode.routine:
        return 'Add to routine';
    }
  }

  String get _primaryLabel {
    switch (widget.mode) {
      case ExercisePickerMode.browse:
        return widget.multiSelect ? 'Select exercises' : 'Select exercise';
      case ExercisePickerMode.session:
        return 'Add to workout';
      case ExercisePickerMode.routine:
        return 'Add to routine';
    }
  }

  void _select(Exercise exercise) {
    setState(() {
      if (widget.multiSelect) {
        if (!_selectedIds.remove(exercise.id)) {
          _selectedIds.add(exercise.id);
        }
      } else {
        _selectedIds
          ..clear()
          ..add(exercise.id);
      }
    });
  }

  void _submit(List<Exercise> exercises) {
    final selected = exercises
        .where((exercise) => _selectedIds.contains(exercise.id))
        .toList(growable: false);
    Navigator.of(context).pop(ExercisePickerResult(selected));
  }

  Widget _buildHeader() {
    return Column(
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        Container(
          width: AppSpacing.x5l,
          height: AppSpacing.xs,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2l,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _title,
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
                icon: const AppIcon(
                  asset: AppIcons.close,
                  color: AppColors.muted,
                ),
              ),
            ],
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
      onChanged: (value) => setState(() => _query = value),
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
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
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

  Widget _buildFilterChips(List<Exercise> exercises) {
    final muscles = _muscleOptions(exercises);
    return SizedBox(
      height: AppSpacing.x5l,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: muscles.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppChip(
              label: 'All',
              selected: _muscleFilter == null,
              onTap: () => setState(() => _muscleFilter = null),
            );
          }
          final muscle = muscles[index - 1];
          return AppChip(
            label: muscle,
            selected: _muscleFilter == muscle,
            onTap: () => setState(() => _muscleFilter = muscle),
          );
        },
      ),
    );
  }

  Widget _buildList(List<Exercise> exercises, {String? emptyMessage}) {
    if (exercises.isEmpty) {
      return Center(
        child: Text(
          emptyMessage ?? 'No exercises found',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.muted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      itemCount: exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _PickerRow(
          exercise: exercise,
          selected: _selectedIds.contains(exercise.id),
          multiSelect: widget.multiSelect,
          onTap: () => _select(exercise),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final compatible = _compatible(provider.exercises);
    final muscleFallback =
        _query.trim().isEmpty &&
        _muscleFilter != null &&
        compatible.isNotEmpty &&
        _filtered(compatible).isEmpty;
    final filtered = muscleFallback
        ? _filtered(compatible, ignoreMuscle: true)
        : _filtered(compatible);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final height = (screenHeight * 0.85 - viewInsets).clamp(
      280.0,
      screenHeight,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
              child: _buildSearchField(),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (compatible.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
                child: _buildFilterChips(compatible),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2l,
                AppSpacing.md,
                AppSpacing.x2l,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    filtered.length == 1
                        ? '1 exercise'
                        : '${filtered.length} exercises',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  if (muscleFallback) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'No ${_muscleFilter!.toLowerCase()} exercises match '
                      'your equipment. Showing all compatible exercises.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
                child: provider.isLoading && provider.exercises.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.lime),
                      )
                    : _buildList(
                        filtered,
                        emptyMessage: compatible.isEmpty
                            ? 'No exercises match your equipment.'
                            : null,
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2l,
                AppSpacing.xl,
                AppSpacing.x2l,
                AppSpacing.x2l,
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: AppButton(
                label: _primaryLabel,
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () => _submit(provider.exercises),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.exercise,
    required this.selected,
    required this.multiSelect,
    required this.onTap,
  });

  final Exercise exercise;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.md);
    final iconAsset = selected ? AppIcons.check : AppIcons.circle;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${exercise.name}, ${exercise.primaryMuscle}, ${exercise.equipment}',
      child: Material(
        color: selected ? AppColors.limeSoft : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.limeBorder45 : AppColors.line,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
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
                const SizedBox(width: AppSpacing.md),
                AppIcon(
                  asset: iconAsset,
                  size: 20,
                  color: selected ? AppColors.lime : AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
