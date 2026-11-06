import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_chip.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('unselected chip uses line border and text color', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AppChip(label: 'All')));

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppChip),
        matching: find.byType(Material),
      ),
    );
    final shape = material.shape! as RoundedRectangleBorder;
    final text = tester.widget<Text>(find.text('All'));
    expect(material.color, Colors.transparent);
    expect(shape.side.color, AppColors.line);
    expect(text.style?.color, AppColors.text);
  });

  testWidgets('selected chip uses lime soft background and lime border', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AppChip(label: 'Chest', selected: true)),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppChip),
        matching: find.byType(Material),
      ),
    );
    final shape = material.shape! as RoundedRectangleBorder;
    final text = tester.widget<Text>(find.text('Chest'));
    expect(material.color, AppColors.limeSoft);
    expect(shape.side.color, AppColors.limeBorder45);
    expect(text.style?.color, AppColors.lime);
  });

  testWidgets('chip calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(AppChip(label: 'All', onTap: () => taps++)));

    await tester.tap(find.text('All'));
    expect(taps, 1);
  });
}
