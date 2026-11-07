import '../models/progression_suggestion.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';

/// Deterministic progressive overload from the most recent performance.
class ProgressionService {
  const ProgressionService();

  ProgressionSuggestion? suggest({
    required String exerciseId,
    required String equipment,
    required int targetRepsLow,
    required int targetRepsHigh,
    required List<WorkoutSession> history,
    required double incrementKg,
  }) {
    if (equipment == 'Bodyweight' || incrementKg <= 0) {
      return null;
    }

    final sorted = List<WorkoutSession>.of(history)
      ..sort((a, b) {
        final aTime = a.completedAt ?? a.startedAt;
        final bTime = b.completedAt ?? b.startedAt;
        return bTime.compareTo(aTime);
      });

    for (final workout in sorted) {
      final exercise = workout.exercises
          .where((item) => item.exerciseId == exerciseId)
          .firstOrNull;
      if (exercise == null) {
        continue;
      }
      final sets = exercise.sets
          .where((set) => set.completed && !set.isWarmup)
          .toList(growable: false);
      if (sets.isEmpty) {
        continue;
      }

      final reference = List<WorkoutSet>.of(sets)
        ..sort((a, b) {
          final weight = b.weightKg.compareTo(a.weightKg);
          if (weight != 0) {
            return weight;
          }
          final reps = b.reps.compareTo(a.reps);
          if (reps != 0) {
            return reps;
          }
          return b.index.compareTo(a.index);
        });
      final source = reference.first;
      if (source.weightKg <= 0) {
        return null;
      }

      final topReached = sets.every((set) => set.reps >= targetRepsHigh);
      final nextWeight = topReached
          ? (source.weightKg + incrementKg).clamp(0.0, 500.0)
          : source.weightKg;
      return ProgressionSuggestion(
        exerciseId: exerciseId,
        weightKg: nextWeight,
        reps: targetRepsLow,
        previousWeightKg: source.weightKg,
        previousReps: source.reps,
        action: topReached
            ? ProgressionAction.increase
            : ProgressionAction.repeat,
        sourceWorkoutId: workout.id,
        sourceSetId: source.id,
      );
    }
    return null;
  }
}
