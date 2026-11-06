import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_wheel_picker.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: SizedBox(width: 160, child: child)),
  );
}

Semantics _wheelSemantics(WidgetTester tester) {
  return tester.widget<Semantics>(
    find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Wheel picker',
    ),
  );
}

void main() {
  const values = <String>['Sep', 'Oct', 'Nov', 'Dec', 'Jan'];

  testWidgets('renders the list and the initial selection', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppWheelPicker(
          values: values,
          selectedIndex: 2,
          onSelectedIndexChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListWheelScrollView), findsOneWidget);
    expect(find.text('Nov'), findsWidgets);
    expect(_wheelSemantics(tester).properties.value, 'Nov');
  });

  testWidgets('scrolling reports the new index', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(
      _wrap(
        AppWheelPicker(
          values: values,
          selectedIndex: 2,
          onSelectedIndexChanged: changes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -56));
    await tester.pumpAndSettle();

    expect(changes, isNotEmpty);
    expect(changes.last, greaterThan(2));
    expect(_wheelSemantics(tester).properties.value, values[changes.last]);
  });

  testWidgets('external selection moves the wheel', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppWheelPicker(
          values: values,
          selectedIndex: 0,
          onSelectedIndexChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_wheelSemantics(tester).properties.value, 'Sep');

    await tester.pumpWidget(
      _wrap(
        AppWheelPicker(
          values: values,
          selectedIndex: 3,
          onSelectedIndexChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_wheelSemantics(tester).properties.value, 'Dec');
  });

  testWidgets('clamps out-of-range selections', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppWheelPicker(
          values: values,
          selectedIndex: 99,
          onSelectedIndexChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_wheelSemantics(tester).properties.value, 'Jan');
  });

  testWidgets('empty values render an empty box', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppWheelPicker(
          values: const <String>[],
          selectedIndex: 0,
          onSelectedIndexChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(ListWheelScrollView), findsNothing);
  });
}
