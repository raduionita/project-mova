import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/equipment_group.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/progression_suggestion.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _now = DateTime.utc(2026, 11, 7, 12);

const List<Exercise> _equipmentLibrary = <Exercise>[
  Exercise(
    id: 'dumbbell-bench-press',
    name: 'Dumbbell Bench Press',
    primaryMuscle: 'Chest',
    equipment: 'Dumbbell',
    isCompound: true,
  ),
  Exercise(
    id: 'dumbbell-row',
    name: 'Dumbbell Row',
    primaryMuscle: 'Back',
    equipment: 'Dumbbell',
    isCompound: true,
  ),
  Exercise(
    id: 'barbell-bench-press',
    name: 'Barbell Bench Press',
    primaryMuscle: 'Chest',
    equipment: 'Barbell',
    isCompound: true,
  ),
  Exercise(
    id: 'barbell-row',
    name: 'Barbell Row',
    primaryMuscle: 'Back',
    equipment: 'Barbell',
    isCompound: true,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profile equipment saves and reloads', () async {
    final storage = StorageService.inMemory();
    final profile = ProfileProvider(storage, clock: FakeClock(_now));
    await profile.saveProfile(
      UserProfile(id: 'profile-1', createdAt: _now, updatedAt: _now),
    );

    expect(
      await profile.updateEquipment(const <EquipmentGroup>[
        EquipmentGroup.dumbbells,
        EquipmentGroup.kettlebells,
      ]),
      isTrue,
    );

    final reloaded = ProfileProvider(storage, clock: FakeClock(_now));
    await reloaded.load();
    expect(reloaded.profile?.availableEquipment, <EquipmentGroup>[
      EquipmentGroup.dumbbells,
      EquipmentGroup.kettlebells,
    ]);
  });

  test('equipment cannot be saved empty', () async {
    final storage = StorageService.inMemory();
    final profile = ProfileProvider(storage, clock: FakeClock(_now));
    await profile.saveProfile(
      UserProfile(id: 'profile-1', createdAt: _now, updatedAt: _now),
    );

    expect(await profile.updateEquipment(const <EquipmentGroup>[]), isFalse);
    expect(profile.error, 'Choose at least one equipment option.');
  });

  test('onboarding equipment persists in the draft', () async {
    final storage = StorageService.inMemory();
    final onboarding = OnboardingProvider(storage, clock: FakeClock(_now));

    expect(
      await onboarding.setEquipment(const <EquipmentGroup>[
        EquipmentGroup.bodyweight,
      ]),
      isTrue,
    );

    final reloaded = OnboardingProvider(storage, clock: FakeClock(_now));
    await reloaded.load();
    expect(reloaded.draft.availableEquipment, <EquipmentGroup>[
      EquipmentGroup.bodyweight,
    ]);
    expect(reloaded.draft.currentStep, OnboardingStep.welcome);
  });

  test('plan generation and schedule updates keep the equipment', () async {
    final storage = StorageService.inMemory();
    final plans = PlanProvider(
      storage,
      loadExercises: () async => _equipmentLibrary,
      clock: FakeClock(_now),
    );

    await plans.generate(
      goals: const <Goal>[Goal.buildMuscle],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 3,
      trainingDays: const <int>[1, 3, 5],
      availableEquipment: const <EquipmentGroup>[EquipmentGroup.dumbbells],
    );

    expect(plans.plan!.availableEquipment, <EquipmentGroup>[
      EquipmentGroup.dumbbells,
    ]);
    expect(
      plans.plan!.days
          .expand((day) => day.exercises)
          .every(
            (exercise) => const <String>{
              'dumbbell-bench-press',
              'dumbbell-row',
            }.contains(exercise.exerciseId),
          ),
      isTrue,
    );

    await plans.updateSchedule(
      daysPerWeek: 3,
      trainingDays: const <int>[1, 3, 5],
      availableEquipment: const <EquipmentGroup>[EquipmentGroup.barbell],
    );

    expect(plans.plan!.availableEquipment, <EquipmentGroup>[
      EquipmentGroup.barbell,
    ]);
    expect(
      plans.plan!.days
          .expand((day) => day.exercises)
          .every(
            (exercise) => const <String>{
              'barbell-bench-press',
              'barbell-row',
            }.contains(exercise.exerciseId),
          ),
      isTrue,
    );
  });

  test('plan warnings are exposed and cleared', () async {
    final storage = StorageService.inMemory();
    final plans = PlanProvider(
      storage,
      loadExercises: () async => const <Exercise>[
        Exercise(
          id: 'barbell-bench-press',
          name: 'Barbell Bench Press',
          primaryMuscle: 'Chest',
          equipment: 'Barbell',
          isCompound: true,
        ),
      ],
      clock: FakeClock(_now),
    );

    await plans.generate(
      goals: const <Goal>[Goal.buildMuscle],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 1,
      trainingDays: const <int>[1],
      availableEquipment: const <EquipmentGroup>[EquipmentGroup.bodyweight],
    );

    expect(plans.lastWarning, contains('No exercises match your equipment'));

    final fullLibrary = await SeedDataService().loadExercises();
    final fullPlans = PlanProvider(
      storage,
      loadExercises: () async => fullLibrary,
      clock: FakeClock(_now),
    );
    await fullPlans.generate(
      goals: const <Goal>[Goal.buildMuscle],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 1,
      trainingDays: const <int>[1],
      availableEquipment: EquipmentGroup.values,
    );

    expect(fullPlans.lastWarning, isNull);
  });

  test(
    'workout suggestions prefill sets and swaps reset and persist',
    () async {
      final storage = StorageService.inMemory();
      final workout = WorkoutProvider(
        storage,
        clock: FakeClock(_now),
        idService: IdService(generator: _sequentialIds()),
      );
      const suggestion = ProgressionSuggestion(
        exerciseId: 'barbell-bench-press',
        weightKg: 82.5,
        reps: 8,
        previousWeightKg: 80,
        previousReps: 12,
        action: ProgressionAction.increase,
      );
      final day = PlanDay(
        id: 'day-1',
        weekday: 1,
        name: 'Push',
        muscleGroups: const <String>['Chest'],
        estimatedMinutes: 40,
        exercises: const <PlanExercise>[
          PlanExercise(
            exerciseId: 'barbell-bench-press',
            sets: 3,
            repsLow: 8,
            repsHigh: 12,
            restSeconds: 90,
            order: 0,
          ),
        ],
      );

      await workout.startFromPlanDay(
        day,
        suggest: (exerciseId, repsLow, repsHigh) => suggestion,
      );

      var exercise = workout.activeSession!.exercises.single;
      expect(exercise.progression, suggestion);
      expect(exercise.sets, hasLength(3));
      expect(exercise.sets.first.weightKg, 82.5);
      expect(exercise.sets.first.reps, 8);

      await workout.completeSet(
        exerciseId: exercise.exerciseId,
        setId: exercise.sets.first.id,
      );
      expect(
        await workout.replaceExercise(
          exerciseId: exercise.exerciseId,
          replacementExerciseId: 'dumbbell-bench-press',
        ),
        isTrue,
      );

      exercise = workout.activeSession!.exercises.single;
      expect(exercise.exerciseId, 'dumbbell-bench-press');
      expect(exercise.progression, isNull);
      expect(exercise.sets, hasLength(3));
      expect(exercise.sets.every((set) => set.weightKg == 0), isTrue);
      expect(exercise.sets.every((set) => !set.completed), isTrue);

      final reloaded = WorkoutProvider(storage, clock: FakeClock(_now));
      await reloaded.loadActive();
      expect(
        reloaded.activeSession!.exercises.single.exerciseId,
        'dumbbell-bench-press',
      );
    },
  );

  test('added exercises keep their suggestion prefill', () async {
    final storage = StorageService.inMemory();
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(generator: _sequentialIds()),
    );
    await workout.startEmpty();

    const suggestion = ProgressionSuggestion(
      exerciseId: 'dumbbell-row',
      weightKg: 32.5,
      reps: 10,
      previousWeightKg: 30,
      previousReps: 12,
      action: ProgressionAction.increase,
    );
    await workout.addExercise('dumbbell-row', suggestion: suggestion);

    final exercise = workout.activeSession!.exercises.single;
    expect(exercise.progression, suggestion);
    expect(exercise.sets.first.weightKg, 32.5);
    expect(exercise.sets.first.reps, 10);
  });

  test('a legacy session without progression still loads', () async {
    final storage = StorageService.inMemory();
    await storage.writeObject(kActiveSessionKey, <String, dynamic>{
      'id': 'session-1',
      'name': 'Legacy',
      'source': 'empty',
      'startedAt': _now.toIso8601String(),
      'status': 'active',
      'exercises': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'exercise-1',
          'exerciseId': 'barbell-bench-press',
          'order': 0,
          'sets': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'set-1',
              'index': 0,
              'weightKg': 60,
              'reps': 8,
            },
          ],
        },
      ],
    });

    final workout = WorkoutProvider(storage, clock: FakeClock(_now));
    await workout.loadActive();

    expect(workout.activeSession, isNotNull);
    expect(workout.activeSession!.exercises.single.progression, isNull);
  });
}

IdGenerator _sequentialIds() {
  var counter = 0;
  return () => 'id-${++counter}';
}
