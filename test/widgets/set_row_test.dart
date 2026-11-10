import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/widgets/set_row.dart';
import 'package:mova/widgets/app_icon.dart';

Finder _assetIcon(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == asset,
);

WorkoutSet _set({
  int index = 0,
  double weightKg = 0,
  int reps = 8,
  bool warmup = false,
  bool completed = false,
}) {
  return WorkoutSet(
    id: 'set-$index',
    index: index,
    weightKg: weightKg,
    reps: reps,
    isWarmup: warmup,
    completed: completed,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('shows set number, previous value, and current value', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SetRow(
          set: _set(),
          previous: _set(weightKg: 80, reps: 8, completed: true),
          unitLabel: 'kg',
          onEditWeight: () {},
          onEditReps: () {},
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('80 × 8'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byTooltip('Edit weight for set 1'),
        matching: find.text('-'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byTooltip('Edit reps for set 1'),
        matching: find.text('8'),
      ),
      findsOneWidget,
    );

    final previous = tester.widget<Text>(find.text('80 × 8'));
    expect(previous.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('exposes edit, complete, warm-up, and remove actions', (
    tester,
  ) async {
    var edits = 0;
    var completes = 0;
    var warmups = 0;
    var removes = 0;

    await tester.pumpWidget(
      _wrap(
        SetRow(
          set: _set(),
          unitLabel: 'kg',
          active: true,
          onEdit: () => edits++,
          onToggleComplete: () => completes++,
          onToggleWarmup: () => warmups++,
          onRemove: () => removes++,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Edit set 1'));
    await tester.tap(find.byTooltip('Complete set 1'));
    await tester.tap(find.byTooltip('Toggle warm-up for set 1'));
    await tester.drag(find.byType(SetRow), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(edits, 1);
    expect(completes, 1);
    expect(warmups, 1);
    expect(removes, 1);
  });

  testWidgets('a completed warm-up set shows its state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SetRow(
          set: _set(warmup: true, completed: true, weightKg: 40, reps: 10),
          unitLabel: 'kg',
        ),
      ),
    );

    expect(_assetIcon(AppIcons.check), findsOneWidget);
    final semantics = tester.getSemantics(
      find
          .byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.label != null,
          )
          .first,
    );
    expect(semantics.label, contains('warm-up'));
    expect(semantics.label, contains('completed'));
  });
}
