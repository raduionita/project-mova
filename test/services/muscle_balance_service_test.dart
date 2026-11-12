import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/services/muscle_balance_service.dart';

final DateTime _now = DateTime(2026, 11, 12, 12);
const MuscleBalanceService _service = MuscleBalanceService();

SessionExercise _exercise({
  required String id,
  String? primaryMuscle,
  List<String> secondaryMuscles = const <String>[],
  double weightKg = 100,
  int reps = 10,
  bool completed = true,
  bool isWarmup = false,
}) {
  return SessionExercise(
    id: id,
    exerciseId: id,
    order: 0,
    primaryMuscle: primaryMuscle,
    secondaryMuscles: secondaryMuscles,
    sets: <WorkoutSet>[
      WorkoutSet(
        id: '$id-set',
        index: 0,
        weightKg: weightKg,
        reps: reps,
        completed: completed,
        isWarmup: isWarmup,
      ),
    ],
  );
}

WorkoutSession _session(
  int daysAgo,
  List<SessionExercise> exercises, {
  List<String> muscleGroups = const <String>[],
  SessionStatus status = SessionStatus.completed,
}) {
  final date = DateTime(_now.year, _now.month, _now.day - daysAgo);
  return WorkoutSession(
    id: 'session-$daysAgo',
    name: 'Workout',
    source: SessionSource.empty,
    startedAt: date.subtract(const Duration(minutes: 30)),
    completedAt: date,
    status: status,
    exercises: exercises,
    muscleGroups: muscleGroups,
  );
}

void main() {
  test('gives primary muscles full volume and secondary half', () {
    final volume = _service.volumeByMuscle(<WorkoutSession>[
      _session(1, <SessionExercise>[
        _exercise(
          id: 'bench',
          primaryMuscle: 'Chest',
          secondaryMuscles: const <String>['Triceps', 'Shoulders'],
        ),
      ]),
    ], _now);

    expect(volume['Chest'], 1000);
    expect(volume['Triceps'], 500);
    expect(volume['Shoulders'], 500);
  });

  test('ignores warm-up and incomplete sets', () {
    final volume = _service.volumeByMuscle(<WorkoutSession>[
      _session(1, <SessionExercise>[
        _exercise(id: 'warmup', primaryMuscle: 'Chest', isWarmup: true),
        _exercise(id: 'open', primaryMuscle: 'Chest', completed: false),
      ]),
    ], _now);

    expect(volume, isEmpty);
  });

  test('only counts the last 28 days', () {
    final volume = _service.volumeByMuscle(<WorkoutSession>[
      _session(27, <SessionExercise>[
        _exercise(id: 'inside', primaryMuscle: 'Back'),
      ]),
      _session(28, <SessionExercise>[
        _exercise(id: 'outside', primaryMuscle: 'Back'),
      ]),
    ], _now);

    expect(volume['Back'], 1000);
  });

  test('falls back to session muscle groups for legacy exercises', () {
    final volume = _service.volumeByMuscle(<WorkoutSession>[
      _session(
        2,
        <SessionExercise>[_exercise(id: 'legacy')],
        muscleGroups: const <String>['Full Body', 'Core'],
      ),
    ], _now);

    expect(volume['Full Body'], 500);
    expect(volume['Core'], 500);
  });

  test('reports tracked muscles with no volume as neglected', () {
    final neglected = _service.neglectedMuscles(<String, double>{
      'Chest': 1000,
      'Back': 2000,
    });

    expect(neglected, contains('Quads'));
    expect(neglected, contains('Calves'));
    expect(neglected, isNot(contains('Chest')));
    expect(neglected, isNot(contains('Back')));
  });
}
