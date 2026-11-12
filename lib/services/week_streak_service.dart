import '../common/date_keys.dart';
import '../models/workout_session.dart';

/// Counts consecutive weeks that meet the training target.
///
/// The current week never breaks a streak while it is still in progress. It
/// only joins the streak once the target is reached. Weeks are grouped by the
/// effective week start, so a Sunday-start week is counted as one week.
class WeekStreakService {
  const WeekStreakService();

  /// Completed sessions in the week containing [now].
  int sessionsInWeek(
    List<WorkoutSession> history,
    DateTime now, {
    int weekStart = DateTime.monday,
  }) {
    final counts = _sessionsByWeek(history, weekStart: weekStart);
    return counts[_weekKey(now, weekStart)] ?? 0;
  }

  /// Number of consecutive completed weeks that met [target].
  ///
  /// [target] is clamped to at least one session. When the current week is
  /// partial, the streak keeps the previous completed weeks without adding the
  /// current week yet.
  int currentWeekStreak(
    List<WorkoutSession> history,
    DateTime now, {
    int weekStart = DateTime.monday,
    int target = 3,
    DateTime? profileCreatedAt,
  }) {
    final counts = _sessionsByWeek(history, weekStart: weekStart);
    if (counts.isEmpty) {
      return 0;
    }
    final effectiveTarget = target < 1 ? 1 : target;
    var cursor = DateKeys.weekStart(now, weekStart: weekStart);
    var streak = 0;

    final currentCount = counts[_weekKey(cursor, weekStart)] ?? 0;
    if (currentCount >= effectiveTarget) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 7);
    } else {
      // The current week is still in progress. Look at the last completed week
      // without ending the streak.
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 7);
    }

    final limit = _weekLimit(now, profileCreatedAt, weekStart);
    while (limit < 0 || streak < limit) {
      final count = counts[_weekKey(cursor, weekStart)] ?? 0;
      if (count < effectiveTarget) {
        break;
      }
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 7);
    }
    return streak;
  }

  Map<String, int> _sessionsByWeek(
    List<WorkoutSession> history, {
    required int weekStart,
  }) {
    final counts = <String, int>{};
    for (final workout in history) {
      if (workout.status != SessionStatus.completed) {
        continue;
      }
      final at = workout.completedAt ?? workout.startedAt;
      final key = _weekKey(at, weekStart);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  String _weekKey(DateTime date, int weekStart) {
    return DateKeys.dayKey(DateKeys.weekStart(date, weekStart: weekStart));
  }

  /// Inclusive week count from profile creation through the current week.
  /// A negative value means no cap applies.
  int _weekLimit(DateTime now, DateTime? profileCreatedAt, int weekStart) {
    if (profileCreatedAt == null) {
      return -1;
    }
    final createdWeek = DateKeys.weekStart(
      profileCreatedAt,
      weekStart: weekStart,
    );
    final currentWeek = DateKeys.weekStart(now, weekStart: weekStart);
    final weeks = currentWeek.difference(createdWeek).inDays ~/ 7 + 1;
    return weeks < 1 ? 1 : weeks;
  }
}
