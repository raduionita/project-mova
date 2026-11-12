import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/weight_entry.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/weight_chart.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

WeightEntry _entry(String day, double kg) {
  return WeightEntry(
    dateKey: day,
    weightKg: kg,
    updatedAt: DateTime(2026, 11, 6),
  );
}

void main() {
  testWidgets('announces the lowest, highest, and latest weight', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        WeightChart(
          entries: <WeightEntry>[
            _entry('2026-11-01', 82),
            _entry('2026-11-03', 79.5),
            _entry('2026-11-06', 81),
          ],
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Weight trend, 3 entries. Lowest 79.5 kilograms, highest 82.0 '
        'kilograms, latest 81.0 kilograms.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('handles an empty log and a single entry', (tester) async {
    await tester.pumpWidget(_wrap(const WeightChart(entries: <WeightEntry>[])));
    expect(find.bySemanticsLabel('No weight entries yet'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        WeightChart(entries: <WeightEntry>[_entry('2026-11-06', 80)]),
      ),
    );
    expect(
      find.bySemanticsLabel('One weight entry: 80.0 kilograms'),
      findsOneWidget,
    );
  });
}
