import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/plate_calculator_sheet.dart';

Widget _launcher({required WeightUnit unit, double targetWeight = 0}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: TextButton(
              onPressed: () => showPlateCalculatorSheet(
                context,
                unit: unit,
                exerciseName: 'Barbell Bench Press',
                targetWeight: targetWeight,
              ),
              child: const Text('Open calculator'),
            ),
          );
        },
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester, {
  WeightUnit unit = WeightUnit.kg,
  double targetWeight = 0,
}) async {
  await tester.pumpWidget(_launcher(unit: unit, targetWeight: targetWeight));
  await tester.tap(find.text('Open calculator'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows an exact 100 kg load with a 20 kg bar', (tester) async {
    await _open(tester);

    await tester.enterText(find.byKey(const Key('plate-target')), '100');
    await tester.pump();

    expect(find.text('Plate calculator'), findsOneWidget);
    expect(find.text('Exact load'), findsOneWidget);
    expect(find.text('25 kg'), findsOneWidget);
    expect(find.text('15 kg'), findsOneWidget);
    expect(find.text('100 kg'), findsOneWidget);
  });

  testWidgets('shows an exact 225 lb load with a 45 lb bar', (tester) async {
    await _open(tester, unit: WeightUnit.lb);

    await tester.enterText(find.byKey(const Key('plate-target')), '225');
    await tester.pump();

    expect(find.text('Exact load'), findsOneWidget);
    expect(find.text('45 lb'), findsWidgets);
    expect(find.text('225 lb'), findsOneWidget);
  });

  testWidgets('reports the closest loadable weight', (tester) async {
    await _open(tester);

    await tester.enterText(find.byKey(const Key('plate-target')), '103');
    await tester.pump();

    expect(find.textContaining('Closest loadable.'), findsOneWidget);
    expect(find.textContaining('0.5 kg short'), findsOneWidget);
  });

  testWidgets('explains targets below the bar and invalid input', (
    tester,
  ) async {
    await _open(tester);

    await tester.enterText(find.byKey(const Key('plate-target')), '10');
    await tester.pump();
    expect(find.textContaining('below the 20 kg bar'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('plate-target')), '999');
    await tester.pump();
    expect(find.textContaining('Enter a target between'), findsOneWidget);
  });

  testWidgets('keypad evaluates a target expression', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _open(tester);

    for (final token in <String>['clear', '5', '0', '×', '2']) {
      await tester.tap(find.byKey(ValueKey<String>('calc-key-$token')));
      await tester.pump();
    }

    expect(find.byKey(const Key('plate-target-calc-result')), findsOneWidget);
    expect(find.text('= 100 kg'), findsOneWidget);
    expect(find.text('Exact load'), findsOneWidget);
    expect(find.text('100 kg'), findsOneWidget);
  });

  testWidgets('closes without changing anything', (tester) async {
    await _open(tester);
    await tester.tap(find.byTooltip('Close plate calculator'));
    await tester.pumpAndSettle();

    expect(find.text('Plate calculator'), findsNothing);
    expect(find.text('Open calculator'), findsOneWidget);
  });
}
