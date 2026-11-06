import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_segmented_control.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  const options = <AppSegmentOption<String>>[
    AppSegmentOption<String>(value: 'kg', label: 'kg'),
    AppSegmentOption<String>(value: 'lb', label: 'lb'),
  ];

  testWidgets('renders every option and marks the selection', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppSegmentedControl<String>(
          options: options,
          selected: 'kg',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('kg'), findsOneWidget);
    expect(find.text('lb'), findsOneWidget);

    final selected = tester.widget<Text>(find.text('kg'));
    final unselected = tester.widget<Text>(find.text('lb'));
    expect(selected.style?.color, AppColors.lime);
    expect(unselected.style?.color, AppColors.muted);
  });

  testWidgets('tapping an option reports its value', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(
      _wrap(
        AppSegmentedControl<String>(
          options: options,
          selected: 'kg',
          onChanged: changes.add,
        ),
      ),
    );

    await tester.tap(find.text('lb'));
    expect(changes, <String>['lb']);
  });

  testWidgets('disabled control ignores taps and dims labels', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(
      _wrap(
        AppSegmentedControl<String>(
          options: options,
          selected: 'kg',
          onChanged: changes.add,
          enabled: false,
        ),
      ),
    );

    await tester.tap(find.text('lb'));
    expect(changes, isEmpty);

    final label = tester.widget<Text>(find.text('lb'));
    expect(label.style?.color, AppColors.textDisabled);
  });

  testWidgets('three unit rows can be built from the same control', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          children: <Widget>[
            AppSegmentedControl<String>(
              options: <AppSegmentOption<String>>[
                AppSegmentOption<String>(value: 'kg', label: 'kg'),
                AppSegmentOption<String>(value: 'lb', label: 'lb'),
              ],
              selected: 'kg',
              onChanged: _noop,
            ),
            AppSegmentedControl<String>(
              options: <AppSegmentOption<String>>[
                AppSegmentOption<String>(value: 'km', label: 'km'),
                AppSegmentOption<String>(value: 'mi', label: 'mi'),
              ],
              selected: 'mi',
              onChanged: _noop,
            ),
          ],
        ),
      ),
    );

    expect(find.text('kg'), findsOneWidget);
    expect(find.text('mi'), findsOneWidget);
    expect(tester.widget<Text>(find.text('mi')).style?.color, AppColors.lime);
  });
}

void _noop(String value) {}
