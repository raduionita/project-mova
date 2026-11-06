import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/routine_exercise.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 6, 12);

IdGenerator _sequentialIds() {
  var counter = 0;
  return () => 'id-${++counter}';
}

WorkoutProvider _provider(StorageService storage) {
  return WorkoutProvider(
    storage,
    clock: FakeClock(_fixedNow),
    idService: IdService(generator: _sequentialIds()),
  );
}

void main() {
  test('startFromPlanDay creates a plan session and persists it', () async {
    final storage = StorageService.inMemory();
    final workout = _provider(storage);
    const planDay = PlanDay(
      id: 'plan-day-1',
      weekday: 5,
      name: 'Push day',
      muscleGroups: <String>['Chest', 'Triceps'],
      estimatedMinutes: 40,
      exercises: <PlanExercise>[
        PlanExercise(
          exerciseId: 'barbell-bench-press',
          sets: 4,
          repsLow: 6,
          repsHigh: 8,
          restSeconds: 120,
          order: 0,
        ),
        PlanExercise(
          exerciseId: 'cable-fly',
          sets: 3,
          repsLow: 10,
          repsHigh: 12,
          restSeconds: 60,
          order: 1,
        ),
      ],
    );

    expect(await workout.startFromPlanDay(planDay), isTrue);

    final session = workout.activeSession;
    expect(session, isNotNull);
    expect(session!.name, 'Push day');
    expect(session.source, SessionSource.plan);
    expect(session.planDayId, 'plan-day-1');
    expect(session.startedAt, _fixedNow);
    expect(session.status, SessionStatus.active);
    expect(session.exercises.length, 2);
    expect(session.exercises.first.exerciseId, 'barbell-bench-press');
    expect(session.exercises.first.order, 0);
    expect(session.exercises.first.sets.length, 4);
    expect(session.exercises.first.sets.first.reps, 6);
    expect(session.exercises.first.sets.first.weightKg, 0);
    expect(session.exercises.last.exerciseId, 'cable-fly');
    expect(session.exercises.last.order, 1);

    final restored = _provider(storage);
    await restored.loadActive();
    expect(restored.activeSession?.id, session.id);
    expect(restored.activeSession?.source, SessionSource.plan);
  });

  test(
    'startFromRoutine creates a routine session from prescribed sets',
    () async {
      final storage = StorageService.inMemory();
      final workout = _provider(storage);
      final routine = Routine(
        id: 'routine-1',
        name: 'Pull day',
        createdAt: _fixedNow,
        updatedAt: _fixedNow,
        exercises: const <RoutineExercise>[
          RoutineExercise(
            exerciseId: 'dumbbell-fly',
            sets: 4,
            repsLow: 12,
            repsHigh: 12,
            restSeconds: 60,
            order: 1,
          ),
          RoutineExercise(
            exerciseId: 'lat-pulldown',
            sets: 3,
            repsLow: 8,
            repsHigh: 10,
            restSeconds: 90,
            order: 0,
          ),
        ],
      );

      expect(await workout.startFromRoutine(routine), isTrue);

      final session = workout.activeSession!;
      expect(session.name, 'Pull day');
      expect(session.source, SessionSource.routine);
      expect(session.routineId, 'routine-1');
      expect(session.exercises.first.exerciseId, 'lat-pulldown');
      expect(session.exercises.first.sets.length, 3);
      expect(session.exercises.first.sets.first.reps, 8);
      expect(session.exercises.last.exerciseId, 'dumbbell-fly');
      expect(session.exercises.last.order, 1);

      final restored = _provider(storage);
      await restored.loadActive();
      expect(restored.activeSession?.routineId, 'routine-1');
    },
  );

  test('a restarted app recovers the exact active session', () async {
    final storage = StorageService.inMemory();
    final clock = FakeClock(_fixedNow);
    final workout = WorkoutProvider(
      storage,
      clock: clock,
      idService: IdService(generator: _sequentialIds()),
    );
    final routine = Routine(
      id: 'routine-1',
      name: 'Leg day',
      createdAt: _fixedNow,
      updatedAt: _fixedNow,
      exercises: const <RoutineExercise>[
        RoutineExercise(
          exerciseId: 'barbell-bench-press',
          sets: 3,
          repsLow: 8,
          repsHigh: 10,
          restSeconds: 120,
          order: 0,
        ),
      ],
    );
    await workout.startFromRoutine(routine);

    final exercise = workout.activeSession!.exercises.first;
    final firstSet = exercise.sets.first;
    await workout.updateSet(
      exerciseId: exercise.exerciseId,
      setId: firstSet.id,
      weightKg: 82.5,
      reps: 9,
      isWarmup: false,
    );
    await workout.completeSet(
      exerciseId: exercise.exerciseId,
      setId: firstSet.id,
    );
    await workout.addSet(exercise.exerciseId);
    clock.advance(const Duration(minutes: 5));
    await workout.pause();
    clock.advance(const Duration(minutes: 1));
    await workout.resume();

    final beforeKill = workout.activeSession!;
    expect(beforeKill.status, SessionStatus.active);
    expect(beforeKill.pausedSeconds, greaterThanOrEqualTo(60));

    final reopened = WorkoutProvider(
      storage,
      clock: clock,
      idService: IdService(generator: _sequentialIds()),
    );
    await reopened.loadActive();

    final recovered = reopened.activeSession;
    expect(recovered, isNotNull);
    expect(recovered!.toJson(), beforeKill.toJson());
    expect(recovered.status, SessionStatus.active);
    expect(recovered.exercises.first.sets, hasLength(4));
    final recoveredFirst = recovered.exercises.first.sets.first;
    expect(recoveredFirst.weightKg, 82.5);
    expect(recoveredFirst.reps, 9);
    expect(recoveredFirst.completed, isTrue);
    expect(recoveredFirst.completedAt, isNotNull);
  });

  test('startEmpty creates an empty session without exercises', () async {
    final workout = _provider(StorageService.inMemory());

    expect(await workout.startEmpty(), isTrue);

    final session = workout.activeSession!;
    expect(session.name, 'Empty workout');
    expect(session.source, SessionSource.empty);
    expect(session.planDayId, isNull);
    expect(session.routineId, isNull);
    expect(session.exercises, isEmpty);
  });

  test('startWalk creates a walk session without exercises', () async {
    final workout = _provider(StorageService.inMemory());

    expect(await workout.startWalk(), isTrue);

    final session = workout.activeSession!;
    expect(session.name, 'Walk');
    expect(session.source, SessionSource.walk);
    expect(session.exercises, isEmpty);
  });
}
