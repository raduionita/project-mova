import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/plan_day.dart';
import '../models/plan_exercise.dart';
import '../models/progression_suggestion.dart';
import '../models/routine.dart';
import '../models/routine_exercise.dart';
import '../models/session_exercise.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../services/clock.dart';
import '../services/id_service.dart';
import '../services/storage_service.dart';

/// Owns the active workout session stored at [kActiveSessionKey].
class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider(this._storage, {Clock? clock, IdService? idService})
    : _clock = clock ?? const SystemClock(),
      _idService = idService ?? IdService();

  final StorageService _storage;
  final Clock _clock;
  final IdService _idService;

  WorkoutSession? _activeSession;
  bool _isLoading = false;
  String? _error;

  WorkoutSession? get activeSession => _activeSession;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadActive() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _activeSession = _storage.readObject<WorkoutSession>(
        kActiveSessionKey,
        WorkoutSession.fromJson,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startFromPlanDay(
    PlanDay planDay, {
    ProgressionSuggestion? Function(
      String exerciseId,
      int repsLow,
      int repsHigh,
    )?
    suggest,
  }) {
    final exercises = <PlanExercise>[...planDay.exercises]
      ..sort((a, b) => a.order.compareTo(b.order));
    return _start(
      WorkoutSession(
        id: _idService.next(),
        name: planDay.name,
        source: SessionSource.plan,
        planDayId: planDay.id,
        startedAt: _clock.now(),
        status: SessionStatus.active,
        exercises: <SessionExercise>[
          for (var index = 0; index < exercises.length; index++)
            _fromPlanExercise(
              exercises[index],
              index,
              suggest?.call(
                exercises[index].exerciseId,
                exercises[index].repsLow,
                exercises[index].repsHigh,
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> startFromRoutine(
    Routine routine, {
    ProgressionSuggestion? Function(
      String exerciseId,
      int repsLow,
      int repsHigh,
    )?
    suggest,
  }) {
    final exercises = <RoutineExercise>[...routine.exercises]
      ..sort((a, b) => a.order.compareTo(b.order));
    return _start(
      WorkoutSession(
        id: _idService.next(),
        name: routine.name,
        source: SessionSource.routine,
        routineId: routine.id,
        startedAt: _clock.now(),
        status: SessionStatus.active,
        exercises: <SessionExercise>[
          for (var index = 0; index < exercises.length; index++)
            _fromRoutineExercise(
              exercises[index],
              index,
              suggest?.call(
                exercises[index].exerciseId,
                exercises[index].repsLow,
                exercises[index].repsHigh,
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> startEmpty() {
    return _start(
      WorkoutSession(
        id: _idService.next(),
        name: 'Empty workout',
        source: SessionSource.empty,
        startedAt: _clock.now(),
        status: SessionStatus.active,
        exercises: const <SessionExercise>[],
      ),
    );
  }

  Future<bool> startWalk() {
    return _start(
      WorkoutSession(
        id: _idService.next(),
        name: 'Walk',
        source: SessionSource.walk,
        startedAt: _clock.now(),
        status: SessionStatus.active,
        exercises: const <SessionExercise>[],
      ),
    );
  }

  Future<bool> addExercise(
    String exerciseId, {
    ProgressionSuggestion? suggestion,
  }) {
    final session = _activeSession;
    if (session == null) {
      return _fail('No active workout.');
    }
    final exercise = SessionExercise(
      id: _idService.next(),
      exerciseId: exerciseId,
      order: session.exercises.length,
      sets: _newSets(3, 8, suggestion: suggestion),
      progression: suggestion,
    );
    return _replace(
      session.copyWith(
        exercises: <SessionExercise>[...session.exercises, exercise],
      ),
    );
  }

  Future<bool> replaceExercise({
    required String exerciseId,
    required String replacementExerciseId,
  }) {
    final session = _activeSession;
    if (session == null) {
      return _fail('No active workout.');
    }
    final index = session.exercises.indexWhere(
      (exercise) => exercise.exerciseId == exerciseId,
    );
    if (index == -1) {
      return _fail('Exercise not found.');
    }
    final current = session.exercises[index];
    final sets = <WorkoutSet>[
      for (var setIndex = 0; setIndex < current.sets.length; setIndex++)
        WorkoutSet(
          id: _idService.next(),
          index: setIndex,
          weightKg: 0,
          reps: current.sets[setIndex].reps,
        ),
    ];
    return _replace(
      session.copyWith(
        exercises: _replaceExercise(
          session.exercises,
          index,
          current.copyWith(
            exerciseId: replacementExerciseId,
            sets: sets,
            progression: null,
          ),
        ),
      ),
    );
  }

  Future<bool> updateSet({
    required String exerciseId,
    required String setId,
    required double weightKg,
    required int reps,
    required bool isWarmup,
  }) {
    return _updateSet(
      exerciseId,
      setId,
      (set) => set.copyWith(weightKg: weightKg, reps: reps, isWarmup: isWarmup),
    );
  }

  Future<bool> completeSet({
    required String exerciseId,
    required String setId,
  }) {
    return _updateSet(
      exerciseId,
      setId,
      (set) => set.copyWith(completed: true, completedAt: _clock.now()),
    );
  }

  Future<bool> uncompleteSet({
    required String exerciseId,
    required String setId,
  }) {
    return _updateSet(
      exerciseId,
      setId,
      (set) => set.copyWith(completed: false, completedAt: null),
    );
  }

  Future<bool> addSet(String exerciseId) {
    final session = _activeSession;
    if (session == null) {
      return _fail('No active workout.');
    }
    final index = session.exercises.indexWhere(
      (exercise) => exercise.exerciseId == exerciseId,
    );
    if (index == -1) {
      return _fail('Exercise not found.');
    }
    final exercise = session.exercises[index];
    final last = exercise.sets.isEmpty ? null : exercise.sets.last;
    final next = exercise.copyWith(
      sets: <WorkoutSet>[
        ...exercise.sets,
        WorkoutSet(
          id: _idService.next(),
          index: exercise.sets.length,
          weightKg: last?.weightKg ?? 0,
          reps: last?.reps ?? 8,
        ),
      ],
    );
    return _replace(
      session.copyWith(
        exercises: _replaceExercise(session.exercises, index, next),
      ),
    );
  }

  Future<bool> removeSet({required String exerciseId, required String setId}) {
    final session = _activeSession;
    if (session == null) {
      return _fail('No active workout.');
    }
    final index = session.exercises.indexWhere(
      (exercise) => exercise.exerciseId == exerciseId,
    );
    if (index == -1) {
      return _fail('Exercise not found.');
    }
    final exercise = session.exercises[index];
    final sets = exercise.sets
        .where((set) => set.id != setId)
        .toList(growable: false);
    final reindexed = <WorkoutSet>[
      for (var setIndex = 0; setIndex < sets.length; setIndex++)
        sets[setIndex].copyWith(index: setIndex),
    ];
    return _replace(
      session.copyWith(
        exercises: _replaceExercise(
          session.exercises,
          index,
          exercise.copyWith(sets: reindexed),
        ),
      ),
    );
  }

  Future<bool> pause() {
    final session = _activeSession;
    if (session == null || session.status != SessionStatus.active) {
      return _fail('No active workout to pause.');
    }
    return _replace(
      session.copyWith(status: SessionStatus.paused, pausedAt: _clock.now()),
    );
  }

  Future<bool> resume() {
    final session = _activeSession;
    if (session == null || session.status != SessionStatus.paused) {
      return _fail('No paused workout to resume.');
    }
    final pausedAt = session.pausedAt;
    final pausedSeconds = pausedAt == null
        ? session.pausedSeconds
        : session.pausedSeconds + _clock.now().difference(pausedAt).inSeconds;
    return _replace(
      session.copyWith(
        status: SessionStatus.active,
        pausedSeconds: pausedSeconds,
        pausedAt: null,
      ),
    );
  }

  Future<WorkoutSession?> finish() async {
    final session = _activeSession;
    if (session == null) {
      _error = 'No active workout to finish.';
      notifyListeners();
      return null;
    }
    final completed = session.copyWith(
      status: SessionStatus.completed,
      completedAt: _clock.now(),
      pausedAt: null,
    );
    if (!await clearActive()) {
      return null;
    }
    return completed;
  }

  /// Clears the persisted active session without producing a completed copy.
  Future<bool> clearActive() async {
    final removed = await _storage.remove(kActiveSessionKey);
    if (!removed) {
      return _fail('Could not clear the active workout.');
    }
    _activeSession = null;
    notifyListeners();
    return true;
  }

  Future<bool> discard() async {
    final removed = await _storage.remove(kActiveSessionKey);
    if (!removed) {
      return _fail('Could not discard the workout.');
    }
    _activeSession = null;
    notifyListeners();
    return true;
  }

  SessionExercise _fromPlanExercise(
    PlanExercise exercise,
    int order,
    ProgressionSuggestion? suggestion,
  ) {
    return SessionExercise(
      id: _idService.next(),
      exerciseId: exercise.exerciseId,
      order: order,
      sets: _newSets(exercise.sets, exercise.repsLow, suggestion: suggestion),
      progression: suggestion,
    );
  }

  SessionExercise _fromRoutineExercise(
    RoutineExercise exercise,
    int order,
    ProgressionSuggestion? suggestion,
  ) {
    return SessionExercise(
      id: _idService.next(),
      exerciseId: exercise.exerciseId,
      order: order,
      sets: _newSets(exercise.sets, exercise.repsLow, suggestion: suggestion),
      progression: suggestion,
    );
  }

  List<WorkoutSet> _newSets(
    int count,
    int reps, {
    ProgressionSuggestion? suggestion,
  }) {
    return <WorkoutSet>[
      for (var index = 0; index < count; index++)
        WorkoutSet(
          id: _idService.next(),
          index: index,
          weightKg: suggestion?.weightKg ?? 0,
          reps: suggestion?.reps ?? reps,
        ),
    ];
  }

  Future<bool> _start(WorkoutSession session) async {
    final saved = await _storage.writeObject(
      kActiveSessionKey,
      session.toJson(),
    );
    if (!saved) {
      return _fail('Could not start workout.');
    }
    _activeSession = session;
    _error = null;
    notifyListeners();
    return true;
  }

  Future<bool> _replace(WorkoutSession session) {
    return _start(session);
  }

  Future<bool> _updateSet(
    String exerciseId,
    String setId,
    WorkoutSet Function(WorkoutSet set) update,
  ) {
    final session = _activeSession;
    if (session == null) {
      return _fail('No active workout.');
    }
    final exerciseIndex = session.exercises.indexWhere(
      (exercise) => exercise.exerciseId == exerciseId,
    );
    if (exerciseIndex == -1) {
      return _fail('Exercise not found.');
    }
    final exercise = session.exercises[exerciseIndex];
    final setIndex = exercise.sets.indexWhere((set) => set.id == setId);
    if (setIndex == -1) {
      return _fail('Set not found.');
    }
    final sets = <WorkoutSet>[...exercise.sets];
    sets[setIndex] = update(sets[setIndex]);
    return _replace(
      session.copyWith(
        exercises: _replaceExercise(
          session.exercises,
          exerciseIndex,
          exercise.copyWith(sets: sets),
        ),
      ),
    );
  }

  List<SessionExercise> _replaceExercise(
    List<SessionExercise> exercises,
    int index,
    SessionExercise replacement,
  ) {
    final next = <SessionExercise>[...exercises];
    next[index] = replacement;
    return next;
  }

  Future<bool> _fail(String message) {
    _error = message;
    notifyListeners();
    return Future<bool>.value(false);
  }
}
