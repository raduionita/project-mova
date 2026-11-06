import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/numeric_input_sheet.dart';

void main() {
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
}
