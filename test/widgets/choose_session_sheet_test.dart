import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/split_style.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/choose_session_sheet.dart';

final DateTime _now = DateTime.utc(2026, 11, 12, 9);

PlanDay _day(int order, String name) {
  return PlanDay(
    id: 'day-${order + 1}',
    order: order,
    slotKey: <String>['push', 'pull', 'legs'][order % 3],
    name: name,
    muscleGroups: const <String>['Chest'],
    estimatedMinutes: 50,
    exercises: const [],
  );
}

TrainingPlan _plan() {
  return TrainingPlan(
    id: 'plan-1',
    goal: Goal.buildMuscle,
    experienceLevel: ExperienceLevel.regular,
    daysPerWeek: 3,
    splitStyle: SplitStyle.auto,
    splitName: 'Push / Pull / Legs',
    days: <PlanDay>[
      _day(0, 'Push Day'),
      _day(1, 'Pull Day'),
      _day(2, 'Leg Day'),
    ],
    generatedAt: _now,
  );
}

Routine _routine() {
  return Routine(
    id: 'routine-1',
    name: 'Lunch push',
    exercises: const [],
    createdAt: _now,
    updatedAt: _now,
  );
}

Widget _host({
  required TrainingPlan? plan,
  required List<Routine> routines,
  required int? nextIndex,
  required ValueChanged<PlanDay> onStartPlanDay,
  required ValueChanged<Routine> onStartRoutine,
  required VoidCallback onStartEmpty,
  required VoidCallback onStartWalk,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Builder(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('open-sheet'),
              onPressed: () => showChooseSessionSheet(
                context,
                plan: plan,
                routines: routines,
                nextIndex: nextIndex,
                onStartPlanDay: onStartPlanDay,
                onStartRoutine: onStartRoutine,
                onStartEmpty: onStartEmpty,
                onStartWalk: onStartWalk,
              ),
              child: const Text('Open'),
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('lists rotation sessions, routines, and quick starts', (
    tester,
  ) async {
    PlanDay? selectedDay;
    await tester.pumpWidget(
      _host(
        plan: _plan(),
        routines: <Routine>[_routine()],
        nextIndex: 0,
        onStartPlanDay: (day) => selectedDay = day,
        onStartRoutine: (_) {},
        onStartEmpty: () {},
        onStartWalk: () {},
      ),
    );
    await tester.tap(find.byKey(const Key('open-sheet')));
    await tester.pumpAndSettle();

    expect(find.text('Choose another session'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Pull Day'), findsOneWidget);
    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Lunch push'), findsOneWidget);
    expect(find.byKey(const Key('choose-session-empty')), findsOneWidget);
    expect(find.byKey(const Key('choose-session-walk')), findsOneWidget);

    await tester.tap(find.byKey(const Key('choose-session-day-1')));
    await tester.pumpAndSettle();

    expect(selectedDay?.name, 'Pull Day');
    expect(find.text('Choose another session'), findsNothing);
  });

  testWidgets('starts a routine and closes the sheet', (tester) async {
    Routine? selectedRoutine;
    await tester.pumpWidget(
      _host(
        plan: _plan(),
        routines: <Routine>[_routine()],
        nextIndex: 0,
        onStartPlanDay: (_) {},
        onStartRoutine: (routine) => selectedRoutine = routine,
        onStartEmpty: () {},
        onStartWalk: () {},
      ),
    );
    await tester.tap(find.byKey(const Key('open-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('choose-session-routine-routine-1')));
    await tester.pumpAndSettle();

    expect(selectedRoutine?.name, 'Lunch push');
    expect(find.text('Choose another session'), findsNothing);
  });

  testWidgets('quick starts report empty and walk', (tester) async {
    var emptyStarts = 0;
    var walkStarts = 0;
    await tester.pumpWidget(
      _host(
        plan: null,
        routines: const <Routine>[],
        nextIndex: null,
        onStartPlanDay: (_) {},
        onStartRoutine: (_) {},
        onStartEmpty: () => emptyStarts++,
        onStartWalk: () => walkStarts++,
      ),
    );
    await tester.tap(find.byKey(const Key('open-sheet')));
    await tester.pumpAndSettle();

    expect(find.text('Rotation'), findsNothing);
    expect(
      find.text('No saved workouts yet. Build one from the planner.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('choose-session-walk')));
    await tester.pumpAndSettle();
    expect(walkStarts, 1);

    await tester.tap(find.byKey(const Key('open-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('choose-session-empty')));
    await tester.pumpAndSettle();
    expect(emptyStarts, 1);
  });
}
