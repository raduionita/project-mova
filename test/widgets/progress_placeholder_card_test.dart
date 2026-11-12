import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/dashed_border.dart';
import 'package:mova/widgets/progress_placeholder_card.dart';

void main() {
  testWidgets('fades the message but keeps the title and action readable', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ProgressPlaceholderCard(
            title: 'Weekly consistency',
            message: 'Log a session this week.',
            iconAsset: AppIcons.calendar,
            actionLabel: 'Start workout',
            actionKey: const Key('placeholder-start'),
            onAction: () => taps++,
          ),
        ),
      ),
    );

    expect(find.byType(DashedBorder), findsOneWidget);
    expect(find.text('Weekly consistency'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);

    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Log a session this week.'),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.72);

    await tester.tap(find.byKey(const Key('placeholder-start')));
    expect(taps, 1);
  });
}
