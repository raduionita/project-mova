import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/day_selector.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('tapping a day toggles it and keeps days sorted', (tester) async {
    var selected = <int>[1];
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (context, setState) {
            return DaySelector(
              selectedDays: selected,
              onChanged: (days) => setState(() => selected = days),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('T').at(0));
    await tester.pump();
    expect(selected, <int>[1, 2]);

    await tester.tap(find.text('M'));
    await tester.pump();
    expect(selected, <int>[2]);
  });

  testWidgets('selected days use lime soft surface', (tester) async {
    await tester.pumpWidget(
      _wrap(const DaySelector(selectedDays: <int>[1, 3, 5])),
    );

    final materials = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(DaySelector),
            matching: find.byType(Material),
          ),
        )
        .toList();
    expect(materials, hasLength(7));
    expect(materials[0].color, AppColors.limeSoft);
    expect(materials[1].color, AppColors.dayCell);
    expect(materials[2].color, AppColors.limeSoft);
  });

  testWidgets('disabled selector does not change', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _wrap(
        DaySelector(
          selectedDays: const <int>[1],
          enabled: false,
          onChanged: (_) => calls++,
        ),
      ),
    );

    await tester.tap(find.text('T').at(0));
    expect(calls, 0);
  });
}
