import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_vertical_ruler_slider.dart';

Widget _wrap({double? value, ValueChanged<double>? onChanged}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Center(
        child: AppVerticalRulerSlider(
          value: value ?? 175,
          min: 120,
          max: 230,
          step: 1,
          unitLabel: 'cm',
          valueLabel: (value ?? 175).toStringAsFixed(0),
          minLabel: '120 cm',
          maxLabel: '230 cm',
          hint: 'Drag to adjust',
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the value, range, and marker hint', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.text('175'), findsOneWidget);
    expect(find.text('cm'), findsOneWidget);
    expect(find.text('120 cm'), findsOneWidget);
    expect(find.text('230 cm'), findsOneWidget);
    expect(find.text('Drag to adjust'), findsOneWidget);
  });

  testWidgets('dragging up increases the value in one cm steps', (
    tester,
  ) async {
    double? changed;
    await tester.pumpWidget(_wrap(onChanged: (value) => changed = value));

    await tester.drag(find.text('Drag to adjust'), const Offset(0, -20));
    await tester.pumpAndSettle();

    expect(changed, 177);
  });

  testWidgets('a small viewport still lets the ruler win the drag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    double? changed;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppVerticalRulerSlider(
              value: 175,
              min: 120,
              max: 230,
              step: 1,
              unitLabel: 'cm',
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    final ruler = tester.getCenter(find.byType(AppVerticalRulerSlider));
    await tester.dragFrom(ruler, const Offset(0, -20));
    await tester.pumpAndSettle();

    expect(changed, 177);
  });
}
