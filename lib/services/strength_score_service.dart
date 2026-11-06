import '../models/personal_record.dart';
import '../models/workout_session.dart';

/// Outcome of a strength score attempt. A null [score] always carries a
/// user-facing [reason] instead of a fabricated number.
class StrengthScoreResult {
  const StrengthScoreResult({this.score, this.reason});

  final int? score;
  final String? reason;

  bool get hasScore => score != null;
}

/// Relative strength score from DESIGN.md section 11.6.
///
/// The score averages the best estimated one rep max of each tracked lift as a
/// percentage of body weight. It is an absolute measure with no percentile or
/// ranking comparison.
class StrengthScoreService {
  const StrengthScoreService();

  static const int minimumSessions = 3;
  static const int minimumTrackedLifts = 2;
  static const List<String> trackedLiftIds = <String>[
    'back-squat',
    'barbell-bench-press',
    'deadlift',
    'overhead-press',
  ];

  static const String missingHistoryReason =
      'Log 3 workouts to unlock a strength score.';
  static const String missingBodyWeightReason =
      'Add your body weight to see your strength score.';
  static const String missingLiftsReason =
      'Train at least 2 of squat, bench press, deadlift, or overhead press.';

  StrengthScoreResult compute({
    required List<WorkoutSession> history,
    required Map<String, PersonalRecord> records,
    required double bodyWeightKg,
  }) {
    final completed = history
        .where((session) => session.status == SessionStatus.completed)
        .length;
    if (completed < minimumSessions) {
      return const StrengthScoreResult(reason: missingHistoryReason);
    }
    if (bodyWeightKg <= 0) {
      return const StrengthScoreResult(reason: missingBodyWeightReason);
    }
    final tracked = records.entries
        .where((entry) => trackedLiftIds.contains(entry.key))
        .toList(growable: false);
    if (tracked.length < minimumTrackedLifts) {
      return const StrengthScoreResult(reason: missingLiftsReason);
    }
    var total = 0.0;
    for (final entry in tracked) {
      total += entry.value.bestE1rmKg / bodyWeightKg * 100;
    }
    return StrengthScoreResult(score: (total / tracked.length).round());
  }
}
