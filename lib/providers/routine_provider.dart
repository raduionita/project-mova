import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/routine.dart';
import '../models/routine_exercise.dart';
import '../services/storage_service.dart';

/// Owns the saved routines stored at [kRoutinesKey].
class RoutineProvider extends ChangeNotifier {
  RoutineProvider(this._storage);

  final StorageService _storage;

  List<Routine> _routines = const <Routine>[];
  bool _isLoading = false;
  String? _error;

  List<Routine> get routines => _routines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _routines = _storage.readList<Routine>(kRoutinesKey, Routine.fromJson);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Routine routine) async {
    final next = <Routine>[..._routines];
    final index = next.indexWhere((item) => item.id == routine.id);
    if (index == -1) {
      next.add(routine);
    } else {
      next[index] = routine;
    }
    return _write(next);
  }

  Future<bool> delete(String routineId) {
    final next = _routines
        .where((routine) => routine.id != routineId)
        .toList(growable: false);
    return _write(next);
  }

  /// Appends an exercise with default sets to a saved routine.
  Future<bool> addExercise({
    required String routineId,
    required String exerciseId,
  }) {
    final routine = _routines.where((item) => item.id == routineId).firstOrNull;
    if (routine == null) {
      _error = 'Routine not found.';
      notifyListeners();
      return Future<bool>.value(false);
    }
    if (routine.exercises.any((item) => item.exerciseId == exerciseId)) {
      return Future<bool>.value(true);
    }
    if (routine.exercises.length >= 20) {
      _error = 'A routine can hold at most 20 exercises.';
      notifyListeners();
      return Future<bool>.value(false);
    }
    final next = <RoutineExercise>[
      ...routine.exercises,
      RoutineExercise(
        exerciseId: exerciseId,
        sets: 3,
        repsLow: 8,
        repsHigh: 12,
        restSeconds: 90,
        order: routine.exercises.length,
      ),
    ];
    return save(
      routine.copyWith(exercises: next, updatedAt: DateTime.now()),
    );
  }

  Future<bool> reorder({
    required String routineId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final routine = _routines.where((item) => item.id == routineId).firstOrNull;
    if (routine == null ||
        oldIndex < 0 ||
        oldIndex >= routine.exercises.length ||
        newIndex < 0 ||
        newIndex >= routine.exercises.length) {
      _error = 'Could not reorder routine exercises.';
      notifyListeners();
      return false;
    }
    final exercises = <RoutineExercise>[...routine.exercises];
    final moved = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, moved);
    final reordered = <RoutineExercise>[
      for (var index = 0; index < exercises.length; index++)
        exercises[index].copyWith(order: index),
    ];
    return save(
      routine.copyWith(exercises: reordered, updatedAt: DateTime.now()),
    );
  }

  Future<bool> _write(List<Routine> next) async {
    _error = null;
    final saved = await _storage.writeList(
      kRoutinesKey,
      next.map((routine) => routine.toJson()).toList(growable: false),
    );
    if (!saved) {
      _error = 'Could not save routines.';
      notifyListeners();
      return false;
    }
    _routines = List<Routine>.unmodifiable(next);
    notifyListeners();
    return true;
  }
}
