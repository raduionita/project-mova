import 'package:flutter_test/flutter_test.dart';

import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/services/session_suggestion_service.dart';

const _generatedAt = '2026-11-01T08:00:00.000';

PlanDay _day({
  required int order,
  required String name,
  required String slotKey,
  List<String> muscles = const <String>[],
}) {
  return PlanDay(
    id: 'day-${order + 1}',
    order: order,
    slotKey: slotKey,
    name: name,
    muscleGroups: muscles,
    estimatedMinutes: 50,
    exercises: const <PlanExercise>[],
  );
}

TrainingPlan _plan({List<PlanDay>? days, int daysPerWeek = 3}) {
  return TrainingPlan(
    id: 'plan-1',
    goal: Goal.buildMuscle,
    experienceLevel: ExperienceLevel.regular,
    daysPerWeek: daysPerWeek,
    splitName: 'Rotation',
    days:
        days ??
        <PlanDay>[
          _day(
            order: 0,
            name: 'Push',
            slotKey: 'push',
            muscles: <String>['Chest'],
          ),
          _day(
            order: 1,
            name: 'Pull',
            slotKey: 'pull',
            muscles: <String>['Back'],
          ),
          _day(
            order: 2,
            name: 'Legs',
            slotKey: 'legs',
            muscles: <String>['Legs'],
          ),
        ],
    generatedAt: DateTime.parse(_generatedAt),
  );
}

WorkoutSession _session({
  required String id,
  required String title,
  required String slotKey,
  required DateTime completedAt,
  SessionSource source = SessionSource.plan,
  SessionStatus status = SessionStatus.completed,
  String? planDayId,
  List<String> muscles = const <String>[],
}) {
  return WorkoutSession(
    id: id,
    name: title,
    displayTitle: title,
    source: source,
    planDayId: planDayId,
    slotKey: slotKey,
    muscleGroups: muscles,
    startedAt: completedAt.subtract(const Duration(minutes: 45)),
    completedAt: completedAt,
    status: status,
    exercises: const <SessionExercise>[],
  );
}

