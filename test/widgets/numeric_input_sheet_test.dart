import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/numeric_input_sheet.dart';

void main() {
  mainCalculator();

  testWidgets('returns a decimal value within bounds', (tester) async {
    double? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showNumericInputSheet(
                context,
                title: 'Edit weight',
                label: 'Weight (kg)',
                initialValue: 80,
                allowDecimal: true,
                max: 500,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit weight'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '82.5');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, 82.5);
  });

  testWidgets('stays open and shows an error for invalid input', (
    tester,
  ) async {
    double? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showNumericInputSheet(
                context,
                title: 'Edit reps',
                label: 'Reps',
                initialValue: 8,
                min: 1,
                max: 100,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a value from 1 to 100.'), findsOneWidget);
    expect(find.text('Edit reps'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('selects the current value so typing replaces it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              showNumericInputSheet(
                context,
                title: 'Edit weight',
                label: 'Weight (kg)',
                initialValue: 0,
                allowDecimal: true,
                max: 500,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '0');
    expect(
      field.controller!.selection,
      const TextSelection(baseOffset: 0, extentOffset: 1),
    );
  });
}

class _Capture {
  double? value;
}

Future<_Capture> _openCalculator(
  WidgetTester tester, {
  bool allowDecimal = true,
  double initialValue = 0,
  double min = 0,
  double max = 500,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final capture = _Capture();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            capture.value = await showNumericInputSheet(
              context,
              title: 'Edit weight',
              label: 'Weight (kg)',
              initialValue: initialValue,
              allowDecimal: allowDecimal,
              min: min,
              max: max,
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return capture;
}

Future<void> _tapKey(WidgetTester tester, String token) async {
  await tester.tap(find.byKey(ValueKey<String>('calc-key-$token')));
  await tester.pump();
}

void mainCalculator() {
  testWidgets('keypad evaluates an expression and shows a live result', (
    tester,
  ) async {
    final capture = await _openCalculator(tester);

    await _tapKey(tester, 'clear');
    for (final token in <String>['8', '0', '+', '2', '.', '5']) {
      await _tapKey(tester, token);
    }

    expect(find.byKey(const Key('numeric-calc-result')), findsOneWidget);
    expect(find.text('= 82.5'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(capture.value, 82.5);
  });

  testWidgets('keypad input replaces the selected starting value', (
    tester,
  ) async {
    await _openCalculator(tester, initialValue: 80);

    await _tapKey(tester, '7');

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '7');
  });

  testWidgets('equals replaces the expression with its result', (tester) async {
    final capture = await _openCalculator(tester);

    await _tapKey(tester, 'clear');
    for (final token in <String>['1', '0', '0', '+', '2', '5']) {
      await _tapKey(tester, token);
    }
    await _tapKey(tester, 'equals');

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '125');
    expect(find.byKey(const Key('numeric-calc-result')), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(capture.value, 125);
  });

  testWidgets('backspace and clear edit the expression', (tester) async {
    final capture = await _openCalculator(tester);

    await _tapKey(tester, 'clear');
    for (final token in <String>['1', '2', '3']) {
      await _tapKey(tester, token);
    }
    await _tapKey(tester, 'backspace');

    var field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '12');

    await _tapKey(tester, 'clear');
    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '');

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid number.'), findsOneWidget);
    expect(capture.value, isNull);
  });

  testWidgets('whole number fields reject fractional results', (tester) async {
    final capture = await _openCalculator(
      tester,
      allowDecimal: false,
      initialValue: 8,
      min: 1,
      max: 100,
    );

    expect(find.byKey(const ValueKey<String>('calc-key-.')), findsNothing);

    await _tapKey(tester, 'clear');
    for (final token in <String>['1', '0', '÷', '4']) {
      await _tapKey(tester, token);
    }
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a whole number.'), findsOneWidget);
    expect(capture.value, isNull);
  });
}
