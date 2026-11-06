import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_button.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('primary button calls onPressed', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      _wrap(AppButton(label: 'Save', onPressed: () => pressed++)),
    );

    await tester.tap(find.text('Save'));
    expect(pressed, 1);
  });

  testWidgets('disabled button does not call onPressed', (tester) async {
    var pressed = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const AppButton(label: 'Save')));

    await tester.tap(find.text('Save'));
    expect(pressed, 0);
    final data = tester.getSemantics(find.byType(AppButton)).getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    handle.dispose();
  });

  testWidgets('loading button shows a spinner and does not fire', (
    tester,
  ) async {
    var pressed = 0;
    await tester.pumpWidget(
      _wrap(
        AppButton(label: 'Save', onPressed: () => pressed++, isLoading: true),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(pressed, 0);
  });

  testWidgets('ghost and destructive variants use their colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppButton(
              label: 'Ghost',
              onPressed: () {},
              variant: AppButtonVariant.ghost,
            ),
            AppButton(
              label: 'Delete',
              onPressed: () {},
              variant: AppButtonVariant.destructive,
            ),
          ],
        ),
      ),
    );

    final ghostText = tester.widget<Text>(find.text('Ghost'));
    final deleteText = tester.widget<Text>(find.text('Delete'));
    expect(ghostText.style?.color, AppColors.text);
    expect(deleteText.style?.color, AppColors.orange);

    final materials = tester.widgetList<Material>(
      find.descendant(
        of: find.byType(AppButton),
        matching: find.byType(Material),
      ),
    );
    expect(materials.map((m) => m.color), contains(Colors.transparent));
  });
}
