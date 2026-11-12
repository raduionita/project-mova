import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/streak_badge_row.dart';

Widget _wrap({required int days, required int weeks}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: StreakBadgeRow(dayStreak: days, weekStreak: weeks),
    ),
  );
}

void main() {
  testWidgets('shows day and week badges with locked milestones', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(days: 8, weeks: 1));

    expect(find.text('Streak badges'), findsOneWidget);
    expect(find.byKey(const Key('today-badge-day-3')), findsOneWidget);
    expect(find.byKey(const Key('today-badge-day-30')), findsOneWidget);
    expect(find.byKey(const Key('today-badge-week-1')), findsOneWidget);
    expect(find.byKey(const Key('today-badge-week-12')), findsOneWidget);
    expect(find.text('3 days'), findsOneWidget);
    expect(find.text('12 weeks'), findsOneWidget);
  });

  testWidgets('earned badges are fully opaque and locked badges are faded', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(days: 7, weeks: 0));

    final earned = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const Key('today-badge-day-7')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    final locked = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const Key('today-badge-day-14')),
            matching: find.byType(Opacity),
          )
          .first,
    );

    expect(earned.opacity, 1);
    expect(locked.opacity, 0.45);
  });
}
