import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/services/pr_service.dart';
import 'package:mova/services/workout_calculator.dart';

final DateTime _now = DateTime.utc(2026, 11, 6, 12, 30);

WorkoutSession _session(List<SessionExercise> exercises) {
  return WorkoutSession(
    id: 'session-1',
    name: 'Push Day',
    source: SessionSource.routine,
    routineId: 'routine-1',
    startedAt: _now.subtract(const Duration(minutes: 30)),
    completedAt: _now,
    status: SessionStatus.completed,
    exercises: exercises,
  );
}

SessionExercise _exercise(String exerciseId, List<WorkoutSet> sets) {
  return SessionExercise(
    id: 'session-exercise-$exerciseId',
    exerciseId: exerciseId,
    order: 0,
    sets: sets,
  );
}

WorkoutSet _set(
  String id, {
  required double weightKg,
  required int reps,
  bool isWarmup = false,
  bool completed = true,
}) {
  return WorkoutSet(
    id: id,
    index: 0,
    weightKg: weightKg,
    reps: reps,
    isWarmup: isWarmup,
    completed: completed,
    completedAt: completed ? _now : null,
  );
}

PersonalRecord _existing(String exerciseId, double bestE1rmKg) {
  return PersonalRecord(
    exerciseId: exerciseId,
    bestE1rmKg: bestE1rmKg,
    weightKg: 100,
    reps: 5,
    achievedAt: _now.subtract(const Duration(days: 7)),
    sessionId: 'session-0',
    previousBestKg: 0,
  );
}

