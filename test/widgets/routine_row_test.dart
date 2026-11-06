import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/routine_exercise.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/routine_row.dart';

void main() {
  final now = DateTime.utc(2026, 11, 6, 12);
  final routine = Routine(
    id: 'routine-1',
    name: 'Push day',
    exercises: const <RoutineExercise>[
      RoutineExercise(
        exerciseId: 'barbell-bench-press',
        sets: 3,
        repsLow: 8,
        repsHigh: 10,
        restSeconds: 90,
        order: 0,
      ),
      RoutineExercise(
        exerciseId: 'dumbbell-fly',
        sets: 4,
        repsLow: 12,
        repsHigh: 12,
        restSeconds: 60,
        order: 1,
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('shows the routine name, exercise count, and chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: RoutineRow(routine: routine)),
      ),
    );

    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('2 exercises'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('uses the singular count and invokes the tap callback', (
    tester,
  ) async {
    var tapped = false;
    final single = routine.copyWith(
      exercises: <RoutineExercise>[routine.exercises.first],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: RoutineRow(routine: single, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('1 exercise'), findsOneWidget);
    await tester.tap(find.byType(RoutineRow));
    expect(tapped, isTrue);
  });
}
