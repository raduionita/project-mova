import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import 'app_navigation.dart';

/// Phase-aware app shell. Shows the bottom navigation bar on tab routes and
/// hides it on onboarding, the live logger, and the summary flow.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentRoute,
    required this.child,
    required this.onTabSelected,
    this.phase = AppNavigation.currentPhase,
  });

  final String currentRoute;
  final Widget child;
  final ValueChanged<AppTab> onTabSelected;
  final AppPhase phase;

  AppTabItem? get _selectedTab {
    return AppNavigation.selectedTab(currentRoute, phase: phase);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedTab;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar:
          selected == null ||
              !AppNavigation.showsBottomBar(currentRoute, phase: phase)
          ? null
          : BottomNavBar(
              currentTab: selected.tab,
              onTabSelected: onTabSelected,
              phase: phase,
            ),
    );
  }
}
