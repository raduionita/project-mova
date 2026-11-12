import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_coordinator.dart';
import '../../models/session_exercise.dart';
import '../../models/unit_preferences.dart';
import '../../models/workout_session.dart';
import '../../models/workout_set.dart';
import '../../navigation/routes.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/clock.dart';
import '../../services/haptics_service.dart';
import '../../services/keep_awake_service.dart';
import '../../services/unit_conversion_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/exercise_notes_sheet.dart';
import '../../widgets/exercise_picker_sheet.dart';
import '../../widgets/focus_sheet.dart';
import '../../widgets/numeric_input_sheet.dart';
import '../../widgets/plate_calculator_sheet.dart';
import '../../widgets/rest_timer_banner.dart';
import '../../widgets/session_stats_bar.dart';
import '../../widgets/set_row.dart';
import '../../widgets/workout_interruption_sheet.dart';
import '../summary/summary_screen.dart';

/// Full-screen live workout logger with rest, pause, and finish.
class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key, this.clock, this.keepAwake, this.haptics});

  final Clock? clock;
  final KeepAwakeService? keepAwake;
  final HapticsService? haptics;

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen>
    with WidgetsBindingObserver {
  static const UnitConversionService _units = UnitConversionService();

  late final Clock _clock = widget.clock ?? const SystemClock();
  late final KeepAwakeService _keepAwake =
      widget.keepAwake ?? const KeepAwakeService();
  late final HapticsService _haptics = widget.haptics ?? const HapticsService();
  int _selectedIndex = 0;
  DateTime? _restEndsAt;
  int _restTotalSeconds = 0;
  bool _finishing = false;
  bool _keepAwakeOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_releaseKeepAwake());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (mounted) {
          setState(() {});
        }
        unawaited(_syncKeepAwake());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_releaseKeepAwake());
    }
  }

  Future<void> _syncKeepAwake() async {
    if (!mounted) {
      return;
    }
    final shouldStayAwake =
        context.read<WorkoutProvider>().activeSession?.status ==
        SessionStatus.active;
    if (shouldStayAwake == _keepAwakeOn) {
      return;
    }
    _keepAwakeOn = shouldStayAwake;
    if (shouldStayAwake) {
      await _keepAwake.enable();
    } else {
      await _keepAwake.disable();
    }
  }

  Future<void> _releaseKeepAwake() async {
    if (!_keepAwakeOn) {
      return;
    }
    _keepAwakeOn = false;
    await _keepAwake.disable();
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final history = context.read<HistoryProvider>();
    final exercises = context.read<ExerciseProvider>();
    await Future.wait<void>(<Future<void>>[
      if (history.workouts.isEmpty && !history.isLoading) history.load(),
      if (exercises.exercises.isEmpty && !exercises.isLoading) exercises.load(),
    ]);
    if (!mounted) {
      return;
    }
    final session = context.read<WorkoutProvider>().activeSession;
    if (session != null && session.exercises.isNotEmpty) {
      final firstOpen = session.exercises.indexWhere(
        (exercise) => exercise.sets.any((set) => !set.completed),
      );
      setState(() {
        _selectedIndex = firstOpen == -1 ? 0 : firstOpen;
      });
    }
    await _syncKeepAwake();
    await _maybeShowFocus();
  }

  Future<void> _maybeShowFocus() async {
    final workout = context.read<WorkoutProvider>();
    final session = workout.activeSession;
    if (session == null ||
        session.source != SessionSource.empty ||
        session.exercises.isNotEmpty ||
        session.focusPromptShown) {
      return;
    }
    await showFocusSheet(context);
    await workout.markFocusPromptShown();
  }

  WorkoutSet? _previousSet(
    HistoryProvider history,
    String exerciseId,
    int index,
  ) {
    for (final workout in history.workouts) {
      for (final exercise in workout.exercises) {
        if (exercise.exerciseId != exerciseId) {
          continue;
        }
        for (final set in exercise.sets) {
          if (set.index == index && set.completed) {
            return set;
          }
        }
      }
    }
    return null;
  }

  Future<void> _editWeight(SessionExercise exercise, WorkoutSet set) async {
    final unit = context
        .read<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    final displayWeight = unit == WeightUnit.kg
        ? set.weightKg
        : _units.kgToLb(set.weightKg);
    final value = await showNumericInputSheet(
      context,
      title: 'Edit weight',
      label: 'Weight (${_units.weightLabel(unit)})',
      initialValue: displayWeight,
      allowDecimal: true,
      max: 500,
      helperText: 'Logged in ${_units.weightLabel(unit)}.',
    );
    if (value == null || !mounted) {
      return;
    }
    final weightKg = _units.roundInputKg(
      unit == WeightUnit.kg ? value : _units.lbToKg(value),
    );
    await _updateSet(exercise, set, weightKg: weightKg, reps: set.reps);
  }

  Future<void> _editReps(SessionExercise exercise, WorkoutSet set) async {
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
    await _updateSet(
      exercise,
      set,
      weightKg: set.weightKg,
      reps: value.round(),
    );
  }

  Future<void> _updateSet(
    SessionExercise exercise,
    WorkoutSet set, {
    required double weightKg,
    required int reps,
  }) async {
    final workout = context.read<WorkoutProvider>();
    final savedSet = await workout.updateSet(
      exerciseId: exercise.exerciseId,
      setId: set.id,
      weightKg: weightKg,
      reps: reps,
      isWarmup: set.isWarmup,
    );
    if (!savedSet && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not update the set.')),
      );
    }
  }

  Future<void> _toggleComplete(SessionExercise exercise, WorkoutSet set) async {
    final workout = context.read<WorkoutProvider>();
    final saved = set.completed
        ? await workout.uncompleteSet(
            exerciseId: exercise.exerciseId,
            setId: set.id,
          )
        : await workout.completeSet(
            exerciseId: exercise.exerciseId,
            setId: set.id,
          );
    if (!saved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(workout.error ?? 'Could not update the set.')),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (set.completed) {
      setState(() => _restEndsAt = null);
    } else {
      unawaited(_haptics.setCompleted(reduceMotion: _reduceMotion));
      _startRest(exercise);
    }
  }

  /// Reads the platform's reduced-motion preference for supplementary feedback.
  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _startRest(SessionExercise exercise) {
    if (!context.read<SettingsProvider>().settings.restTimerEnabled) {
      if (_restEndsAt != null) {
        setState(() => _restEndsAt = null);
      }
      return;
    }
    final meta = context.read<ExerciseProvider>().byId(exercise.exerciseId);
    final seconds = meta?.isCompound == true ? 120 : 60;
    setState(() {
      _restTotalSeconds = seconds;
      _restEndsAt = _clock.now().add(Duration(seconds: seconds));
    });
  }

  Future<void> _toggleRestTimer(bool enabled) async {
    final settings = context.read<SettingsProvider>();
    final saved = await settings.setRestTimerEnabled(enabled);
    if (!mounted) {
      return;
    }
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            settings.error ?? 'Could not save the rest timer setting.',
          ),
        ),
      );
      return;
    }
    if (!enabled && _restEndsAt != null) {
      setState(() => _restEndsAt = null);
    }
  }

  Future<void> _editNotes(SessionExercise exercise) async {
    final name =
        context.read<ExerciseProvider>().byId(exercise.exerciseId)?.name ??
        exercise.exerciseId;
    final notes = await showExerciseNotesSheet(
      context,
      exerciseName: name,
      initialNotes: exercise.notes,
    );
    if (notes == null || !mounted) {
      return;
    }
    final workout = context.read<WorkoutProvider>();
    final saved = await workout.setExerciseNotes(
      exerciseId: exercise.exerciseId,
      notes: notes,
    );
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not save the note.')),
      );
    }
  }

  void _skipRest() {
    if (_restEndsAt == null) {
      return;
    }
    setState(() => _restEndsAt = null);
  }

  void _finishRest() {
    if (_restEndsAt == null) {
      return;
    }
    unawaited(_haptics.restFinished(reduceMotion: _reduceMotion));
    setState(() => _restEndsAt = null);
  }

  Future<void> _toggleWarmup(SessionExercise exercise, WorkoutSet set) async {
    final workout = context.read<WorkoutProvider>();
    final saved = await workout.updateSet(
      exerciseId: exercise.exerciseId,
      setId: set.id,
      weightKg: set.weightKg,
      reps: set.reps,
      isWarmup: !set.isWarmup,
    );
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not update the set.')),
      );
    }
  }

  Future<void> _removeSet(SessionExercise exercise, WorkoutSet set) async {
    final workout = context.read<WorkoutProvider>();
    final removed = await workout.removeSet(
      exerciseId: exercise.exerciseId,
      setId: set.id,
    );
    if (!removed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not remove the set.')),
      );
    }
  }

  Future<void> _addSet(SessionExercise exercise) async {
    final workout = context.read<WorkoutProvider>();
    final added = await workout.addSet(exercise.exerciseId);
    if (!added && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not add a set.')),
      );
    }
  }

  Future<void> _addExercises() async {
    final result = await showExercisePicker(
      context,
      mode: ExercisePickerMode.session,
      multiSelect: true,
    );
    if (result == null || result.exercises.isEmpty || !mounted) {
      return;
    }
    final workout = context.read<WorkoutProvider>();
    final coordinator = context.read<AppCoordinator>();
    for (final exercise in result.exercises) {
      final added = await coordinator.addExerciseToWorkout(exercise.id);
      if (!added && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(workout.error ?? 'Could not add exercise.')),
        );
        return;
      }
    }
    if (!mounted) {
      return;
    }
    final session = workout.activeSession;
    if (session != null && session.exercises.isNotEmpty) {
      setState(() => _selectedIndex = session.exercises.length - 1);
    }
  }

  Future<void> _swapExercise(SessionExercise exercise) async {
    final library = context.read<ExerciseProvider>();
    final current = library.byId(exercise.exerciseId);
    final result = await showExercisePicker(
      context,
      mode: ExercisePickerMode.session,
      availableEquipment: context
          .read<ProfileProvider>()
          .profile
          ?.availableEquipment,
      excludedExerciseIds: <String>{exercise.exerciseId},
      initialMuscle: current?.primaryMuscle,
      title: 'Swap exercise',
    );
    if (result == null || result.exercises.isEmpty || !mounted) {
      return;
    }
    final replacement = result.exercises.first;
    final completed = exercise.sets.where((set) => set.completed).length;
    if (completed > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.x2l),
            ),
            title: Text(
              'Swap exercise?',
              style: AppTypography.h2.copyWith(color: AppColors.text),
            ),
            content: Text(
              'Your $completed completed '
              '${completed == 1 ? 'set' : 'sets'} will reset. '
              'The new exercise keeps the same number of sets with no weight.',
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
            actions: <Widget>[
              TextButton(
                key: const Key('swap-cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Cancel',
                  style: AppTypography.label.copyWith(color: AppColors.muted),
                ),
              ),
              TextButton(
                key: const Key('swap-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'Replace',
                  style: AppTypography.label.copyWith(color: AppColors.lime),
                ),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }
    final workout = context.read<WorkoutProvider>();
    final swapped = await workout.replaceExercise(
      exerciseId: exercise.exerciseId,
      replacementExerciseId: replacement.id,
    );
    if (!swapped && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not swap exercise.')),
      );
    }
  }

  Future<void> _openPlateCalculator(SessionExercise exercise) async {
    final settings = context.read<SettingsProvider>();
    final unit = settings.settings.unitPreferences.weightUnit;
    final session = context.read<WorkoutProvider>().activeSession;
    final current = session?.exercises
        .where((item) => item.exerciseId == exercise.exerciseId)
        .firstOrNull;
    final ordered = current == null
        ? const <WorkoutSet>[]
        : (<WorkoutSet>[...current.sets]
            ..sort((a, b) => a.index.compareTo(b.index)));
    final active =
        ordered.where((set) => !set.completed).firstOrNull ??
        ordered.lastOrNull;
    final weightKg = active?.weightKg ?? 0;
    final target = weightKg > 0 && unit == WeightUnit.lb
        ? _units.kgToLb(weightKg)
        : weightKg;
    final name =
        context.read<ExerciseProvider>().byId(exercise.exerciseId)?.name ??
        exercise.exerciseId;
    await showPlateCalculatorSheet(
      context,
      unit: unit,
      exerciseName: name,
      targetWeight: target,
    );
  }

  String? _progressionLabel(SessionExercise exercise, WeightUnit weightUnit) {
    final suggestion = exercise.progression;
    if (suggestion == null) {
      return null;
    }
    if (suggestion.isIncrease) {
      final difference = suggestion.weightKg - suggestion.previousWeightKg;
      return 'Progressive overload: +'
          '${_units.displayWeight(difference, weightUnit)} from last workout';
    }
    return 'Repeat last weight: '
        '${_units.displayWeight(suggestion.weightKg, weightUnit)}';
  }

  int _completedSets(WorkoutSession session) {
    var count = 0;
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        if (set.completed) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> _finishWorkout() async {
    if (_finishing) {
      return;
    }
    setState(() => _finishing = true);
    final result = await context.read<AppCoordinator>().finishWorkout();
    if (!mounted) {
      return;
    }
    setState(() => _finishing = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not finish the workout.')),
      );
      return;
    }
    await _releaseKeepAwake();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      Routes.summary,
      arguments: SummaryArgs(session: result.session, records: result.records),
    );
  }

  Future<void> _handleInterruption() async {
    final workout = context.read<WorkoutProvider>();
    final session = workout.activeSession;
    if (session == null) {
      Navigator.of(context).maybePop();
      return;
    }
    final action = await showWorkoutInterruptionSheet(
      context,
      completedSets: _completedSets(session),
    );
    if (action == null || !mounted) {
      return;
    }
    if (action == WorkoutInterruptionAction.pause) {
      final paused = await workout.pause();
      if (!paused) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(workout.error ?? 'Could not pause the workout.'),
            ),
          );
        }
        return;
      }
    } else {
      final discarded = await workout.discard();
      if (!discarded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(workout.error ?? 'Could not discard the workout.'),
            ),
          );
        }
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => _restEndsAt = null);
    Navigator.of(context).pushReplacementNamed(Routes.today);
  }

  Widget _buildHeader(WorkoutSession session, SettingsProvider settings) {
    final restEnabled = settings.settings.restTimerEnabled;
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: 'Close workout',
          onPressed: _handleInterruption,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(
            width: AppSpacing.x5l,
            height: AppSpacing.x5l,
          ),
          icon: const AppIcon(
            asset: AppIcons.close,
            size: AppSpacing.x3l,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            session.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title.copyWith(color: AppColors.text),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        IconButton(
          key: const Key('logger-rest-toggle'),
          tooltip: restEnabled ? 'Rest timer on' : 'Rest timer off',
          onPressed: () => _toggleRestTimer(!restEnabled),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(
            width: AppSpacing.x5l,
            height: AppSpacing.x5l,
          ),
          icon: AppIcon(
            asset: AppIcons.clock,
            size: AppSpacing.x3l,
            color: restEnabled ? AppColors.lime : AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseChips(WorkoutSession session, ExerciseProvider library) {
    if (session.exercises.length < 2) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: AppSpacing.x5l,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: session.exercises.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final exercise = session.exercises[index];
          final name =
              library.byId(exercise.exerciseId)?.name ?? exercise.exerciseId;
          return AppChip(
            label: name,
            selected: index == _selectedIndex,
            onTap: () => setState(() => _selectedIndex = index),
          );
        },
      ),
    );
  }

  Widget _buildSetHeader(String unitLabel) {
    final style = AppTypography.micro.copyWith(color: AppColors.tabInactive);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: AppSpacing.x5l - AppSpacing.xs,
            child: Text('SET', style: style),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(flex: 3, child: Text('PREV', style: style)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Center(
              child: Text('${unitLabel.toUpperCase()} × REPS', style: style),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildExercise(
    SessionExercise exercise,
    int selectedIndex,
    WorkoutSession session,
    ExerciseProvider library,
    HistoryProvider history,
    String unitLabel,
    WeightUnit weightUnit,
  ) {
    final name = library.byId(exercise.exerciseId)?.name ?? exercise.exerciseId;
    final ordered = <WorkoutSet>[...exercise.sets]
      ..sort((a, b) => a.index.compareTo(b.index));
    final activeIndex = ordered.indexWhere((set) => !set.completed);
    final progression = _progressionLabel(exercise, weightUnit);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h1.copyWith(color: AppColors.text),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              key: const Key('logger-exercise-notes'),
              tooltip: exercise.notes.isEmpty ? 'Add note' : 'Edit note',
              onPressed: () => _editNotes(exercise),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.x5l,
                height: AppSpacing.x5l,
              ),
              icon: AppIcon(
                asset: AppIcons.document,
                size: AppSpacing.x3l,
                color: exercise.notes.isEmpty
                    ? AppColors.muted
                    : AppColors.lime,
              ),
            ),
            IconButton(
              key: const Key('logger-swap-exercise'),
              tooltip: 'Swap exercise',
              onPressed: () => _swapExercise(exercise),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.x5l,
                height: AppSpacing.x5l,
              ),
              icon: const AppIcon(
                asset: AppIcons.swap,
                size: AppSpacing.x3l,
                color: AppColors.muted,
              ),
            ),
            IconButton(
              key: const Key('logger-plate-calculator'),
              tooltip: 'Plate calculator',
              onPressed: () => _openPlateCalculator(exercise),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.x5l,
                height: AppSpacing.x5l,
              ),
              icon: const AppIcon(
                asset: AppIcons.calculator,
                size: AppSpacing.x3l,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${selectedIndex + 1} of ${session.exercises.length} · '
          '${ordered.length} sets',
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
        if (exercise.notes.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            exercise.notes,
            key: const Key('logger-exercise-note'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
        if (progression != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            progression,
            key: const Key('logger-progression-hint'),
            style: AppTypography.caption.copyWith(
              color: exercise.progression?.isIncrease ?? false
                  ? AppColors.lime
                  : AppColors.muted,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x3l),
        _buildSetHeader(unitLabel),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < ordered.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: SetRow(
              set: ordered[index],
              previous: _previousSet(
                history,
                exercise.exerciseId,
                ordered[index].index,
              ),
              unitLabel: unitLabel,
              weightUnit: weightUnit,
              active: index == activeIndex,
              onEditWeight: () => _editWeight(exercise, ordered[index]),
              onEditReps: () => _editReps(exercise, ordered[index]),
              onToggleComplete: () => _toggleComplete(exercise, ordered[index]),
              onToggleWarmup: () => _toggleWarmup(exercise, ordered[index]),
              onRemove: () => _removeSet(exercise, ordered[index]),
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: 'Add set',
          variant: AppButtonVariant.ghost,
          assetIcon: AppIcons.plus,
          onPressed: () => _addSet(exercise),
        ),
      ],
    );
  }

  Widget _buildUpNext(WorkoutSession session, ExerciseProvider library) {
    if (_selectedIndex >= session.exercises.length - 1) {
      return const SizedBox.shrink();
    }
    final next = session.exercises[_selectedIndex + 1];
    final name = library.byId(next.exerciseId)?.name ?? next.exerciseId;
    return AppCard(
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: 'Up next: ',
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
            TextSpan(
              text: name,
              style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSession(
    WorkoutSession session,
    ExerciseProvider library,
    HistoryProvider history,
    SettingsProvider settings,
  ) {
    final unit = settings.settings.unitPreferences.weightUnit;
    final unitLabel = _units.weightLabel(unit);
    if (session.exercises.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(session, settings),
          const SizedBox(height: AppSpacing.lg),
          SessionStatsBar(session: session, weightUnit: unit, clock: _clock),
          const Expanded(
            child: AppEmptyState(
              assetIcon: AppIcons.dumbbell,
              title: 'No exercises yet',
              message: 'Add an exercise to start logging sets.',
            ),
          ),
          AppButton(
            label: 'Add exercise',
            assetIcon: AppIcons.plus,
            onPressed: _addExercises,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Finish workout',
            variant: AppButtonVariant.ghost,
            isLoading: _finishing,
            onPressed: _finishing ? null : _finishWorkout,
          ),
        ],
      );
    }

    final selectedIndex = _selectedIndex.clamp(0, session.exercises.length - 1);
    final exercise = session.exercises[selectedIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeader(session, settings),
        const SizedBox(height: AppSpacing.lg),
        SessionStatsBar(session: session, weightUnit: unit, clock: _clock),
        if (_restEndsAt != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          RestTimerBanner(
            endsAt: _restEndsAt!,
            totalSeconds: _restTotalSeconds,
            onSkip: _skipRest,
            onFinished: _finishRest,
            clock: _clock,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _buildExerciseChips(session, library),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildExercise(
                  exercise,
                  selectedIndex,
                  session,
                  library,
                  history,
                  unitLabel,
                  unit,
                ),
                const SizedBox(height: AppSpacing.x2l),
                AppButton(
                  label: 'Add exercise',
                  variant: AppButtonVariant.ghost,
                  assetIcon: AppIcons.plus,
                  onPressed: _addExercises,
                ),
                const SizedBox(height: AppSpacing.x3l),
                _buildUpNext(session, library),
                const SizedBox(height: AppSpacing.x3l),
                AppButton(
                  label: 'Finish workout',
                  variant: AppButtonVariant.ghost,
                  isLoading: _finishing,
                  onPressed: _finishing ? null : _finishWorkout,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final library = context.watch<ExerciseProvider>();
    final history = context.watch<HistoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final session = workout.activeSession;
    return PopScope(
      canPop: session == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleInterruption();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2l,
              vertical: AppSpacing.xl,
            ),
            child: session == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Expanded(
                        child: AppEmptyState(
                          assetIcon: AppIcons.play,
                          title: 'No active workout',
                          message:
                              'Start a workout from Today or a saved routine.',
                        ),
                      ),
                      AppButton(
                        label: 'Back to Today',
                        variant: AppButtonVariant.ghost,
                        onPressed: () {
                          Navigator.of(context)
                              .pushReplacementNamed(Routes.today);
                        },
                      ),
                    ],
                  )
                : _buildActiveSession(session, library, history, settings),
          ),
        ),
      ),
    );
  }
}
