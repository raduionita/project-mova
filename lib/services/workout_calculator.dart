import '../models/session_exercise.dart';
import '../models/workout_session.dart';

/// Pure session math shared by the logger, summary, and progress features.
class WorkoutCalculator {
  const WorkoutCalculator._();

  /// Volume in kg from completed working sets.
  static double volumeKg(List<SessionExercise> exercises) {
    var total = 0.0;
    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        if (!set.completed || set.isWarmup) {
          continue;
        }
        if (set.weightKg <= 0 || set.reps <= 0) {
          continue;
        }
        total += set.weightKg * set.reps;
      }
    }
    return total;
  }

  /// Completed working sets, excluding warm-ups.
  static int completedSetCount(List<SessionExercise> exercises) {
    var total = 0;
    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        if (set.completed && !set.isWarmup) {
          total += 1;
        }
      }
    }
    return total;
  }

  /// All working sets, including those not completed yet.
  static int workingSetCount(List<SessionExercise> exercises) {
    var total = 0;
    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        if (!set.isWarmup) {
          total += 1;
        }
      }
    }
    return total;
  }

  /// Elapsed seconds minus stored and currently running pause time.
  static int durationSeconds({
    required DateTime startedAt,
    DateTime? completedAt,
    required DateTime now,
    int pausedSeconds = 0,
    DateTime? pausedAt,
  }) {
    final end = completedAt ?? now;
    final activePause = pausedAt != null && end.isAfter(pausedAt)
        ? end.difference(pausedAt).inSeconds
        : 0;
    final elapsed = end.difference(startedAt).inSeconds;
    return (elapsed - pausedSeconds - activePause).clamp(0, 864000);
  }

  /// Session duration using the same rules as the live logger.
  static int sessionDurationSeconds(WorkoutSession session, DateTime now) {
    return durationSeconds(
      startedAt: session.startedAt,
      completedAt: session.completedAt,
      now: now,
      pausedSeconds: session.pausedSeconds,
      pausedAt: session.pausedAt,
    );
  }

  /// Epley estimated one-rep max. Returns 0 for non-positive input.
  static double estimatedOneRepMax(double weightKg, int reps) {
    if (weightKg <= 0 || reps <= 0) {
      return 0;
    }
    return weightKg * (1 + reps / 30);
  }
}
