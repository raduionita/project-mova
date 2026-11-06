import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_tag.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('neutral tag uses surface and muted text', (tester) async {
    await tester.pumpWidget(_wrap(const AppTag(label: 'Planned')));

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    final text = tester.widget<Text>(find.text('Planned'));
    expect(decoration.color, AppColors.surfaceAlt);
    expect(text.style?.color, AppColors.muted);
    expect(container.constraints?.maxHeight, 20);
  });

  testWidgets('lime and gold tags use soft backgrounds', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppTag(label: 'PR', variant: AppTagVariant.gold),
            AppTag(label: 'Active', variant: AppTagVariant.lime),
          ],
        ),
      ),
    );

    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => container.decoration! as BoxDecoration)
        .toList();
    expect(containers[0].color, AppColors.goldSoft);
    expect(containers[1].color, AppColors.limeSoft);
  });
}
