import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/widgets/exercise_row.dart';
import 'package:mova/widgets/app_icon.dart';

Finder _assetIcon(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == asset,
);

Exercise _exercise() {
  return const Exercise(
    id: 'barbell-bench-press',
    name: 'Barbell Bench Press',
    primaryMuscle: 'Chest',
    equipment: 'Barbell',
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

void main() {
  testWidgets('shows name, muscle, equipment, and add affordance', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(ExerciseRow(exercise: _exercise())));

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Chest · Barbell'), findsOneWidget);
    expect(_assetIcon(AppIcons.plus), findsOneWidget);
    expect(find.byTooltip('Add Barbell Bench Press'), findsOneWidget);
  });

  testWidgets('add affordance reports taps', (tester) async {
    var adds = 0;
    await tester.pumpWidget(
      _wrap(ExerciseRow(exercise: _exercise(), onAdd: () => adds++)),
    );

    await tester.tap(_assetIcon(AppIcons.plus));

    expect(adds, 1);
  });

  testWidgets('added rows show Added and View instead of add', (tester) async {
    var views = 0;
    await tester.pumpWidget(
      _wrap(
        ExerciseRow(
          exercise: _exercise(),
          isAdded: true,
          onView: () => views++,
        ),
      ),
    );

    expect(
      find.byKey(const Key('exercise-added-barbell-bench-press')),
      findsOneWidget,
    );
    expect(find.text('Added'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(_assetIcon(AppIcons.plus), findsNothing);

    await tester.tap(find.byKey(const Key('exercise-view-barbell-bench-press')));
    expect(views, 1);
  });

  testWidgets('the row reports taps when onTap is provided', (tester) async {
    var opens = 0;
    await tester.pumpWidget(
      _wrap(ExerciseRow(exercise: _exercise(), onTap: () => opens++)),
    );

    await tester.tap(find.text('Barbell Bench Press'));

    expect(opens, 1);
  });
}
