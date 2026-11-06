import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../common/date_keys.dart';
import '../models/personal_record.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import '../services/clock.dart';
import '../services/streak_service.dart';
import '../services/strength_score_service.dart';
import '../services/storage_service.dart';
import '../services/workout_calculator.dart';

/// Owns read-only progress data derived from history, profile, and PRs.
class ProgressProvider extends ChangeNotifier {
  ProgressProvider(
    this._storage, {
    Clock? clock,
    this.streakService = const StreakService(),
    this.strengthScoreService = const StrengthScoreService(),
  }) : _clock = clock ?? const SystemClock();

  final StorageService _storage;
  final Clock _clock;
  final StreakService streakService;
  final StrengthScoreService strengthScoreService;

  List<WorkoutSession> _workouts = const <WorkoutSession>[];
  List<WorkoutSession> _recent = const <WorkoutSession>[];
  Map<String, PersonalRecord> _prs = const <String, PersonalRecord>{};
  int _streak = 0;
  double _totalVolumeKg = 0;
  Map<String, double> _weeklyVolume = const <String, double>{};
  int? _strengthScore;
  String? _scoreReason;
  bool _isLoading = false;
  String? _error;

  /// All completed workouts, newest first.
  List<WorkoutSession> get workouts => _workouts;

  /// The latest ten workouts for compact previews.
  List<WorkoutSession> get recent => _recent;
  Map<String, PersonalRecord> get prs => _prs;
  int get streak => _streak;
  int get totalWorkouts => _workouts.length;
  double get totalVolumeKg => _totalVolumeKg;
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
      final stored = _storage.readList<WorkoutSession>(
        kWorkoutsKey,
        WorkoutSession.fromJson,
      );
      final workouts = _sorted(
        stored
            .where((session) => session.status == SessionStatus.completed)
            .toList(growable: false),
      );
      final profile = _storage.readObject<UserProfile>(
        kProfileKey,
        UserProfile.fromJson,
      );
      _workouts = workouts;
      _prs = _storage.readMap<PersonalRecord>(kPrsKey, PersonalRecord.fromJson);
      _recent = workouts.take(10).toList(growable: false);
      _totalVolumeKg = _computeTotalVolume(workouts);
      final now = _clock.now();
      _streak = streakService.currentStreak(
        workouts,
        now,
        profileCreatedAt: profile?.createdAt,
      );
      _weeklyVolume = _computeWeeklyVolume(workouts, now);
      _applyStrengthScore(profile);
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
    return _writeRecords(next);
  }

  /// Replaces the stored record map, including clearing it after a deletion.
  Future<bool> replaceRecords(Map<String, PersonalRecord> records) {
    return _writeRecords(records);
  }

  Future<bool> _writeRecords(Map<String, PersonalRecord> records) async {
    final saved = await _storage.writeMap(
      kPrsKey,
      <String, Map<String, dynamic>>{
        for (final entry in records.entries) entry.key: entry.value.toJson(),
      },
    );
    if (!saved) {
      _error = 'Could not save personal records.';
      notifyListeners();
      return false;
    }
    _prs = Map<String, PersonalRecord>.unmodifiable(records);
    _error = null;
    notifyListeners();
    return true;
  }

  void _applyStrengthScore(UserProfile? profile) {
    final result = strengthScoreService.compute(
      history: _workouts,
      records: _prs,
      bodyWeightKg: profile?.bodyWeightKg ?? 0,
    );
    _strengthScore = result.score;
    _scoreReason = result.reason;
  }

  double _computeTotalVolume(List<WorkoutSession> workouts) {
    var total = 0.0;
    for (final workout in workouts) {
      total += WorkoutCalculator.volumeKg(workout.exercises);
    }
    return total;
  }

  Map<String, double> _computeWeeklyVolume(
    List<WorkoutSession> workouts,
    DateTime now,
  ) {
    final window = <String>{
      for (var offset = 0; offset < 7; offset++)
        DateKeys.dayKey(DateTime(now.year, now.month, now.day - offset)),
    };
    final volume = <String, double>{};
    for (final workout in workouts) {
      final key = DateKeys.dayKey(workout.completedAt ?? workout.startedAt);
      if (!window.contains(key)) {
        continue;
      }
      volume[key] =
          (volume[key] ?? 0) + WorkoutCalculator.volumeKg(workout.exercises);
    }
    return volume;
  }

  List<WorkoutSession> _sorted(List<WorkoutSession> workouts) {
    final next = <WorkoutSession>[...workouts];
    next.sort((a, b) {
      final aDate = a.completedAt ?? a.startedAt;
      final bDate = b.completedAt ?? b.startedAt;
      return bDate.compareTo(aDate);
    });
    return List<WorkoutSession>.unmodifiable(next);
  }
}
