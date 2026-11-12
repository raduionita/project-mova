import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/exercise_notes_sheet.dart';

Widget _wrap({required VoidCallback onOpen}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(onPressed: onOpen, child: const Text('Open note')),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('prefills the note and saves trimmed text', (tester) async {
    String? result;
    await tester.pumpWidget(
      _wrap(
        onOpen: () async {
          result = await showExerciseNotesSheet(
            tester.element(find.text('Open note')),
            exerciseName: 'Barbell Bench Press',
            initialNotes: 'Pause at the chest',
          );
        },
      ),
    );

    await tester.tap(find.text('Open note'));
    await tester.pumpAndSettle();

    expect(find.text('Note · Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pause at the chest'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('exercise-notes-field')),
      '  Pause at the chest  ',
    );
    await tester.tap(find.byKey(const Key('exercise-notes-save')));
    await tester.pumpAndSettle();

    expect(result, 'Pause at the chest');
    expect(find.byKey(const Key('exercise-notes-field')), findsNothing);
  });

  testWidgets('clears an existing note', (tester) async {
    String? result;
    await tester.pumpWidget(
      _wrap(
        onOpen: () async {
          result = await showExerciseNotesSheet(
            tester.element(find.text('Open note')),
            exerciseName: 'Barbell Bench Press',
            initialNotes: 'Pause at the chest',
          );
        },
      ),
    );

    await tester.tap(find.text('Open note'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise-notes-clear')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('exercise-notes-save')));
    await tester.pumpAndSettle();

    expect(result, '');
  });

  testWidgets('cancel returns null and keeps the note', (tester) async {
    String? result = 'unchanged';
    await tester.pumpWidget(
      _wrap(
        onOpen: () async {
          result = await showExerciseNotesSheet(
            tester.element(find.text('Open note')),
            exerciseName: 'Barbell Bench Press',
            initialNotes: 'Pause at the chest',
          );
        },
      ),
    );

    await tester.tap(find.text('Open note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
