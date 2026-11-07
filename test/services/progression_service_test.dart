import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/progression_suggestion.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/services/progression_service.dart';

const ProgressionService _service = ProgressionService();

WorkoutSession _session({
  required String id,
  required DateTime completedAt,
  required List<SessionExercise> exercises,
}) {
  return WorkoutSession(
    id: id,
    name: 'Workout',
    source: SessionSource.plan,
    startedAt: completedAt.subtract(const Duration(minutes: 45)),
    completedAt: completedAt,
    status: SessionStatus.completed,
    exercises: exercises,
  );
}

SessionExercise _exercise({
  required String exerciseId,
  required List<WorkoutSet> sets,
}) {
  return SessionExercise(
    id: 'session-exercise',
    exerciseId: exerciseId,
    order: 0,
    sets: sets,
  );
}

WorkoutSet _set({
  required String id,
  required int index,
  required double weightKg,
  required int reps,
  bool completed = true,
  bool isWarmup = false,
}) {
  return WorkoutSet(
    id: id,
    index: index,
    weightKg: weightKg,
    reps: reps,
    completed: completed,
    isWarmup: isWarmup,
  );
}

void main() {
  final now = DateTime.utc(2026, 11, 7, 12);

  test('returns null without history', () {
    final suggestion = _service.suggest(
      exerciseId: 'barbell-bench-press',
      equipment: 'Barbell',
      targetRepsLow: 8,
      targetRepsHigh: 12,
      history: const <WorkoutSession>[],
      incrementKg: 2.5,
    );

    expect(suggestion, isNull);
  });

  test('bodyweight exercises never suggest a load', () {
    final history = <WorkoutSession>[
      _session(
        id: 'session-1',
        completedAt: now,
        exercises: <SessionExercise>[
          _exercise(
            exerciseId: 'push-up',
            sets: <WorkoutSet>[
              _set(id: 'set-1', index: 0, weightKg: 0, reps: 20),
            ],
          ),
        ],
      ),
    ];

    final suggestion = _service.suggest(
      exerciseId: 'push-up',
      equipment: 'Bodyweight',
      targetRepsLow: 10,
      targetRepsHigh: 15,
      history: history,
      incrementKg: 2.5,
    );

    expect(suggestion, isNull);
  });

  test('ignores warmup-only and incomplete sets', () {
    final history = <WorkoutSession>[
      _session(
        id: 'session-1',
        completedAt: now,
        exercises: <SessionExercise>[
          _exercise(
            exerciseId: 'barbell-bench-press',
            sets: <WorkoutSet>[
              _set(
                id: 'warmup',
                index: 0,
                weightKg: 40,
                reps: 15,
                isWarmup: true,
              ),
              _set(
                id: 'working',
                index: 1,
                weightKg: 80,
                reps: 12,
                completed: false,
              ),
            ],
          ),
        ],
      ),
    ];

    final suggestion = _service.suggest(
      exerciseId: 'barbell-bench-press',
      equipment: 'Barbell',
      targetRepsLow: 8,
      targetRepsHigh: 12,
      history: history,
      incrementKg: 2.5,
    );

    expect(suggestion, isNull);
  });

  test('repeats the last weight when the top of the range is not reached', () {
    final history = <WorkoutSession>[
      _session(
        id: 'session-1',
        completedAt: now,
        exercises: <SessionExercise>[
          _exercise(
            exerciseId: 'barbell-bench-press',
            sets: <WorkoutSet>[
              _set(id: 'set-1', index: 0, weightKg: 80, reps: 12),
              _set(id: 'set-2', index: 1, weightKg: 80, reps: 10),
            ],
          ),
        ],
      ),
    ];

    final suggestion = _service.suggest(
      exerciseId: 'barbell-bench-press',
      equipment: 'Barbell',
      targetRepsLow: 8,
      targetRepsHigh: 12,
      history: history,
      incrementKg: 2.5,
    )!;

    expect(suggestion.action, ProgressionAction.repeat);
    expect(suggestion.weightKg, 80);
    expect(suggestion.reps, 8);
    expect(suggestion.previousWeightKg, 80);
    expect(suggestion.sourceWorkoutId, 'session-1');
  });

  test('adds the increment when every working set reaches the top', () {
    final history = <WorkoutSession>[
      _session(
        id: 'session-1',
        completedAt: now,
        exercises: <SessionExercise>[
          _exercise(
            exerciseId: 'barbell-bench-press',
            sets: <WorkoutSet>[
              _set(id: 'set-1', index: 0, weightKg: 80, reps: 12),
              _set(id: 'set-2', index: 1, weightKg: 80, reps: 12),
            ],
          ),
        ],
      ),
    ];

    final suggestion = _service.suggest(
      exerciseId: 'barbell-bench-press',
      equipment: 'Barbell',
      targetRepsLow: 8,
      targetRepsHigh: 12,
      history: history,
      incrementKg: 2.5,
    )!;

    expect(suggestion.action, ProgressionAction.increase);
    expect(suggestion.weightKg, 82.5);
    expect(suggestion.previousWeightKg, 80);
    expect(suggestion.reps, 8);
  });

  test('uses the newest workout that trained the exercise', () {
    final history = <WorkoutSession>[
      _session(
        id: 'older',
        completedAt: now.subtract(const Duration(days: 4)),
        exercises: <SessionExercise>[
          _exercise(
            exerciseId: 'barbell-bench-press',
            sets: <WorkoutSet>[
              _set(id: 'old-set', index: 0, weightKg: 70, reps: 12),
            ],
          ),
        ],
      ),
      _session(
        id: 'newer',
        completedAt: now,
        exercises: <SessionExercise>[
          _exercise(
            exerciseId: 'barbell-bench-press',
            sets: <WorkoutSet>[
              _set(id: 'new-set', index: 0, weightKg: 90, reps: 8),
            ],
          ),
        ],
      ),
    ];

    final suggestion = _service.suggest(
      exerciseId: 'barbell-bench-press',
      equipment: 'Barbell',
      targetRepsLow: 8,
      targetRepsHigh: 12,
      history: history,
      incrementKg: 2.5,
    )!;

    expect(suggestion.previousWeightKg, 90);
    expect(suggestion.action, ProgressionAction.repeat);
    expect(suggestion.sourceWorkoutId, 'newer');
  });

  test('clamps the next weight at 500 kg', () {
    final history = <WorkoutSession>[
      _session(
        id: 'session-1',
        completedAt: now,
        exercises: <SessionExercise>[
          _exercise(
            exerciseId: 'barbell-bench-press',
            sets: <WorkoutSet>[
              _set(id: 'set-1', index: 0, weightKg: 499, reps: 12),
            ],
          ),
        ],
      ),
    ];

    final suggestion = _service.suggest(
      exerciseId: 'barbell-bench-press',
      equipment: 'Barbell',
      targetRepsLow: 8,
      targetRepsHigh: 12,
      history: history,
      incrementKg: 5,
    )!;

    expect(suggestion.weightKg, 500);
  });

  test('returns null when the logged weight is zero', () {
    final history = <WorkoutSession>[
      _session(
        id: 'session-1',
        completedAt: now,
        exercises: <SessionExercise>[
          _exercise(
            exerciseId: 'barbell-bench-press',
            sets: <WorkoutSet>[
              _set(id: 'set-1', index: 0, weightKg: 0, reps: 12),
            ],
          ),
        ],
      ),
    ];

    final suggestion = _service.suggest(
      exerciseId: 'barbell-bench-press',
      equipment: 'Barbell',
      targetRepsLow: 8,
      targetRepsHigh: 12,
      history: history,
      incrementKg: 2.5,
    );

    expect(suggestion, isNull);
  });
}
