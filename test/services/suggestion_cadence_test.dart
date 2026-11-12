import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/services/suggestion_cadence.dart';

PlanDay _day(int order, String name, String slotKey) {
  return PlanDay(
    id: 'day-${order + 1}',
    order: order,
    slotKey: slotKey,
    name: name,
    muscleGroups: const <String>[],
    estimatedMinutes: 50,
    exercises: const <PlanExercise>[],
  );
}

TrainingPlan _plan({required int daysPerWeek, required List<PlanDay> days}) {
  return TrainingPlan(
    id: 'plan-1',
    goal: Goal.buildMuscle,
    experienceLevel: ExperienceLevel.regular,
    daysPerWeek: daysPerWeek,
    splitName: 'Rotation',
    days: days,
    generatedAt: DateTime(2026, 11, 1, 8),
  );
}

void main() {
  const cadence = SuggestionCadence();
  final from = DateTime(2026, 11, 12, 15, 30);

  test('a three day plan suggests every other day', () {
    final plan = _plan(
      daysPerWeek: 3,
      days: <PlanDay>[
        _day(0, 'Push', 'push'),
        _day(1, 'Pull', 'pull'),
        _day(2, 'Legs', 'legs'),
      ],
    );

    final suggestions = cadence.next(plan: plan, startIndex: 1, from: from);

    expect(suggestions, hasLength(3));
    expect(suggestions.map((suggestion) => suggestion.date), <DateTime>[
      DateTime(2026, 11, 14),
      DateTime(2026, 11, 16),
      DateTime(2026, 11, 18),
    ]);
    expect(suggestions.map((suggestion) => suggestion.day.name), <String>[
      'Pull',
      'Legs',
      'Push',
    ]);
    expect(suggestions.map((suggestion) => suggestion.dayIndex), <int>[
      1,
      2,
      0,
    ]);
  });

  test('a one day plan suggests once a week', () {
    final plan = _plan(
      daysPerWeek: 1,
      days: <PlanDay>[_day(0, 'Full', 'full')],
    );

    final suggestions = cadence.next(plan: plan, startIndex: 0, from: from);

    expect(suggestions.map((suggestion) => suggestion.date), <DateTime>[
      DateTime(2026, 11, 19),
      DateTime(2026, 11, 26),
      DateTime(2026, 12, 3),
    ]);
  });

  test('count controls how many suggestions are returned', () {
    final plan = _plan(
      daysPerWeek: 3,
      days: <PlanDay>[
        _day(0, 'Push', 'push'),
        _day(1, 'Pull', 'pull'),
        _day(2, 'Legs', 'legs'),
      ],
    );

    expect(
      cadence.next(plan: plan, startIndex: 0, from: from, count: 0),
      isEmpty,
    );
    expect(
      cadence.next(plan: plan, startIndex: 0, from: from, count: 1),
      hasLength(1),
    );
  });

  test('an empty plan returns no suggestions', () {
    final plan = _plan(daysPerWeek: 3, days: const <PlanDay>[]);

    expect(cadence.next(plan: plan, startIndex: 0, from: from), isEmpty);
  });
}
