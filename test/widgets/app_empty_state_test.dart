import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_empty_state.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('empty state shows icon, title, message, and action', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        AppEmptyState(
          icon: Icons.fitness_center,
          title: 'No workouts yet',
          message: 'Finish a workout to see it here.',
          actionLabel: 'Start a workout',
          onAction: () => taps++,
        ),
      ),
    );

    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    expect(find.text('No workouts yet'), findsOneWidget);
    expect(find.text('Finish a workout to see it here.'), findsOneWidget);

    await tester.tap(find.text('Start a workout'));
    expect(taps, 1);
  });
}
