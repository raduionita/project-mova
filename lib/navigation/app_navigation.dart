import 'package:flutter/material.dart';

import 'routes.dart';

/// Product phases from the plan. Each tab unlocks with its release phase.
enum AppPhase { foundation, training, progress, social, profile }

/// Top-level destinations in the bottom navigation bar.
enum AppTab { today, train, progress, social, me }

/// A single bottom navigation destination.
class AppTabItem {
  const AppTabItem({
    required this.tab,
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.releasePhase,
  });

  final AppTab tab;
  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final AppPhase releasePhase;

  bool isAvailableIn(AppPhase phase) => releasePhase.index <= phase.index;
}

/// Phase-aware tab registry. Phase 1 exposes Today only.
class AppNavigation {
  const AppNavigation._();

  /// The phase flag for the shipped build. Later tabs stay hidden until the
  /// phase that owns them is enabled here.
  static const AppPhase currentPhase = AppPhase.training;

  static const List<AppTabItem> allTabs = <AppTabItem>[
    AppTabItem(
      tab: AppTab.today,
      label: 'Today',
      route: Routes.today,
      icon: Icons.today_outlined,
      selectedIcon: Icons.today,
      releasePhase: AppPhase.foundation,
    ),
    AppTabItem(
      tab: AppTab.train,
      label: 'Train',
      route: Routes.train,
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center,
      releasePhase: AppPhase.training,
    ),
    AppTabItem(
      tab: AppTab.progress,
      label: 'Progress',
      route: Routes.progress,
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      releasePhase: AppPhase.progress,
    ),
    AppTabItem(
      tab: AppTab.social,
      label: 'Social',
      route: Routes.social,
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      releasePhase: AppPhase.social,
    ),
    AppTabItem(
      tab: AppTab.me,
      label: 'Me',
      route: Routes.me,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      releasePhase: AppPhase.profile,
    ),
  ];

  /// Tabs available at [phase], in display order.
  static List<AppTabItem> visibleTabs({AppPhase phase = currentPhase}) {
    return allTabs
        .where((item) => item.isAvailableIn(phase))
        .toList(growable: false);
  }

  /// The tab that owns [route], including nested routes such as
  /// `/train/routines`. Returns null for onboarding, logger, and summary.
  static AppTabItem? tabForRoute(String? route) {
    if (route == null) {
      return null;
    }
    for (final item in allTabs) {
      if (route == item.route || route.startsWith('${item.route}/')) {
        return item;
      }
    }
    return null;
  }

  /// The selected tab for [route], or null when no visible tab owns it.
  static AppTabItem? selectedTab(
    String? route, {
    AppPhase phase = currentPhase,
  }) {
    final tab = tabForRoute(route);
    if (tab == null || !tab.isAvailableIn(phase)) {
      return null;
    }
    return tab;
  }

  /// The bottom bar is hidden on onboarding, logger, summary, builder
  /// sub-routes, and on routes that belong to a tab that has not been released
  /// yet.
  static bool showsBottomBar(String? route, {AppPhase phase = currentPhase}) {
    if (route == Routes.logger || route == Routes.summary) {
      return false;
    }
    if (Routes.isRoutineBuilderRoute(route)) {
      return false;
    }
    return selectedTab(route, phase: phase) != null;
  }
}
