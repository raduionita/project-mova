import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_choice_card.dart';
import 'package:mova/widgets/app_tag.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders label, description, and icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppChoiceCard(
          label: 'Male',
          description: 'Use male reference values.',
          icon: Icons.male,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Use male reference values.'), findsOneWidget);
    expect(find.byIcon(Icons.male), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('selected card shows a lime check', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppChoiceCard(label: 'Female', selected: true)),
    );

    final check = tester.widget<Icon>(find.byIcon(Icons.check));
    expect(check.color, AppColors.lime);
  });

  testWidgets('tapping reports the action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(AppChoiceCard(label: 'Other', onTap: () => taps++)),
    );

    await tester.tap(find.text('Other'));
    expect(taps, 1);
  });

  testWidgets('a trailing widget replaces the check', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppChoiceCard(
          label: 'Build muscle',
          selected: true,
          trailing: AppTag(label: 'Primary', variant: AppTagVariant.lime),
        ),
      ),
    );

    expect(find.text('Primary'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('no trailing widget occupies no space when unselected', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AppChoiceCard(label: 'Beginner')));

    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('Primary'), findsNothing);
  });
}
