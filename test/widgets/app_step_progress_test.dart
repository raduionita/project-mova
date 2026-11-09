import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_step_progress.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

AnimatedContainer _segment(WidgetTester tester, int index) {
  return tester.widget<AnimatedContainer>(
    find.byKey(ValueKey<String>('step-segment-$index')),
  );
}

Color? _segmentColor(WidgetTester tester, int index) {
  final decoration = _segment(tester, index).decoration;
  return decoration is BoxDecoration ? decoration.color : null;
}

void main() {
  testWidgets('renders ten dots with only the current step highlighted', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AppStepProgress(currentStep: 3)));

    for (var index = 0; index < 10; index++) {
      expect(
        find.byKey(ValueKey<String>('step-segment-$index')),
        findsOneWidget,
      );
      expect(
        _segmentColor(tester, index),
        index == 2 ? AppColors.lime : AppColors.stepInactive,
        reason: 'segment $index',
      );
    }
    expect(_segment(tester, 2).constraints?.maxWidth, 18);
    expect(_segment(tester, 0).constraints?.maxWidth, 6);
  });

  testWidgets('clamps step counts outside the range', (tester) async {
    await tester.pumpWidget(_wrap(const AppStepProgress(currentStep: 0)));
    expect(_segmentColor(tester, 0), AppColors.stepInactive);

    await tester.pumpWidget(_wrap(const AppStepProgress(currentStep: 20)));
    expect(_segmentColor(tester, 9), AppColors.lime);

    await tester.pumpAndSettle();
  });

  testWidgets('exposes a step label for accessibility', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const AppStepProgress(currentStep: 4)));

    expect(find.bySemanticsLabel('Step 4 of 10'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('supports a custom total', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppStepProgress(currentStep: 2, totalSteps: 5)),
    );

    expect(
      find.byKey(const ValueKey<String>('step-segment-4')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('step-segment-5')), findsNothing);
    expect(_segmentColor(tester, 1), AppColors.lime);
    expect(_segmentColor(tester, 2), AppColors.stepInactive);
  });
}
