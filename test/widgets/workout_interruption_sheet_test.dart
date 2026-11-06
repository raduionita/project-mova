import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/widgets/workout_interruption_sheet.dart';

void main() {
  Future<void> pumpLauncher(
    WidgetTester tester,
    void Function(WorkoutInterruptionAction?) onResult, {
    int completedSets = 0,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showWorkoutInterruptionSheet(
                  context,
                  completedSets: completedSets,
                );
                onResult(result);
              },
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pausing returns the pause action', (tester) async {
    WorkoutInterruptionAction? result;
    await pumpLauncher(tester, (value) => result = value);

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Workout in progress'), findsOneWidget);

    await tester.tap(find.text('Pause and exit'));
    await tester.pumpAndSettle();

    expect(result, WorkoutInterruptionAction.pause);
  });

  testWidgets('keeping training returns no action', (tester) async {
    WorkoutInterruptionAction? result;
    await pumpLauncher(tester, (value) => result = value);

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep training'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Workout in progress'), findsNothing);
  });

  testWidgets('discarding requires a second confirmation with set count', (
    tester,
  ) async {
    WorkoutInterruptionAction? result;
    await pumpLauncher(tester, (value) => result = value, completedSets: 2);

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard workout'));
    await tester.pumpAndSettle();

    expect(find.text('Discard this workout?'), findsOneWidget);
    expect(
      find.text('You will lose 2 completed sets. This cannot be undone.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep workout'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.text('Workout in progress'), findsOneWidget);

    await tester.tap(find.text('Discard workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(result, WorkoutInterruptionAction.discard);
    expect(find.text('Workout in progress'), findsNothing);
  });
}
