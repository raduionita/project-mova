import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
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

const Exercise _benchPress = Exercise(
  id: 'barbell-bench-press',
  name: 'Barbell bench press',
  primaryMuscle: 'Chest',
  secondaryMuscles: <String>['Triceps', 'Shoulders'],
  equipment: 'Barbell',
  isCompound: true,
);

void main() {
  test(
    'plan sessions snapshot their title, source, slot, and muscles',
    () async {
      final storage = StorageService.inMemory();
      final workout = _provider(storage);
      const planDay = PlanDay(
        id: 'plan-day-2',
        order: 1,
        slotKey: 'pull',
        name: 'Pull day',
        muscleGroups: <String>['Back', 'Biceps'],
        estimatedMinutes: 45,
        exercises: <PlanExercise>[
          PlanExercise(
            exerciseId: 'barbell-bench-press',
            sets: 3,
            repsLow: 8,
            repsHigh: 10,
            restSeconds: 90,
            order: 0,
          ),
        ],
      );

      expect(
        await workout.startFromPlanDay(
          planDay,
          findExercise: (id) => id == _benchPress.id ? _benchPress : null,
        ),
        isTrue,
      );

      final session = workout.activeSession!;
      expect(session.schemaVersion, 2);
      expect(session.displayTitle, 'Pull day');
      expect(session.sourceLabel, 'Plan');
      expect(session.slotKey, 'pull');
      expect(session.muscleGroups, <String>['Back', 'Biceps']);
      expect(session.focusPromptShown, isTrue);
      expect(session.exercises.single.primaryMuscle, 'Chest');
      expect(session.exercises.single.secondaryMuscles, <String>[
        'Triceps',
        'Shoulders',
      ]);

      final restored = _provider(storage);
      await restored.loadActive();
      final reloaded = restored.activeSession!;
      expect(reloaded.displayTitle, 'Pull day');
      expect(reloaded.sourceLabel, 'Plan');
      expect(reloaded.slotKey, 'pull');
      expect(reloaded.muscleGroups, <String>['Back', 'Biceps']);
      expect(reloaded.focusPromptShown, isTrue);
      expect(reloaded.exercises.single.primaryMuscle, 'Chest');
      expect(reloaded.exercises.single.secondaryMuscles, <String>[
        'Triceps',
        'Shoulders',
      ]);
    },
  );

  test(
    'an empty workout asks for focus once and persists the answer',
    () async {
      final storage = StorageService.inMemory();
      final workout = _provider(storage);

      expect(await workout.startEmpty(), isTrue);
      expect(workout.activeSession!.displayTitle, 'Empty workout');
      expect(workout.activeSession!.sourceLabel, 'Empty');
      expect(workout.activeSession!.focusPromptShown, isFalse);

      expect(await workout.markFocusPromptShown(), isTrue);
      expect(workout.activeSession!.focusPromptShown, isTrue);

      final restored = _provider(storage);
      await restored.loadActive();
      expect(restored.activeSession!.focusPromptShown, isTrue);
    },
  );

  test('adding an exercise snapshots its muscles', () async {
    final storage = StorageService.inMemory();
    final workout = _provider(storage);
    await workout.startEmpty();

    expect(
      await workout.addExercise(_benchPress.id, exercise: _benchPress),
      isTrue,
    );

    final entry = workout.activeSession!.exercises.single;
    expect(entry.primaryMuscle, 'Chest');
    expect(entry.secondaryMuscles, <String>['Triceps', 'Shoulders']);
  });

  test('legacy sessions keep loading with sensible snapshot defaults', () {
    final session = WorkoutSession.fromJson(<String, dynamic>{
      'schemaVersion': 1,
      'id': 'legacy-session',
      'name': 'Push day',
      'source': 'routine',
      'startedAt': _fixedNow.toIso8601String(),
      'status': 'completed',
      'exercises': <Map<String, dynamic>>[
        <String, dynamic>{
          'schemaVersion': 1,
          'id': 'legacy-entry',
          'exerciseId': 'barbell-bench-press',
          'order': 0,
          'sets': <Map<String, dynamic>>[],
        },
      ],
    });

    expect(session.displayTitle, 'Push day');
    expect(session.sourceLabel, 'Routine');
    expect(session.slotKey, isNull);
    expect(session.muscleGroups, isEmpty);
    expect(session.focusPromptShown, isTrue);
    expect(session.exercises.single.primaryMuscle, isNull);
    expect(session.exercises.single.secondaryMuscles, isEmpty);
    expect(session.exercises.single.schemaVersion, 1);
  });

  test('session exercise JSON keeps muscle snapshots', () {
    const entry = SessionExercise(
      id: 'entry-1',
      exerciseId: 'barbell-bench-press',
      order: 0,
      sets: <WorkoutSet>[],
      primaryMuscle: 'Chest',
      secondaryMuscles: <String>['Triceps'],
    );

    final decoded = SessionExercise.fromJson(entry.toJson());
    expect(decoded.primaryMuscle, 'Chest');
    expect(decoded.secondaryMuscles, <String>['Triceps']);
  });
}
