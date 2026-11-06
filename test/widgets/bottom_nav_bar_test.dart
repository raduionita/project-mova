import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/navigation/app_navigation.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/bottom_nav_bar.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(bottomNavigationBar: child),
  );
}

void main() {
  testWidgets('phase 1 renders Today only', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BottomNavBar(
          currentTab: AppTab.today,
          onTabSelected: (_) {},
          phase: AppPhase.foundation,
        ),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Train'), findsNothing);
    expect(find.text('Progress'), findsNothing);
    expect(find.text('Social'), findsNothing);
    expect(find.text('Me'), findsNothing);
    expect(find.byIcon(Icons.today), findsOneWidget);
  });

  testWidgets('phase 5 renders all five destinations', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BottomNavBar(
          currentTab: AppTab.social,
          onTabSelected: (_) {},
          phase: AppPhase.profile,
        ),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);
    expect(find.byIcon(Icons.today_outlined), findsOneWidget);
  });

  testWidgets('tapping a tab reports the tab', (tester) async {
    final tapped = <AppTab>[];
    await tester.pumpWidget(
      _wrap(
        BottomNavBar(
          currentTab: AppTab.today,
          onTabSelected: tapped.add,
          phase: AppPhase.training,
        ),
      ),
    );

    await tester.tap(find.text('Train'));
    expect(tapped, <AppTab>[AppTab.train]);
  });

  testWidgets('selected tab uses lime and inactive tabs use tabInactive', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        BottomNavBar(
          currentTab: AppTab.today,
          onTabSelected: (_) {},
          phase: AppPhase.training,
        ),
      ),
    );

    final selected = tester.widget<Icon>(find.byIcon(Icons.today));
    final inactive = tester.widget<Icon>(
      find.byIcon(Icons.fitness_center_outlined),
    );
    final selectedLabel = tester.widget<Text>(find.text('Today'));
    final inactiveLabel = tester.widget<Text>(find.text('Train'));

    expect(selected.color, AppColors.lime);
    expect(inactive.color, AppColors.tabInactive);
    expect(selectedLabel.style?.color, AppColors.lime);
    expect(inactiveLabel.style?.color, AppColors.tabInactive);
  });
}
