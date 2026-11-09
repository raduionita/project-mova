import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/widgets/stepper_row.dart';
import 'package:mova/widgets/app_icon.dart';

Finder _assetIcon(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == asset,
);

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('stepper increments and decrements within bounds', (
    tester,
  ) async {
    var value = 1;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return StepperRow(
              label: 'Days per week',
              value: value,
              min: 0,
              max: 2,
              onChanged: (next) => setState(() => value = next),
            );
          },
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    await tester.tap(_assetIcon(AppIcons.plus));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(_assetIcon(AppIcons.plus));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(_assetIcon(AppIcons.minus));
    await tester.pump();
    await tester.tap(_assetIcon(AppIcons.minus));
    await tester.pump();
    await tester.tap(_assetIcon(AppIcons.minus));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('long press repeats after 400 ms', (tester) async {
    var value = 1;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return StepperRow(
              label: 'Days per week',
              value: value,
              min: 0,
              max: 20,
              onChanged: (next) => setState(() => value = next),
            );
          },
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(_assetIcon(AppIcons.plus)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 450));
    expect(value, greaterThan(1));

    await gesture.up();
    await tester.pump();
    final stopped = value;
    await tester.pump(const Duration(milliseconds: 300));
    expect(value, stopped);
  });
}
