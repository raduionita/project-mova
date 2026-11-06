import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/services/plan_generator_service.dart';
import 'package:mova/services/seed_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> library;
  late Set<String> libraryIds;
  final fixedNow = DateTime.utc(2026, 11, 5, 12);

  setUpAll(() async {
    library = await SeedDataService().loadExercises();
    libraryIds = library.map((exercise) => exercise.id).toSet();
  });

  PlanGeneratorService generator({int sessionMinutes = 55}) {
    return PlanGeneratorService(
      exercises: library,
      now: () => fixedNow,
      sessionMinutes: sessionMinutes,
    );
  }

  test('every day and goal combination produces a valid plan', () {
    for (final days in <int>[1, 2, 3, 4, 5, 6, 7]) {
      for (final goal in Goal.values) {
        for (final level in ExperienceLevel.values) {
          final plan = generator().generate(
            goals: <Goal>[goal],
            experienceLevel: level,
            daysPerWeek: days,
            trainingDays: const <int>[1, 2, 3, 4, 5, 6, 7].sublist(0, days),
          );

          expect(plan.isFallback, isFalse, reason: '$days $goal $level');
          expect(plan.daysPerWeek, days);
          expect(plan.trainingDays, hasLength(days));
          expect(plan.days, hasLength(days));
          expect(plan.goal, goal);
          expect(plan.goals, <Goal>[goal]);
          expect(plan.generatedAt, fixedNow);

          for (final day in plan.days) {
            expect(day.weekday, inInclusiveRange(1, 7));
            expect(day.name, isNotEmpty);
            expect(day.estimatedMinutes, inInclusiveRange(20, 90));

            if (day.name == 'Active Recovery') {
              expect(day.exercises, isEmpty);
              continue;
            }

            expect(day.exercises.length, inInclusiveRange(5, 7));
            final dayIds = day.exercises
                .map((exercise) => exercise.exerciseId)
                .toList();
            expect(dayIds.toSet(), hasLength(dayIds.length));
            expect(dayIds.every(libraryIds.contains), isTrue);

            for (var index = 0; index < day.exercises.length; index++) {
              final prescribed = day.exercises[index];
              expect(prescribed.order, index);
              expect(prescribed.sets, inInclusiveRange(1, 6));
              expect(
                prescribed.repsLow,
                lessThanOrEqualTo(prescribed.repsHigh),
              );
              expect(prescribed.restSeconds, greaterThan(0));
            }

            final compounds = day.exercises
                .map(
                  (prescribed) => library
                      .firstWhere(
                        (exercise) => exercise.id == prescribed.exerciseId,
                      )
                      .isCompound,
                )
                .toList();
            final firstIsolation = compounds.indexOf(false);
            if (firstIsolation != -1) {
              expect(compounds.sublist(firstIsolation), everyElement(isFalse));
            }

            final primaryMuscles = day.exercises
                .map(
                  (prescribed) => library
                      .firstWhere(
                        (exercise) => exercise.id == prescribed.exerciseId,
                      )
                      .primaryMuscle,
                )
                .toSet();
            for (final group in day.muscleGroups) {
              expect(primaryMuscles, contains(group), reason: day.name);
            }
          }
        }
      }
    }
  });

  test('split names follow the day count table', () {
    const expected = <int, String>{
      1: 'Full Body',
      2: 'Full Body A / Full Body B',
      3: 'Push / Pull / Legs',
      4: 'Upper / Lower / Upper / Lower',
      5: 'Push / Pull / Legs / Upper / Lower',
      6: 'Push / Pull / Legs / Push / Pull / Legs',
      7: 'Push / Pull / Legs / Push / Pull / Legs / Active Recovery',
    };
    for (final entry in expected.entries) {
      final plan = generator().generate(
        goals: const <Goal>[Goal.buildMuscle],
        experienceLevel: ExperienceLevel.regular,
        daysPerWeek: entry.key,
        trainingDays: const <int>[1, 2, 3, 4, 5, 6, 7].sublist(0, entry.key),
      );
      expect(plan.splitName, entry.value);
    }
  });

  test('seven days end with an active recovery day', () {
    final plan = generator().generate(
      goals: const <Goal>[Goal.buildMuscle],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 7,
      trainingDays: const <int>[1, 2, 3, 4, 5, 6, 7],
    );

    expect(plan.days, hasLength(7));
    expect(plan.days.where((day) => day.exercises.isNotEmpty), hasLength(6));
    expect(plan.days.last.name, 'Active Recovery');
    expect(plan.days.last.exercises, isEmpty);
    expect(plan.days.last.estimatedMinutes, 20);
  });

  test('goal prescriptions match the week 1 table', () {
    for (final goal in Goal.values) {
      final plan = generator().generate(
        goals: <Goal>[goal],
        experienceLevel: ExperienceLevel.regular,
        daysPerWeek: 1,
        trainingDays: const <int>[1],
      );
      final prescriptions = plan.days.single.exercises;
      switch (goal) {
        case Goal.buildMuscle:
          expect(prescriptions.every((item) => item.sets == 3), isTrue);
          expect(prescriptions.every((item) => item.repsLow == 8), isTrue);
          expect(prescriptions.every((item) => item.repsHigh == 12), isTrue);
          expect(
            prescriptions.every(
              (item) => item.restSeconds >= 60 && item.restSeconds <= 90,
            ),
            isTrue,
          );
        case Goal.getStronger:
          expect(prescriptions.every((item) => item.sets == 4), isTrue);
          expect(prescriptions.every((item) => item.repsLow == 3), isTrue);
          expect(prescriptions.every((item) => item.repsHigh == 6), isTrue);
          expect(
            prescriptions.every(
              (item) => item.restSeconds >= 120 && item.restSeconds <= 180,
            ),
            isTrue,
          );
        case Goal.loseWeight:
          expect(prescriptions.every((item) => item.sets == 3), isTrue);
          expect(prescriptions.every((item) => item.repsLow == 12), isTrue);
          expect(prescriptions.every((item) => item.repsHigh == 15), isTrue);
          expect(
            prescriptions.every(
              (item) => item.restSeconds >= 45 && item.restSeconds <= 60,
            ),
            isTrue,
          );
        case Goal.stayHealthy:
          expect(prescriptions.every((item) => item.sets == 2), isTrue);
          expect(prescriptions.every((item) => item.repsLow == 10), isTrue);
          expect(prescriptions.every((item) => item.repsHigh == 15), isTrue);
          expect(prescriptions.every((item) => item.restSeconds == 60), isTrue);
      }
    }
  });

  test('experience levels adjust the first compound set count', () {
    int firstCompoundSets(ExperienceLevel level) {
      final plan = generator().generate(
        goals: const <Goal>[Goal.buildMuscle],
        experienceLevel: level,
        daysPerWeek: 1,
        trainingDays: const <int>[1],
      );
      final first = plan.days.single.exercises.first;
      final exercise = library.firstWhere(
        (item) => item.id == first.exerciseId,
      );
      expect(exercise.isCompound, isTrue);
      return first.sets;
    }

    expect(firstCompoundSets(ExperienceLevel.beginner), 2);
    expect(firstCompoundSets(ExperienceLevel.regular), 3);
    expect(firstCompoundSets(ExperienceLevel.gymRat), 4);
    expect(firstCompoundSets(ExperienceLevel.veteran), 4);
  });

  test('generation is deterministic for the same inputs', () {
    final first = generator().generate(
      goals: const <Goal>[Goal.buildMuscle, Goal.getStronger],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 3,
      trainingDays: const <int>[1, 3, 5],
    );
    final second = generator().generate(
      goals: const <Goal>[Goal.buildMuscle, Goal.getStronger],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 3,
      trainingDays: const <int>[1, 3, 5],
    );

    expect(first.toJson(), second.toJson());
    expect(first.goal, Goal.buildMuscle);
    expect(first.goals, <Goal>[Goal.buildMuscle, Goal.getStronger]);
  });

  test('empty goals fall back to build muscle and record a warning', () {
    final service = generator();
    final plan = service.generate(
      goals: const <Goal>[],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 2,
      trainingDays: const <int>[2, 4],
    );

    expect(plan.goal, Goal.buildMuscle);
    expect(plan.goals, isEmpty);
    expect(service.lastWarning, isNotNull);
    expect(plan.trainingDays, <int>[2, 4]);
  });

  test('missing weekdays are filled deterministically', () {
    final plan = generator().generate(
      goals: const <Goal>[Goal.buildMuscle],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 3,
      trainingDays: <int>[],
    );

    expect(plan.trainingDays, <int>[1, 3, 5]);
    expect(plan.days.map((day) => day.weekday), <int>[1, 3, 5]);
  });

  test('empty library returns a fallback Starter plan', () {
    final service = PlanGeneratorService(
      exercises: const <Exercise>[],
      now: () => fixedNow,
    );
    final plan = service.generate(
      goals: const <Goal>[Goal.getStronger],
      experienceLevel: ExperienceLevel.beginner,
      daysPerWeek: 3,
      trainingDays: const <int>[1, 3, 5],
    );

    expect(plan.isFallback, isTrue);
    expect(plan.splitName, 'Starter plan');
    expect(plan.daysPerWeek, 3);
    expect(plan.days, hasLength(3));
    expect(plan.days.every((day) => day.name == 'Full Body'), isTrue);
    expect(service.lastWarning, isNotNull);
  });

  test('out-of-range day counts recover with a clamped fallback', () {
    final plan = generator().generate(
      goals: const <Goal>[Goal.buildMuscle],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 9,
      trainingDays: <int>[],
    );

    expect(plan.isFallback, isTrue);
    expect(plan.splitName, 'Starter plan');
    expect(plan.daysPerWeek, 7);
    expect(plan.trainingDays, hasLength(7));
    expect(plan.days, hasLength(7));
    expect(plan.days.every((day) => day.name == 'Full Body'), isTrue);
  });

  test('fallback builds full body days for the requested weekdays', () {
    final plan = generator().fallback(
      goals: const <Goal>[Goal.loseWeight],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 2,
      trainingDays: const <int>[2, 4],
    );

    expect(plan.isFallback, isTrue);
    expect(plan.splitName, 'Starter plan');
    expect(plan.daysPerWeek, 2);
    expect(plan.days.map((day) => day.weekday), <int>[2, 4]);
    expect(plan.days, hasLength(2));
    for (final day in plan.days) {
      expect(day.exercises.length, inInclusiveRange(5, 7));
      expect(day.muscleGroups, isNotEmpty);
    }
  });

  test('fallback skip and recovery states stay valid', () {
    final plan = generator().fallback(
      goals: const <Goal>[Goal.stayHealthy],
      experienceLevel: ExperienceLevel.veteran,
      daysPerWeek: 1,
      trainingDays: const <int>[6],
    );

    expect(plan.generatedAt, fixedNow);
    expect(plan.days.single.weekday, 6);
    expect(plan.days.single.exercises, isNotEmpty);
  });
}
