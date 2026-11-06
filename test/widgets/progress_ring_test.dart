import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/progress_ring.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('progress ring renders value and exposes semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(
        const ProgressRing(
          value: 0.75,
          label: 'Weekly goal',
          valueLabel: '75%',
        ),
      ),
    );

    expect(find.text('75%'), findsOneWidget);
    expect(find.text('WEEKLY GOAL'), findsOneWidget);

    final semantics = tester.getSemantics(find.byType(ProgressRing));
    expect(semantics.label, 'Weekly goal');
    expect(semantics.value, '75%');
    handle.dispose();
  });

  testWidgets('progress ring clamps values outside 0 to 1', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ProgressRing(
          value: 1.4,
          label: 'Weekly goal',
          valueLabel: '140%',
        ),
      ),
    );

    expect(find.text('140%'), findsOneWidget);
  });
}
