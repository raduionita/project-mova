import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/services/workout_calculator.dart';

WorkoutSet _set({
  required String id,
  required int index,
  required double weightKg,
  required int reps,
  bool isWarmup = false,
  bool completed = true,
}) {
  return WorkoutSet(
    id: id,
    index: index,
    weightKg: weightKg,
    reps: reps,
    isWarmup: isWarmup,
    completed: completed,
  );
}

void main() {
  final exercises = <SessionExercise>[
    SessionExercise(
      id: 'exercise-1',
      exerciseId: 'barbell-bench-press',
      order: 0,
      sets: <WorkoutSet>[
        _set(id: 'set-1', index: 0, weightKg: 100, reps: 5),
        _set(id: 'set-2', index: 1, weightKg: 100, reps: 5, isWarmup: true),
        _set(id: 'set-3', index: 2, weightKg: 100, reps: 5, completed: false),
      ],
    ),
    SessionExercise(
      id: 'exercise-2',
      exerciseId: 'dumbbell-fly',
      order: 1,
      sets: <WorkoutSet>[
        _set(id: 'set-4', index: 0, weightKg: 20, reps: 10),
        _set(id: 'set-5', index: 1, weightKg: 0, reps: 12),
      ],
    ),
  ];

  test('volume counts completed working sets only', () {
    expect(WorkoutCalculator.volumeKg(exercises), 700);
  });

  test('completed set count excludes warm-ups and open sets', () {
    expect(WorkoutCalculator.completedSetCount(exercises), 3);
  });

  test('duration subtracts stored and running pause time', () {
    final startedAt = DateTime(2026, 11, 6, 12);
    final now = DateTime(2026, 11, 6, 12, 30);
    expect(
      WorkoutCalculator.durationSeconds(
        startedAt: startedAt,
        now: now,
        pausedSeconds: 300,
      ),
      1500,
    );
    expect(
      WorkoutCalculator.durationSeconds(
        startedAt: startedAt,
        now: now,
        pausedSeconds: 60,
        pausedAt: DateTime(2026, 11, 6, 12, 20),
      ),
      1140,
    );
    expect(
      WorkoutCalculator.durationSeconds(
        startedAt: startedAt,
        now: now,
        pausedSeconds: 4000,
      ),
      0,
    );
  });

  test('duration clamps to zero when the clock moves backward', () {
    expect(
      WorkoutCalculator.durationSeconds(
        startedAt: DateTime(2026, 11, 6, 12, 30),
        now: DateTime(2026, 11, 6, 12),
      ),
      0,
    );
  });

  test('session duration uses completedAt when present', () {
    final session = WorkoutSession(
      id: 'session-1',
      name: 'Push day',
      source: SessionSource.routine,
      startedAt: DateTime(2026, 11, 6, 12),
      completedAt: DateTime(2026, 11, 6, 12, 45),
      status: SessionStatus.completed,
      pausedSeconds: 120,
      exercises: exercises,
    );
    expect(
      WorkoutCalculator.sessionDurationSeconds(
        session,
        DateTime(2026, 11, 6, 13),
      ),
      2580,
    );
  });

  test('Epley one-rep max handles edge cases', () {
    expect(WorkoutCalculator.estimatedOneRepMax(100, 5), closeTo(116.67, 0.01));
    expect(WorkoutCalculator.estimatedOneRepMax(80, 10), closeTo(106.67, 0.01));
    expect(WorkoutCalculator.estimatedOneRepMax(0, 8), 0);
    expect(WorkoutCalculator.estimatedOneRepMax(80, 0), 0);
  });
}
