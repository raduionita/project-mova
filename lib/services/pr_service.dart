import '../models/personal_record.dart';
import '../models/session_exercise.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import 'workout_calculator.dart';

/// Detects personal records from a completed workout session.
///
/// Only completed working sets count. Weighted sets with 1 to 12 reps use an
/// estimated one rep max; bodyweight rep records arrive in a later phase.
class PrService {
  const PrService();

  List<PersonalRecord> detect({
    required WorkoutSession session,
    required Map<String, PersonalRecord> existing,
  }) {
    final bestByExercise = <String, PersonalRecord>{};

    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        final record = _recordFor(
          exercise: exercise,
          set: set,
          session: session,
          existing: existing[exercise.exerciseId],
        );
        if (record == null) {
          continue;
        }
        final current = bestByExercise[exercise.exerciseId];
        if (current == null || record.bestE1rmKg > current.bestE1rmKg) {
          bestByExercise[exercise.exerciseId] = record;
        }
      }
    }

    final records = bestByExercise.values.toList(growable: false);
    return (records..sort((a, b) => b.bestE1rmKg.compareTo(a.bestE1rmKg)))
        .toList(growable: false);
  }

  /// Rebuilds the best record per exercise from a full history in
  /// chronological order. Used after a deletion so removed PRs cannot linger.
  Map<String, PersonalRecord> recompute(List<WorkoutSession> history) {
    final sessions =
        history
            .where((session) => session.status == SessionStatus.completed)
            .toList(growable: false)
          ..sort((a, b) {
            final aDate = a.completedAt ?? a.startedAt;
            final bDate = b.completedAt ?? b.startedAt;
            return aDate.compareTo(bDate);
          });

    final best = <String, PersonalRecord>{};
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          if (!set.completed ||
              set.isWarmup ||
              set.weightKg <= 0 ||
              set.reps < 1 ||
              set.reps > 12) {
            continue;
          }
          final estimated = WorkoutCalculator.estimatedOneRepMax(
            set.weightKg,
            set.reps,
          );
          final previous = best[exercise.exerciseId];
          if (previous != null && estimated <= previous.bestE1rmKg) {
            continue;
          }
          best[exercise.exerciseId] = PersonalRecord(
            exerciseId: exercise.exerciseId,
            bestE1rmKg: estimated,
            weightKg: set.weightKg,
            reps: set.reps,
            achievedAt:
                set.completedAt ?? session.completedAt ?? session.startedAt,
            sessionId: session.id,
            previousBestKg: previous?.bestE1rmKg ?? 0,
          );
        }
      }
    }
    return Map<String, PersonalRecord>.unmodifiable(best);
  }

  PersonalRecord? _recordFor({
    required SessionExercise exercise,
    required WorkoutSet set,
    required WorkoutSession session,
    required PersonalRecord? existing,
  }) {
    if (!set.completed ||
        set.isWarmup ||
        set.weightKg <= 0 ||
        set.reps < 1 ||
        set.reps > 12) {
      return null;
    }
    final estimated = WorkoutCalculator.estimatedOneRepMax(
      set.weightKg,
      set.reps,
    );
    final previousBest = existing?.bestE1rmKg ?? 0;
    if (estimated <= previousBest) {
      return null;
    }
    return PersonalRecord(
      exerciseId: exercise.exerciseId,
      bestE1rmKg: estimated,
      weightKg: set.weightKg,
      reps: set.reps,
      achievedAt: set.completedAt ?? session.completedAt ?? session.startedAt,
      sessionId: session.id,
      previousBestKg: previousBest,
    );
  }
}
