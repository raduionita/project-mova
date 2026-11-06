import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_radii.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_card.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('standard card uses card surface and line border', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AppCard(child: Text('Body'))));

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(Material),
      ),
    );
    final shape = material.shape! as RoundedRectangleBorder;
    expect(material.color, AppColors.card);
    expect(shape.side.color, AppColors.line);
    expect(shape.borderRadius, BorderRadius.circular(AppRadii.xl));
  });

  testWidgets('featured card uses elevated surface and border', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppCard(featured: true, child: Text('Body'))),
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(Material),
      ),
    );
    final shape = material.shape! as RoundedRectangleBorder;
    expect(material.color, AppColors.cardElevated);
    expect(shape.side.color, AppColors.featuredBorder);
    expect(shape.borderRadius, BorderRadius.circular(AppRadii.x2l));
  });

  testWidgets('tappable card calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(AppCard(onTap: () => taps++, child: const Text('Body'))),
    );

    await tester.tap(find.text('Body'));
    expect(taps, 1);
  });
}
