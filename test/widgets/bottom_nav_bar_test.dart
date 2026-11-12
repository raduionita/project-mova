import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/navigation/app_navigation.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:mova/widgets/bottom_nav_bar.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(bottomNavigationBar: child),
  );
}

Finder _tabIcon(AppTab tab) {
  return find.byKey(ValueKey<String>('tab-icon-${tab.name}'));
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
    expect(find.text('Calendar'), findsNothing);
    expect(find.text('Progress'), findsNothing);
    expect(find.text('Social'), findsNothing);
    expect(find.text('Me'), findsNothing);
    expect(_tabIcon(AppTab.today), findsOneWidget);
    expect(
      tester.widget<AppIcon>(_tabIcon(AppTab.today)).asset,
      AppIcons.navToday,
    );
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
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);
    expect(find.text('Me'), findsOneWidget);
    for (final tab in AppTab.values) {
      expect(_tabIcon(tab), findsOneWidget);
    }
    expect(
      tester.widget<AppIcon>(_tabIcon(AppTab.social)).asset,
      AppIcons.navSocial,
    );
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

    await tester.tap(find.text('Calendar'));
    expect(tapped, <AppTab>[AppTab.calendar]);
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

    final selected = tester.widget<AppIcon>(_tabIcon(AppTab.today));
    final inactive = tester.widget<AppIcon>(_tabIcon(AppTab.calendar));
    final selectedLabel = tester.widget<Text>(find.text('Today'));
    final inactiveLabel = tester.widget<Text>(find.text('Calendar'));

    expect(selected.color, AppColors.lime);
    expect(inactive.color, AppColors.tabInactive);
    expect(selectedLabel.style?.color, AppColors.lime);
    expect(inactiveLabel.style?.color, AppColors.tabInactive);
  });
}
