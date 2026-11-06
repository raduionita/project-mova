import '../common/date_keys.dart';
import '../models/workout_session.dart';

/// Counts consecutive active calendar days from completed sessions.
///
/// A day counts when at least one completed workout or walk lands on it in the
/// device timezone. A missing day resets the streak to zero, and the streak can
/// never exceed the days since the profile was created.
class StreakService {
  const StreakService();

  int currentStreak(
    List<WorkoutSession> history,
    DateTime now, {
    DateTime? profileCreatedAt,
  }) {
    final days = <String>{
      for (final workout in history)
        if (workout.status == SessionStatus.completed)
          DateKeys.dayKey(workout.completedAt ?? workout.startedAt),
    };
    if (days.isEmpty) {
      return 0;
    }

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    DateTime cursor;
    if (days.contains(DateKeys.dayKey(today))) {
      cursor = today;
    } else if (days.contains(DateKeys.dayKey(yesterday))) {
      cursor = yesterday;
    } else {
      return 0;
    }

    final limit = _dayLimit(today, profileCreatedAt);
    var streak = 0;
    while (limit < 0 || streak < limit) {
      if (!days.contains(DateKeys.dayKey(cursor))) {
        break;
      }
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return streak;
  }

  /// Inclusive day count from profile creation through today. A negative value
  /// means no cap applies.
  int _dayLimit(DateTime today, DateTime? profileCreatedAt) {
    if (profileCreatedAt == null) {
      return -1;
    }
    final created = DateTime(
      profileCreatedAt.year,
      profileCreatedAt.month,
      profileCreatedAt.day,
    );
    final days = today.difference(created).inDays + 1;
    return days < 1 ? 1 : days;
  }
}
