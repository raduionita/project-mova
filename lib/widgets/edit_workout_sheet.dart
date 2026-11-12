import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_coordinator.dart';
import '../common/formatters.dart';
import '../models/exercise.dart';
import '../models/session_exercise.dart';
import '../models/unit_preferences.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../providers/exercise_provider.dart';
import '../providers/settings_provider.dart';
import '../services/id_service.dart';
import '../services/unit_conversion_service.dart';
import '../services/workout_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_icon.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/numeric_input_sheet.dart';
import '../widgets/set_row.dart';

/// Opens the editor for a completed workout.
Future<bool?> showEditWorkoutSheet(
  BuildContext context, {
  required WorkoutSession session,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.x3l)),
    ),
    builder: (_) => EditWorkoutSheet(session: session),
  );
}

/// Full-height drawer for editing a completed workout.
class EditWorkoutSheet extends StatefulWidget {
  const EditWorkoutSheet({super.key, required this.session, this.now});

  final WorkoutSession session;
  final DateTime? now;

  @override
  State<EditWorkoutSheet> createState() => _EditWorkoutSheetState();
}

class _EditWorkoutSheetState extends State<EditWorkoutSheet> {
  static const UnitConversionService _units = UnitConversionService();
  final IdService _ids = IdService();

  late final TextEditingController _title = TextEditingController(
    text: widget.session.displayTitle.trim().isEmpty
        ? widget.session.name
        : widget.session.displayTitle,
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.session.notes,
  );
  late List<SessionExercise> _exercises;
  late double? _distanceMeters;
  String? _error;
  bool _saving = false;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _exercises = <SessionExercise>[...widget.session.exercises];
    _distanceMeters = widget.session.distanceMeters;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Exercise? _libraryExercise(String id) {
    return context.read<ExerciseProvider>().byId(id);
  }

  double _displayDistance(double meters, DistanceUnit unit) {
    final km = meters / 1000;
    return unit == DistanceUnit.km ? km : _units.kmToMi(km);
  }

  String _distanceLabel(DistanceUnit unit) => _units.distanceLabel(unit);

  Future<void> _editSetWeight(
    String exerciseId,
    WorkoutSet set,
    WeightUnit unit,
  ) async {
    final initial = unit == WeightUnit.kg
        ? set.weightKg
        : _units.kgToLb(set.weightKg);
    final value = await showNumericInputSheet(
      context,
      title: 'Edit weight',
      label: 'Weight (${_units.weightLabel(unit)})',
      initialValue: initial,
      allowDecimal: true,
      max: 500,
    );
    if (value == null || !mounted) {
      return;
    }
    final kg = _units.roundInputKg(
      unit == WeightUnit.kg ? value : _units.lbToKg(value),
    );
    _replaceSet(exerciseId, set.id, set.copyWith(weightKg: kg));
  }

  Future<void> _editSetReps(String exerciseId, WorkoutSet set) async {
    final value = await showNumericInputSheet(
      context,
      title: 'Edit reps',
      label: 'Reps',
      initialValue: set.reps.toDouble(),
      min: 1,
      max: 100,
    );
    if (value == null || !mounted) {
      return;
    }
    _replaceSet(exerciseId, set.id, set.copyWith(reps: value.round()));
  }

  void _replaceSet(String exerciseId, String setId, WorkoutSet next) {
    setState(() {
      _exercises = <SessionExercise>[
        for (final exercise in _exercises)
          exercise.exerciseId == exerciseId
              ? exercise.copyWith(
                  sets: <WorkoutSet>[
                    for (final set in exercise.sets)
                      set.id == setId ? next : set,
                  ],
                )
              : exercise,
      ];
    });
  }

  void _toggleSet(String exerciseId, WorkoutSet set) {
    _replaceSet(
      exerciseId,
      set.id,
      set.copyWith(
        completed: !set.completed,
        completedAt: !set.completed ? _now : null,
      ),
    );
  }

  void _addSet(String exerciseId) {
    setState(() {
      _exercises = <SessionExercise>[
        for (final exercise in _exercises)
          if (exercise.exerciseId == exerciseId)
            _withAddedSet(exercise)
          else
            exercise,
      ];
    });
  }

