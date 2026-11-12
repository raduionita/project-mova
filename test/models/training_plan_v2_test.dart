import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/split_style.dart';
import 'package:mova/models/training_plan.dart';

Map<String, dynamic> _v1PlanJson() {
  PlanDay day(String id, int weekday, String name) {
    return PlanDay(
      schemaVersion: 1,
      id: id,
      weekday: weekday,
      name: name,
      muscleGroups: const <String>['Chest'],
      estimatedMinutes: 45,
      exercises: const <PlanExercise>[],
    );
  }

  return <String, dynamic>{
    'schemaVersion': 1,
    'id': 'plan-old',
    'goal': 'buildMuscle',
    'experienceLevel': 'beginner',
    'daysPerWeek': 3,
    'trainingDays': <int>[3, 5, 1],
    'splitName': 'Push / Pull / Legs',
    'days': <Map<String, dynamic>>[
      day('day-push', 3, 'Push').toJson(),
      day('day-pull', 5, 'Pull').toJson(),
      day('day-legs', 1, 'Legs').toJson(),
    ],
    'generatedAt': DateTime.utc(2026, 3, 1).toIso8601String(),
  };
}

void main() {
  test('v1 plans migrate to an ordered rotation with slot keys', () {
    final plan = TrainingPlan.fromJson(_v1PlanJson());

    expect(plan.schemaVersion, 2);
    expect(plan.days.map((day) => day.name), <String>['Legs', 'Push', 'Pull']);
    expect(plan.days.map((day) => day.id), <String>[
      'day-legs',
      'day-push',
      'day-pull',
    ]);
    expect(plan.days.map((day) => day.order), <int>[0, 1, 2]);
    expect(plan.days.map((day) => day.slotKey), <String>[
      'legs',
      'push',
      'pull',
    ]);
    expect(plan.days.every((day) => day.schemaVersion == 2), isTrue);
    expect(plan.trainingDays, <int>[3, 5, 1]);
  });

  test('v2 plans sort by order and keep stable slot keys', () {
    final plan = TrainingPlan.fromJson(<String, dynamic>{
      'schemaVersion': 2,
      'id': 'plan-new',
      'goal': 'buildMuscle',
      'experienceLevel': 'beginner',
      'daysPerWeek': 2,
      'splitStyle': 'fullBody',
      'splitName': 'Full Body',
      'days': <Map<String, dynamic>>[
        PlanDay(
          id: 'b',
          order: 1,
          slotKey: 'full-b',
          name: 'Full Body B',
          muscleGroups: const <String>['Chest'],
          estimatedMinutes: 40,
          exercises: const <PlanExercise>[],
        ).toJson(),
        PlanDay(
          id: 'a',
          order: 0,
          slotKey: 'full-a',
          name: 'Full Body A',
          muscleGroups: const <String>['Chest'],
          estimatedMinutes: 40,
          exercises: const <PlanExercise>[],
        ).toJson(),
      ],
      'generatedAt': DateTime.utc(2026, 3, 1).toIso8601String(),
    });

    expect(plan.id, 'plan-new');
    expect(plan.splitStyle, SplitStyle.fullBody);
    expect(plan.trainingDays, isEmpty);
    expect(plan.days.map((day) => day.id), <String>['a', 'b']);
    expect(plan.days.map((day) => day.slotKey), <String>['full-a', 'full-b']);
    expect(plan.toJson().containsKey('trainingDays'), isFalse);
  });

  test('slot keys are stable for every rotation length', () {
    expect(planSlotKeyFor(name: 'Full Body', order: 0, count: 1), 'full');

    expect(
      <String>[
        for (var index = 0; index < 2; index++)
          planSlotKeyFor(
            name: 'Full Body ${index == 0 ? 'A' : 'B'}',
            order: index,
            count: 2,
          ),
      ],
      <String>['full-a', 'full-b'],
    );

    expect(
      <String>[
        for (var index = 0; index < 3; index++)
          planSlotKeyFor(
            name: <String>['Push', 'Pull', 'Legs'][index],
            order: index,
            count: 3,
          ),
      ],
      <String>['push', 'pull', 'legs'],
    );

    expect(
      <String>[
        for (var index = 0; index < 4; index++)
          planSlotKeyFor(
            name: <String>['Upper A', 'Lower A', 'Upper B', 'Lower B'][index],
            order: index,
            count: 4,
          ),
      ],
      <String>['upper-a', 'lower-a', 'upper-b', 'lower-b'],
    );

    expect(
      <String>[
        for (var index = 0; index < 5; index++)
          planSlotKeyFor(
            name: <String>['Push', 'Pull', 'Legs', 'Upper', 'Lower'][index],
            order: index,
            count: 5,
          ),
      ],
      <String>['push', 'pull', 'legs', 'upper', 'lower'],
    );

    expect(
      <String>[
        for (var index = 0; index < 6; index++)
          planSlotKeyFor(
            name: <String>[
              'Push',
              'Pull',
              'Legs',
              'Push',
              'Pull',
              'Legs',
            ][index],
            order: index,
            count: 6,
          ),
      ],
      <String>['push-a', 'pull-a', 'legs-a', 'push-b', 'pull-b', 'legs-b'],
    );

    expect(
      <String>[
        for (var index = 0; index < 7; index++)
          planSlotKeyFor(
            name: <String>[
              'Push',
              'Pull',
              'Legs',
              'Push',
              'Pull',
              'Legs',
              'Active Recovery',
            ][index],
            order: index,
            count: 7,
          ),
      ],
      <String>[
        'push-a',
        'pull-a',
        'legs-a',
        'push-b',
        'pull-b',
        'legs-b',
        'recovery',
      ],
    );
  });

  test('explicit split styles produce their own slot keys', () {
    expect(
      planSlotKeyFor(
        name: 'Legs',
        order: 2,
        count: 6,
        splitStyle: SplitStyle.ppl,
      ),
      'legs-a',
    );
    expect(
      planSlotKeyFor(
        name: 'Lower A',
        order: 1,
        count: 4,
        splitStyle: SplitStyle.upperLower,
      ),
      'lower-a',
    );
    expect(
      planSlotKeyFor(
        name: 'Full Body C',
        order: 2,
        count: 3,
        splitStyle: SplitStyle.fullBody,
      ),
      'full-c',
    );
  });
}