void main() {
  const service = PrService();

  test('detects a first weighted personal record', () {
    final records = service.detect(
      session: _session(<SessionExercise>[
        _exercise('barbell-bench-press', <WorkoutSet>[
          _set('set-1', weightKg: 100, reps: 5),
        ]),
      ]),
      existing: const <String, PersonalRecord>{},
    );

    expect(records, hasLength(1));
    expect(records.single.exerciseId, 'barbell-bench-press');
    expect(
      records.single.bestE1rmKg,
      closeTo(WorkoutCalculator.estimatedOneRepMax(100, 5), 0.0001),
    );
    expect(records.single.previousBestKg, 0);
    expect(records.single.weightKg, 100);
    expect(records.single.reps, 5);
    expect(records.single.sessionId, 'session-1');
    expect(records.single.achievedAt, _now);
  });

  test('detects a strict improvement over the stored best', () {
    final records = service.detect(
      session: _session(<SessionExercise>[
        _exercise('barbell-bench-press', <WorkoutSet>[
          _set('set-1', weightKg: 100, reps: 8),
        ]),
      ]),
      existing: <String, PersonalRecord>{
        'barbell-bench-press': _existing('barbell-bench-press', 110),
      },
    );

    expect(records, hasLength(1));
    expect(records.single.previousBestKg, 110);
    expect(
      records.single.bestE1rmKg,
      closeTo(WorkoutCalculator.estimatedOneRepMax(100, 8), 0.0001),
    );
  });

  test('ignores equal and lower estimated one-rep maxes', () {
    final equal = service.detect(
      session: _session(<SessionExercise>[
        _exercise('barbell-bench-press', <WorkoutSet>[
          _set('set-1', weightKg: 100, reps: 6),
        ]),
      ]),
      existing: <String, PersonalRecord>{
        'barbell-bench-press': _existing('barbell-bench-press', 120),
      },
    );
    final lower = service.detect(
      session: _session(<SessionExercise>[
        _exercise('barbell-bench-press', <WorkoutSet>[
          _set('set-1', weightKg: 100, reps: 5),
        ]),
      ]),
      existing: <String, PersonalRecord>{
        'barbell-bench-press': _existing('barbell-bench-press', 120),
      },
    );

    expect(equal, isEmpty);
    expect(lower, isEmpty);
  });

  test('ignores warm-up, incomplete, high-rep, and bodyweight sets', () {
    final records = service.detect(
      session: _session(<SessionExercise>[
        _exercise('barbell-bench-press', <WorkoutSet>[
          _set('warmup', weightKg: 120, reps: 5, isWarmup: true),
          _set('incomplete', weightKg: 120, reps: 5, completed: false),
          _set('high-rep', weightKg: 60, reps: 13),
          _set('bodyweight', weightKg: 0, reps: 20),
        ]),
      ]),
      existing: const <String, PersonalRecord>{},
    );

    expect(records, isEmpty);
  });

  test('keeps only the highest set per exercise in a session', () {
    final records = service.detect(
      session: _session(<SessionExercise>[
        _exercise('barbell-bench-press', <WorkoutSet>[
          _set('set-1', weightKg: 100, reps: 5),
          _set('set-2', weightKg: 110, reps: 5),
        ]),
      ]),
      existing: const <String, PersonalRecord>{},
    );

    expect(records, hasLength(1));
    expect(records.single.weightKg, 110);
    expect(
      records.single.bestE1rmKg,
      closeTo(WorkoutCalculator.estimatedOneRepMax(110, 5), 0.0001),
    );
  });

  test('returns multiple records sorted by estimated one-rep max', () {
    final records = service.detect(
      session: _session(<SessionExercise>[
        _exercise('dumbbell-fly', <WorkoutSet>[
          _set('fly', weightKg: 20, reps: 10),
        ]),
        _exercise('barbell-row', <WorkoutSet>[
          _set('row', weightKg: 80, reps: 8),
        ]),
        _exercise('barbell-bench-press', <WorkoutSet>[
          _set('bench', weightKg: 100, reps: 5),
        ]),
      ]),
      existing: const <String, PersonalRecord>{},
    );

    expect(records.map((record) => record.exerciseId).toList(), <String>[
      'barbell-bench-press',
      'barbell-row',
      'dumbbell-fly',
    ]);
  });

  test('recompute walks history in order and fills previous bests', () {
    final older = _sessionAt(
      id: 'older',
      date: _now.subtract(const Duration(days: 3)),
      weightKg: 80,
    );
    final newer = _sessionAt(
      id: 'newer',
      date: _now.subtract(const Duration(days: 1)),
      weightKg: 100,
    );

    final records = service.recompute(<WorkoutSession>[newer, older]);

    final record = records['barbell-bench-press'];
    expect(record, isNotNull);
    expect(record!.sessionId, 'newer');
    expect(
      record.bestE1rmKg,
      closeTo(WorkoutCalculator.estimatedOneRepMax(100, 5), 0.0001),
    );
    expect(
      record.previousBestKg,
      closeTo(WorkoutCalculator.estimatedOneRepMax(80, 5), 0.0001),
    );
  });

  test(
    'recompute drops a deleted session and falls back to the older best',
    () {
      final older = _sessionAt(
        id: 'older',
        date: _now.subtract(const Duration(days: 3)),
        weightKg: 80,
      );
      final newer = _sessionAt(
        id: 'newer',
        date: _now.subtract(const Duration(days: 1)),
        weightKg: 100,
      );

      final records = service.recompute(<WorkoutSession>[older]);

      expect(records, hasLength(1));
      expect(records['barbell-bench-press']!.sessionId, 'older');
      expect(
        records['barbell-bench-press']!.bestE1rmKg,
        closeTo(WorkoutCalculator.estimatedOneRepMax(80, 5), 0.0001),
      );
      expect(
        records['barbell-bench-press']!.bestE1rmKg,
        lessThan(
          service.recompute(<WorkoutSession>[
            older,
            newer,
          ])['barbell-bench-press']!.bestE1rmKg,
        ),
      );
    },
  );

  test('recompute ignores warm-up and incomplete sets and empty history', () {
    final incomplete = WorkoutSession(
      id: 'incomplete',
      name: 'Workout',
      source: SessionSource.empty,
      startedAt: _now,
      completedAt: _now,
      status: SessionStatus.completed,
      exercises: <SessionExercise>[
        _exercise('barbell-bench-press', <WorkoutSet>[
          _set('warmup', weightKg: 120, reps: 5, isWarmup: true),
          _set('incomplete', weightKg: 120, reps: 5, completed: false),
        ]),
      ],
    );

    expect(service.recompute(<WorkoutSession>[incomplete]), isEmpty);
    expect(service.recompute(const <WorkoutSession>[]), isEmpty);
  });
}

WorkoutSession _sessionAt({
  required String id,
  required DateTime date,
  required double weightKg,
}) {
  return WorkoutSession(
    id: id,
    name: 'Push Day',
    source: SessionSource.empty,
    startedAt: date.subtract(const Duration(minutes: 30)),
    completedAt: date,
    status: SessionStatus.completed,
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'exercise-$id',
        exerciseId: 'barbell-bench-press',
        order: 0,
        sets: <WorkoutSet>[
          WorkoutSet(
            id: 'set-$id',
            index: 0,
            weightKg: weightKg,
            reps: 5,
            completed: true,
            completedAt: date,
          ),
        ],
      ),
    ],
  );
}