  SessionExercise _withAddedSet(SessionExercise exercise) {
    if (exercise.sets.length >= 10) {
      return exercise;
    }
    final last = exercise.sets.isEmpty ? null : exercise.sets.last;
    return exercise.copyWith(
      sets: <WorkoutSet>[
        ...exercise.sets,
        WorkoutSet(
          id: _ids.next(),
          index: exercise.sets.length,
          weightKg: last?.weightKg ?? 0,
          reps: last?.reps ?? 8,
        ),
      ],
    );
  }

  void _removeSet(String exerciseId, WorkoutSet set) {
    setState(() {
      _exercises = <SessionExercise>[
        for (final exercise in _exercises)
          if (exercise.exerciseId == exerciseId)
            exercise.copyWith(
              sets: <WorkoutSet>[
                for (var index = 0;
                    index <
                        exercise.sets
                            .where((entry) => entry.id != set.id)
                            .length;
                    index++)
                  exercise.sets
                      .where((entry) => entry.id != set.id)
                      .elementAt(index)
                      .copyWith(index: index),
              ],
            )
          else
            exercise,
      ];
    });
  }

  void _removeExercise(String exerciseId) {
    setState(() {
      final remaining = _exercises
          .where((exercise) => exercise.exerciseId != exerciseId)
          .toList(growable: false);
      _exercises = <SessionExercise>[
        for (var index = 0; index < remaining.length; index++)
          remaining[index].copyWith(order: index),
      ];
    });
  }

  Future<void> _addExercises() async {
    final selected = await showExercisePicker(
      context,
      mode: ExercisePickerMode.session,
      multiSelect: true,
      excludedExerciseIds: _exercises
          .map((exercise) => exercise.exerciseId)
          .toSet(),
      title: 'Add exercise',
    );
    if (selected == null || selected.exercises.isEmpty || !mounted) {
      return;
    }
    setState(() {
      for (final exercise in selected.exercises) {
        if (_exercises.length >= 20) {
          break;
        }
        _exercises = <SessionExercise>[
          ..._exercises,
          _newSessionExercise(exercise),
        ];
      }
    });
  }

  SessionExercise _newSessionExercise(Exercise exercise) {
    return SessionExercise(
      id: _ids.next(),
      exerciseId: exercise.id,
      order: _exercises.length,
      sets: <WorkoutSet>[
        for (var index = 0; index < 3; index++)
          WorkoutSet(id: _ids.next(), index: index, weightKg: 0, reps: 8),
      ],
      primaryMuscle: exercise.primaryMuscle,
      secondaryMuscles: exercise.secondaryMuscles,
    );
  }

