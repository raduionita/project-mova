import '../models/workout_session.dart';
import '../models/workout_set.dart';

/// Volume by muscle group over a recent window.
///
/// Primary muscles receive the full working-set volume and secondary muscles
/// receive half. Legacy sessions without muscle snapshots fall back to their
/// session-level muscle groups.
class MuscleBalanceService {
  const MuscleBalanceService();

  /// Muscle groups shown in the balance card, in display order.
  static const List<String> trackedMuscles = <String>[
    'Chest',
    'Back',
    'Shoulders',
    'Biceps',
    'Triceps',
    'Quads',
    'Hamstrings',
    'Glutes',
    'Core',
    'Calves',
  ];

  /// Volume in kilograms keyed by muscle group.
  Map<String, double> volumeByMuscle(
    List<WorkoutSession> history,
    DateTime now, {
    int days = 28,
  }) {
    final start = DateTime(now.year, now.month, now.day - (days - 1));
    final nowDate = DateTime(now.year, now.month, now.day);
    final volume = <String, double>{};

    for (final workout in history) {
      if (workout.status != SessionStatus.completed) {
        continue;
      }
      final at = workout.completedAt ?? workout.startedAt;
      final day = DateTime(at.year, at.month, at.day);
      if (day.isBefore(start) || day.isAfter(nowDate)) {
        continue;
      }
      for (final exercise in workout.exercises) {
        final exerciseVolume = _exerciseVolume(exercise.sets);
        if (exerciseVolume <= 0) {
          continue;
        }
        final primary = exercise.primaryMuscle;
        if (primary != null && primary.isNotEmpty) {
          volume[primary] = (volume[primary] ?? 0) + exerciseVolume;
        } else if (workout.muscleGroups.isNotEmpty) {
          final share = exerciseVolume / workout.muscleGroups.length;
          for (final muscle in workout.muscleGroups) {
            volume[muscle] = (volume[muscle] ?? 0) + share;
          }
        }
        for (final muscle in exercise.secondaryMuscles) {
          if (muscle.isEmpty) {
            continue;
          }
          volume[muscle] = (volume[muscle] ?? 0) + exerciseVolume * 0.5;
        }
      }
    }
    return volume;
  }

  /// Tracked muscles with no volume in the window.
  List<String> neglectedMuscles(Map<String, double> volumeByMuscle) {
    return <String>[
      for (final muscle in trackedMuscles)
        if ((volumeByMuscle[muscle] ?? 0) <= 0) muscle,
    ];
  }

  double _exerciseVolume(List<WorkoutSet> sets) {
    var total = 0.0;
    for (final set in sets) {
      if (!set.completed || set.isWarmup) {
        continue;
      }
      if (set.weightKg > 0 && set.reps > 0) {
        total += set.weightKg * set.reps;
      }
    }
    return total;
  }
}
