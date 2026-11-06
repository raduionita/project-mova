import 'package:flutter/foundation.dart';

import '../models/exercise.dart';
import '../services/clock.dart';
import '../services/seed_data_service.dart';
import '../services/storage_service.dart';

/// Owns the in-memory exercise library and search query.
class ExerciseProvider extends ChangeNotifier {
  ExerciseProvider(this._storage, this._seedDataService, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  final StorageService _storage;
  final SeedDataService _seedDataService;
  final Clock _clock;

  List<Exercise> _exercises = const <Exercise>[];
  bool _isLoading = false;
  String _query = '';
  String? _muscleFilter;
  String? _error;

  List<Exercise> get exercises => _exercises;
  bool get isLoading => _isLoading;
  String get query => _query;
  String? get muscleFilter => _muscleFilter;
  String? get error => _error;

  List<Exercise> get filtered {
    final query = _query.trim().toLowerCase();
    final muscle = _muscleFilter?.toLowerCase();
    if (query.isEmpty && muscle == null) {
      return _exercises;
    }
    return _exercises
        .where((exercise) {
          if (muscle != null &&
              exercise.primaryMuscle.toLowerCase() != muscle) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return exercise.name.toLowerCase().contains(query) ||
              exercise.primaryMuscle.toLowerCase().contains(query) ||
              exercise.equipment.toLowerCase().contains(query) ||
              exercise.secondaryMuscles.any(
                (secondary) => secondary.toLowerCase().contains(query),
              );
        })
        .toList(growable: false);
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _seedDataService.seedIfNeeded(_storage, _clock.now());
      _exercises = await _seedDataService.loadExercises();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _query = query;
    notifyListeners();
  }

  void clearSearch() {
    if (_query.isEmpty) {
      return;
    }
    _query = '';
    notifyListeners();
  }

  void setMuscleFilter(String? muscle) {
    final normalized = (muscle == null || muscle.trim().isEmpty)
        ? null
        : muscle.trim();
    if (normalized == _muscleFilter) {
      return;
    }
    _muscleFilter = normalized;
    notifyListeners();
  }

  void clearFilters() {
    if (_query.isEmpty && _muscleFilter == null) {
      return;
    }
    _query = '';
    _muscleFilter = null;
    notifyListeners();
  }

  Exercise? byId(String exerciseId) {
    for (final exercise in _exercises) {
      if (exercise.id == exerciseId) {
        return exercise;
      }
    }
    return null;
  }
}