  Future<void> _editDistance(DistanceUnit unit) async {
    final meters = _distanceMeters ?? 0;
    final value = await showNumericInputSheet(
      context,
      title: 'Edit distance',
      label: 'Distance (${_distanceLabel(unit)})',
      initialValue: _displayDistance(meters, unit),
      allowDecimal: true,
      max: 1000,
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() {
      final km = unit == DistanceUnit.km ? value : _units.miToKm(value);
      _distanceMeters = km <= 0 ? null : km * 1000;
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Name this workout.');
      return;
    }
    final isStrength =
        widget.session.source != SessionSource.run &&
        widget.session.source != SessionSource.walk;
    if (isStrength && _exercises.isEmpty) {
      setState(() => _error = 'Add at least one exercise.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final updated = widget.session.copyWith(
      name: title,
      displayTitle: title,
      notes: _notes.text.trim(),
      exercises: <SessionExercise>[
        for (var index = 0; index < _exercises.length; index++)
          _exercises[index].copyWith(order: index),
      ],
      distanceMeters: _distanceMeters,
    );
    final saved = await context
        .read<AppCoordinator>()
        .updateCompletedWorkout(updated);
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() {
        _saving = false;
        _error = 'Could not save changes.';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  Widget _buildHeader() {
    final date = widget.session.completedAt ?? widget.session.startedAt;
    final seconds = WorkoutCalculator.sessionDurationSeconds(
      widget.session,
      _now,
    );
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Edit workout',
                style: AppTypography.h2.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${formatDetailDate(date)} · ${widget.session.sourceLabel} · '
                '${formatDuration(seconds)}',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('edit-workout-close'),
          tooltip: 'Close',
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const AppIcon(asset: AppIcons.close, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      key: const Key('edit-workout-title'),
      controller: _title,
      enabled: !_saving,
      textCapitalization: TextCapitalization.sentences,
      style: AppTypography.body.copyWith(color: AppColors.text),
      decoration: InputDecoration(
        labelText: 'Workout name',
        labelStyle: AppTypography.caption.copyWith(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextField(
      key: const Key('edit-workout-notes'),
      controller: _notes,
      enabled: !_saving,
      minLines: 2,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      style: AppTypography.body.copyWith(color: AppColors.text),
      decoration: InputDecoration(
        labelText: 'Notes',
        labelStyle: AppTypography.caption.copyWith(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }

  Widget _buildRunFields(DistanceUnit unit) {
    final meters = _distanceMeters;
    return AppCard(
      key: const Key('edit-workout-distance'),
      onTap: _saving ? null : () => _editDistance(unit),
      child: Row(
        children: <Widget>[
          const AppIcon(asset: AppIcons.run, color: AppColors.blue, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Distance',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  meters == null || meters <= 0
                      ? 'Add distance'
                      : _units.displayDistance(meters / 1000, unit),
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          const AppIcon(
            asset: AppIcons.chevronRight,
            size: 18,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    SessionExercise exercise,
    WeightUnit weightUnit,
  ) {
    final details = _libraryExercise(exercise.exerciseId);
    final name = details?.name ?? exercise.exerciseId;
    return AppCard(
      key: Key('edit-workout-exercise-${exercise.id}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              IconButton(
                key: Key('edit-workout-remove-exercise-${exercise.id}'),
                tooltip: 'Remove $name',
                visualDensity: VisualDensity.compact,
                onPressed: _saving
                    ? null
                    : () => _removeExercise(exercise.exerciseId),
                icon: const AppIcon(
                  asset: AppIcons.close,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final set in exercise.sets) ...<Widget>[
            SetRow(
              set: set,
              unitLabel: _units.weightLabel(weightUnit),
              weightUnit: weightUnit,
              onEditWeight: _saving
                  ? null
                  : () => _editSetWeight(exercise.exerciseId, set, weightUnit),
              onEditReps: _saving
                  ? null
                  : () => _editSetReps(exercise.exerciseId, set),
              onToggleComplete: _saving
                  ? null
                  : () => _toggleSet(exercise.exerciseId, set),
              onRemove: _saving
                  ? null
                  : () => _removeSet(exercise.exerciseId, set),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: Key('edit-workout-add-set-${exercise.id}'),
              onPressed: _saving || exercise.sets.length >= 10
                  ? null
                  : () => _addSet(exercise.exerciseId),
              icon: const AppIcon(
                asset: AppIcons.plus,
                size: 16,
                color: AppColors.lime,
              ),
              label: const Text('Add set'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBody(WeightUnit weightUnit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final exercise in _exercises) ...<Widget>[
          _buildExerciseCard(exercise, weightUnit),
          const SizedBox(height: AppSpacing.md),
        ],
        OutlinedButton.icon(
          key: const Key('edit-workout-add-exercise'),
          onPressed: _saving ? null : _addExercises,
          icon: const AppIcon(
            asset: AppIcons.plus,
            size: 18,
            color: AppColors.lime,
          ),
          label: const Text('Add exercise'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.lime,
            side: const BorderSide(color: AppColors.line),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final weightUnit = settings.unitPreferences.weightUnit;
    final distanceUnit = settings.unitPreferences.distanceUnit;
    final isRun = widget.session.source == SessionSource.run;
    final height = MediaQuery.sizeOf(context).height * 0.92;
    return SizedBox(
      key: const Key('edit-workout-sheet'),
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x2l,
          AppSpacing.xl,
          AppSpacing.x2l,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildTitleField(),
                    const SizedBox(height: AppSpacing.md),
                    if (isRun) ...<Widget>[
                      _buildRunFields(distanceUnit),
                      const SizedBox(height: AppSpacing.md),
                    ] else ...<Widget>[
                      _buildStrengthBody(weightUnit),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildNotesField(),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _error!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('edit-workout-save'),
              label: _saving ? 'Saving...' : 'Save changes',
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              key: const Key('edit-workout-cancel'),
              onPressed: _saving ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
