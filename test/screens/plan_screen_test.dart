import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/split_style.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/screens/plan/plan_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime.utc(2026, 11, 12, 9);

PlanDay _day(int order, String name, List<String> muscles) {
  return PlanDay(
    id: 'day-${order + 1}',
    order: order,
    slotKey: <String>['push', 'pull', 'legs'][order % 3],
    name: name,
    muscleGroups: muscles,
    estimatedMinutes: 50,
    exercises: const [],
  );
}

TrainingPlan _plan() {
  return TrainingPlan(
    id: 'plan-1',
    goal: Goal.buildMuscle,
    goals: const <Goal>[Goal.buildMuscle],
    experienceLevel: ExperienceLevel.regular,
    daysPerWeek: 3,
    splitName: 'Push / Pull / Legs',
    days: <PlanDay>[
      _day(0, 'Push', const <String>['Chest', 'Shoulders']),
      _day(1, 'Pull', const <String>['Back', 'Biceps']),
      _day(2, 'Legs', const <String>['Quads', 'Glutes']),
    ],
    generatedAt: _now,
  );
}

Future<void> _openPlan(WidgetTester tester, StorageService storage) async {
  await tester.pumpWidget(MovaApp(storage: storage, clock: FakeClock(_now)));
  await tester.pumpAndSettle();
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.pushNamed(Routes.plan);
  await tester.pumpAndSettle();
}

PlanProvider _plans(WidgetTester tester) {
  return tester.element(find.byType(PlanScreen)).read<PlanProvider>();
}

void main() {
  testWidgets('frequency and split changes wait for regenerate', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(kPlanKey, _plan().toJson());
    await _openPlan(tester, storage);

    expect(find.text('Your rotation'), findsOneWidget);
    expect(_plans(tester).plan!.daysPerWeek, 3);

    await tester.tap(find.byKey(const Key('plan-frequency-4')));
    await tester.pumpAndSettle();
    expect(_plans(tester).plan!.daysPerWeek, 3);
    expect(find.textContaining('Changes apply only'), findsOneWidget);

    await tester.tap(find.byKey(const Key('plan-split-fullBody')));
    await tester.pumpAndSettle();
    expect(_plans(tester).plan!.splitStyle, SplitStyle.auto);

    await tester.ensureVisible(find.byKey(const Key('plan-regenerate')));
    await tester.tap(find.byKey(const Key('plan-regenerate')));
    await tester.pumpAndSettle();
    expect(find.text('Regenerate rotation?'), findsOneWidget);

    await tester.tap(find.text('Regenerate'));
    await tester.pumpAndSettle();

    final plan = _plans(tester).plan!;
    expect(plan.daysPerWeek, 4);
    expect(plan.splitStyle, SplitStyle.fullBody);
    expect(find.textContaining('Day 1 is next'), findsOneWidget);
  });

  testWidgets('reorder moves a rotation session', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(kPlanKey, _plan().toJson());
    await _openPlan(tester, storage);

    await tester.ensureVisible(find.byKey(const Key('plan-day-down-1')));
    await tester.tap(find.byKey(const Key('plan-day-down-1')));
    await tester.pumpAndSettle();

    expect(_plans(tester).plan!.days.map((day) => day.name), <String>[
      'Pull',
      'Push',
      'Legs',
    ]);
    expect(_plans(tester).plan!.days.map((day) => day.order), <int>[0, 1, 2]);
  });

  testWidgets('starting a plan session opens the logger', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(kPlanKey, _plan().toJson());
    await _openPlan(tester, storage);

    await tester.ensureVisible(find.byKey(const Key('plan-day-start-1')));
    await tester.tap(find.byKey(const Key('plan-day-start-1')));
    await tester.pumpAndSettle();

    final workout = tester
        .element(find.byType(Navigator).first)
        .read<WorkoutProvider>();
    expect(workout.activeSession?.displayTitle, 'Push');
  });

  testWidgets('routines can be started from the planner', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(kPlanKey, _plan().toJson());
    final routine = Routine(
      id: 'routine-1',
      name: 'Lunch push',
      exercises: const [],
      createdAt: _now,
      updatedAt: _now,
    );
    await storage.writeList(kRoutinesKey, <Map<String, dynamic>>[
      routine.toJson(),
    ]);
    await _openPlan(tester, storage);

    expect(find.text('Lunch push'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('plan-routine-start-routine-1')),
    );
    await tester.tap(find.byKey(const Key('plan-routine-start-routine-1')));
    await tester.pumpAndSettle();

    final workout = tester
        .element(find.byType(Navigator).first)
        .read<WorkoutProvider>();
    expect(workout.activeSession?.displayTitle, 'Lunch push');
  });
}
