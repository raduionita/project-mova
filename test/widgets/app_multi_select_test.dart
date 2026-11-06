import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_multi_select.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

const _options = <AppMultiSelectOption<String>>[
  AppMultiSelectOption<String>(
    value: 'muscle',
    label: 'Build muscle',
    description: 'Add size with steady volume.',
    icon: Icons.fitness_center,
  ),
  AppMultiSelectOption<String>(
    value: 'strong',
    label: 'Get stronger',
    description: 'Lift heavier with low reps.',
    icon: Icons.trending_up,
  ),
  AppMultiSelectOption<String>(
    value: 'weight',
    label: 'Lose weight',
    description: 'Burn energy with higher reps.',
    icon: Icons.local_fire_department,
  ),
];

Widget _harness(List<String> current, ValueChanged<List<String>> onChanged) {
  return _wrap(
    StatefulBuilder(
      builder: (context, setState) {
        return AppMultiSelect<String>(
          options: _options,
          selected: current,
          onChanged: (next) {
            setState(() => current = next);
            onChanged(next);
          },
        );
      },
    ),
  );
}

void main() {
  testWidgets('renders every option with descriptions and icons', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(<String>[], (_) {}));

    expect(find.text('Build muscle'), findsOneWidget);
    expect(find.text('Get stronger'), findsOneWidget);
    expect(find.text('Lose weight'), findsOneWidget);
    expect(find.text('Add size with steady volume.'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.text('Primary'), findsNothing);
  });

  testWidgets('selection order decides the primary goal', (tester) async {
    final changes = <List<String>>[];
    final current = <String>[];
    await tester.pumpWidget(_harness(current, changes.add));

    await tester.tap(find.text('Get stronger'));
    await tester.pumpAndSettle();
    expect(changes.last, <String>['strong']);
    expect(find.text('Primary'), findsOneWidget);

    await tester.tap(find.text('Build muscle'));
    await tester.pumpAndSettle();
    expect(changes.last, <String>['strong', 'muscle']);

    final primaryCard = find.ancestor(
      of: find.text('Primary'),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(
        of: primaryCard.first,
        matching: find.text('Get stronger'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('deselecting the primary promotes the next goal', (tester) async {
    final changes = <List<String>>[];
    await tester.pumpWidget(_harness(<String>[], changes.add));

    await tester.tap(find.text('Build muscle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get stronger'));
    await tester.pumpAndSettle();

    expect(changes.last, <String>['muscle', 'strong']);

    await tester.tap(find.text('Build muscle'));
    await tester.pumpAndSettle();

    expect(changes.last, <String>['strong']);
    expect(find.text('Primary'), findsOneWidget);
  });

  testWidgets('deselecting every goal removes the primary tag', (tester) async {
    final changes = <List<String>>[];
    await tester.pumpWidget(_harness(<String>[], changes.add));

    await tester.tap(find.text('Lose weight'));
    await tester.pumpAndSettle();
    expect(find.text('Primary'), findsOneWidget);

    await tester.tap(find.text('Lose weight'));
    await tester.pumpAndSettle();

    expect(changes.last, isEmpty);
    expect(find.text('Primary'), findsNothing);
  });

  testWidgets('disabled multi-select ignores taps', (tester) async {
    final changes = <List<String>>[];
    await tester.pumpWidget(
      _wrap(
        AppMultiSelect<String>(
          options: _options,
          selected: const <String>[],
          onChanged: changes.add,
          enabled: false,
        ),
      ),
    );

    await tester.tap(find.text('Build muscle'));
    expect(changes, isEmpty);
  });
}