void main() {
  const service = SessionSuggestionService();
  final now = DateTime(2026, 11, 12, 12);

  test('returns null without a plan or sessions', () {
    expect(
      service.suggest(plan: null, history: const <WorkoutSession>[], now: now),
      isNull,
    );
    expect(
      service.suggest(
        plan: _plan(days: const <PlanDay>[]),
        history: const <WorkoutSession>[],
        now: now,
      ),
      isNull,
    );
  });

  test('starts at Day 1 without completed plan history', () {
    final suggestion = service.suggest(
      plan: _plan(),
      history: const <WorkoutSession>[],
      now: now,
    );
    expect(suggestion?.day.name, 'Push');
    expect(suggestion?.dayIndex, 0);
    expect(suggestion?.reason, 'Start your rotation with Day 1.');
    expect(suggestion?.recoveryWarning, isNull);
  });

  test('advances to the slot after the last completed plan session', () {
    final suggestion = service.suggest(
      plan: _plan(),
      history: <WorkoutSession>[
        _session(
          id: 's1',
          title: 'Push',
          slotKey: 'push',
          completedAt: DateTime(2026, 11, 10, 18),
        ),
      ],
      now: now,
    );
    expect(suggestion?.day.name, 'Pull');
    expect(suggestion?.dayIndex, 1);
    expect(suggestion?.reason, 'Because you trained Push 2 days ago');
    expect(suggestion?.lastSession?.id, 's1');
  });

  test('wraps from the last slot back to Day 1', () {
    final suggestion = service.suggest(
      plan: _plan(),
      history: <WorkoutSession>[
        _session(
          id: 's1',
          title: 'Legs',
          slotKey: 'legs',
          completedAt: DateTime(2026, 11, 11, 18),
        ),
      ],
      now: now,
    );
    expect(suggestion?.day.name, 'Push');
    expect(suggestion?.dayIndex, 0);
  });

  test('ignores sessions completed before the plan was generated', () {
    final suggestion = service.suggest(
      plan: _plan(),
      history: <WorkoutSession>[
        _session(
          id: 's1',
          title: 'Pull',
          slotKey: 'pull',
          completedAt: DateTime(2026, 10, 20, 18),
        ),
      ],
      now: now,
    );
    expect(suggestion?.day.name, 'Push');
    expect(suggestion?.lastSession, isNull);
  });

  test('ignores routines, empty workouts, walks, and active sessions', () {
    final suggestion = service.suggest(
      plan: _plan(),
      history: <WorkoutSession>[
        _session(
          id: 'routine',
          title: 'Routine',
          slotKey: 'pull',
          source: SessionSource.routine,
          completedAt: DateTime(2026, 11, 10, 18),
        ),
        _session(
          id: 'empty',
          title: 'Empty',
          slotKey: 'pull',
          source: SessionSource.empty,
          completedAt: DateTime(2026, 11, 10, 19),
        ),
        _session(
          id: 'walk',
          title: 'Walk',
          slotKey: 'pull',
          source: SessionSource.walk,
          completedAt: DateTime(2026, 11, 10, 20),
        ),
        _session(
          id: 'active',
          title: 'Push',
          slotKey: 'push',
          status: SessionStatus.active,
          completedAt: DateTime(2026, 11, 11, 18),
        ),
      ],
      now: now,
    );
    expect(suggestion?.day.name, 'Push');
    expect(suggestion?.lastSession, isNull);
  });

  test('falls back to Day 1 when the last slot no longer exists', () {
    final suggestion = service.suggest(
      plan: _plan(
        days: <PlanDay>[
          _day(order: 0, name: 'Upper', slotKey: 'upper-a'),
          _day(order: 1, name: 'Lower', slotKey: 'lower-a'),
        ],
        daysPerWeek: 2,
      ),
      history: <WorkoutSession>[
        _session(
          id: 's1',
          title: 'Legs',
          slotKey: 'legs',
          completedAt: DateTime(2026, 11, 10, 18),
        ),
      ],
      now: now,
    );
    expect(suggestion?.day.name, 'Upper');
    expect(suggestion?.dayIndex, 0);
  });

  test('uses the reordered rotation and the same last slot', () {
    final suggestion = service.suggest(
      plan: _plan(
        days: <PlanDay>[
          _day(order: 0, name: 'Pull', slotKey: 'pull'),
          _day(order: 1, name: 'Legs', slotKey: 'legs'),
          _day(order: 2, name: 'Push', slotKey: 'push'),
        ],
      ),
      history: <WorkoutSession>[
        _session(
          id: 's1',
          title: 'Pull',
          slotKey: 'pull',
          completedAt: DateTime(2026, 11, 10, 18),
        ),
      ],
      now: now,
    );
    expect(suggestion?.day.name, 'Legs');
    expect(suggestion?.dayIndex, 1);
  });

  test('warns about same-day training without blocking the suggestion', () {
    final suggestion = service.suggest(
      plan: _plan(),
      history: <WorkoutSession>[
        _session(
          id: 's1',
          title: 'Push',
          slotKey: 'push',
          completedAt: DateTime(2026, 11, 12, 7),
        ),
      ],
      now: now,
    );
    expect(suggestion?.day.name, 'Pull');
    expect(
      suggestion?.recoveryWarning,
      'You trained Push today. This is a suggestion, not a block.',
    );
  });

  test('no recovery warning after a different day', () {
    final suggestion = service.suggest(
      plan: _plan(),
      history: <WorkoutSession>[
        _session(
          id: 's1',
          title: 'Push',
          slotKey: 'push',
          completedAt: DateTime(2026, 11, 11, 7),
        ),
      ],
      now: now,
    );
    expect(suggestion?.recoveryWarning, isNull);
  });

  test('mentions a neglected muscle after 7 days', () {
    final suggestion = service.suggest(
      plan: _plan(
        days: <PlanDay>[
          _day(
            order: 0,
            name: 'Chest',
            slotKey: 'full',
            muscles: <String>['Chest'],
          ),
        ],
        daysPerWeek: 1,
      ),
      history: <WorkoutSession>[
        _session(
          id: 's1',
          title: 'Chest',
          slotKey: 'full',
          completedAt: DateTime(2026, 11, 4, 18),
          muscles: const <String>['Chest'],
        ),
      ],
      now: now,
    );
    expect(suggestion?.reason, 'You have not trained chest in 8 days');
  });
}
