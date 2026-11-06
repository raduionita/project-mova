import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_ruler_slider.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}

Finder _rulerGesture() {
  return find.descendant(
    of: find.byType(AppRulerSlider),
    matching: find.byType(GestureDetector),
  );
}

void main() {
  testWidgets('shows the value and unit', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppRulerSlider(
          value: 78.5,
          min: 30,
          max: 250,
          step: 0.5,
          unitLabel: 'kg',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('78.5'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
  });

  testWidgets('dragging right increases in step increments', (tester) async {
    final changes = <double>[];
    await tester.pumpWidget(
      _wrap(
        AppRulerSlider(
          value: 80,
          min: 30,
          max: 250,
          step: 0.5,
          pixelsPerStep: 10,
          onChanged: changes.add,
        ),
      ),
    );

    await tester.drag(_rulerGesture(), const Offset(30, 0));
    await tester.pumpAndSettle();

    expect(changes, isNotEmpty);
    expect(changes.last, 81.5);
    expect(find.text('81.5'), findsOneWidget);
  });

  testWidgets('dragging left decreases and clamps at the minimum', (
    tester,
  ) async {
    final changes = <double>[];
    await tester.pumpWidget(
      _wrap(
        AppRulerSlider(
          value: 30.5,
          min: 30,
          max: 250,
          step: 0.5,
          pixelsPerStep: 10,
          onChanged: changes.add,
        ),
      ),
    );

    await tester.drag(_rulerGesture(), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(changes.last, 30);
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('tapping sets a value relative to the center', (tester) async {
    final changes = <double>[];
    await tester.pumpWidget(
      _wrap(
        AppRulerSlider(
          value: 80,
          min: 30,
          max: 250,
          step: 0.5,
          pixelsPerStep: 10,
          onChanged: changes.add,
        ),
      ),
    );

    final rect = tester.getRect(_rulerGesture());
    await tester.tapAt(rect.center + const Offset(24, 0));
    await tester.pumpAndSettle();

    expect(changes.last, 81);
  });

  testWidgets('disabled ruler ignores input', (tester) async {
    final changes = <double>[];
    await tester.pumpWidget(
      _wrap(
        AppRulerSlider(
          value: 80,
          min: 30,
          max: 250,
          step: 0.5,
          onChanged: changes.add,
          enabled: false,
        ),
      ),
    );

    await tester.drag(_rulerGesture(), const Offset(60, 0));
    await tester.tapAt(tester.getRect(_rulerGesture()).center);
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(find.byType(Opacity), findsWidgets);
  });
}
