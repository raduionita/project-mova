import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../common/date_keys.dart';
import '../models/personal_record.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import '../services/storage_service.dart';

/// Owns read-only progress data derived from history and PRs.
class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._storage);

  final StorageService _storage;

  List<WorkoutSession> _recent = const <WorkoutSession>[];
  Map<String, PersonalRecord> _prs = const <String, PersonalRecord>{};
  int _streak = 0;
  Map<String, double> _weeklyVolume = const <String, double>{};
  int? _strengthScore;
  String? _scoreReason;
  bool _isLoading = false;
  String? _error;

  List<WorkoutSession> get recent => _recent;
  Map<String, PersonalRecord> get prs => _prs;
  int get streak => _streak;
  Map<String, double> get weeklyVolume => _weeklyVolume;
  int? get strengthScore => _strengthScore;
  String? get scoreReason => _scoreReason;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final workouts = _storage.readList<WorkoutSession>(
        kWorkoutsKey,
        WorkoutSession.fromJson,
      );
      final profile = _storage.readObject<UserProfile>(
        kProfileKey,
        UserProfile.fromJson,
      );
      _prs = _storage.readMap<PersonalRecord>(kPrsKey, PersonalRecord.fromJson);
      _recent = _sorted(workouts).take(10).toList(growable: false);
      _streak = _computeStreak(workouts);
      _weeklyVolume = _computeWeeklyVolume(workouts);
      _computeStrengthScore(workouts, profile);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recompute() => load();

  /// Persists records only when they beat the stored best for their exercise.
  Future<bool> saveRecords(List<PersonalRecord> records) async {
    final next = Map<String, PersonalRecord>.from(_prs);
    var changed = false;
    for (final record in records) {
      final current = next[record.exerciseId];
      if (current == null || record.bestE1rmKg > current.bestE1rmKg) {
        next[record.exerciseId] = record;
        changed = true;
      }
    }
    if (!changed) {
      return true;
    }
    final saved = await _storage.writeMap(
      kPrsKey,
      <String, Map<String, dynamic>>{
        for (final entry in next.entries) entry.key: entry.value.toJson(),
      },
    );
    if (!saved) {
      _error = 'Could not save personal records.';
      notifyListeners();
      return false;
    }
    _prs = Map<String, PersonalRecord>.unmodifiable(next);
    _error = null;
    notifyListeners();
    return true;
  }

  int _computeStreak(List<WorkoutSession> workouts) {
    final days = <String>{
      for (final workout in workouts)
        if (workout.status == SessionStatus.completed)
          DateKeys.dayKey(workout.completedAt ?? workout.startedAt),
    };
    final today = DateTime.now();
    var streak = 0;
    while (true) {
      final key = DateKeys.dayKey(
        DateTime(today.year, today.month, today.day - streak),
      );
      if (!days.contains(key)) {
        break;
      }
      streak++;
    }
    return streak;
  }

  Map<String, double> _computeWeeklyVolume(List<WorkoutSession> workouts) {
    final today = DateTime.now();
    final window = <String>{
      for (var offset = 0; offset < 7; offset++)
        DateKeys.dayKey(DateTime(today.year, today.month, today.day - offset)),
    };
    final volume = <String, double>{};
    for (final workout in workouts) {
      if (workout.status != SessionStatus.completed) {
        continue;
      }
      final key = DateKeys.dayKey(workout.completedAt ?? workout.startedAt);
      if (!window.contains(key)) {
        continue;
      }
      var total = 0.0;
      for (final exercise in workout.exercises) {
        for (final set in exercise.sets) {
          if (set.completed && !set.isWarmup) {
            total += set.weightKg * set.reps;
          }
        }
      }
      volume[key] = (volume[key] ?? 0) + total;
    }
    return volume;
  }

  void _computeStrengthScore(
    List<WorkoutSession> workouts,
    UserProfile? profile,
  ) {
    final bodyWeight = profile?.bodyWeightKg ?? 0;
    if (workouts.length < 3 || _prs.length < 2 || bodyWeight <= 0) {
      _strengthScore = null;
      _scoreReason = 'Not enough training history for a strength score.';
      return;
    }
    final average =
        _prs.values
            .map((record) => record.bestE1rmKg / bodyWeight * 100)
            .reduce((a, b) => a + b) /
        _prs.length;
    _strengthScore = average.round();
    _scoreReason = null;
  }

  List<WorkoutSession> _sorted(List<WorkoutSession> workouts) {
    final next = <WorkoutSession>[...workouts];
    next.sort((a, b) {
      final aDate = a.completedAt ?? a.startedAt;
      final bDate = b.completedAt ?? b.startedAt;
      return bDate.compareTo(aDate);
    });
    return next;
  }
}
