import '../theme/app_icons.dart';
import 'routes.dart';

/// Product phases from the plan. Each tab unlocks with its release phase.
enum AppPhase { foundation, training, progress, social, profile }

/// Top-level destinations in the bottom navigation bar.
enum AppTab { today, calendar, progress, social, me }

/// A single bottom navigation destination.
class AppTabItem {
  const AppTabItem({
    required this.tab,
    required this.label,
    required this.route,
    required this.iconAsset,
    required this.releasePhase,
  });

  final AppTab tab;
  final String label;
  final String route;

  /// SVG asset from `assets/icons/`, tinted at runtime.
  final String iconAsset;
  final AppPhase releasePhase;

  bool isAvailableIn(AppPhase phase) => releasePhase.index <= phase.index;
}

/// Phase-aware tab registry. Phase 5 exposes all five destinations.
class AppNavigation {
  const AppNavigation._();

  /// The phase flag for the shipped build. Later tabs stay hidden until the
  /// phase that owns them is enabled here.
  static const AppPhase currentPhase = AppPhase.profile;

  static const List<AppTabItem> allTabs = <AppTabItem>[
    AppTabItem(
      tab: AppTab.today,
      label: 'Today',
      route: Routes.today,
      iconAsset: AppIcons.navToday,
      releasePhase: AppPhase.foundation,
    ),
    AppTabItem(
      tab: AppTab.calendar,
      label: 'Calendar',
      route: Routes.calendar,
      iconAsset: AppIcons.calendar,
      releasePhase: AppPhase.training,
    ),
    AppTabItem(
      tab: AppTab.progress,
      label: 'Progress',
      route: Routes.progress,
      iconAsset: AppIcons.navProgress,
      releasePhase: AppPhase.progress,
    ),
    AppTabItem(
      tab: AppTab.social,
      label: 'Social',
      route: Routes.social,
      iconAsset: AppIcons.navSocial,
      releasePhase: AppPhase.social,
    ),
    AppTabItem(
      tab: AppTab.me,
      label: 'Me',
      route: Routes.me,
      iconAsset: AppIcons.navMe,
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
  /// `/train/exercises`. Returns null for onboarding, logger, summary, plan,
  /// and routine routes.
  static AppTabItem? tabForRoute(String? route) {
    if (route == null) {
      return null;
    }
    final calendar = allTabs.firstWhere(
      (item) => item.tab == AppTab.calendar,
    );
    if (route == Routes.calendar ||
        route == Routes.train ||
        route == Routes.exercises ||
        route == Routes.trainExercises ||
        route.startsWith('${Routes.trainExercises}/')) {
      return calendar;
    }
    // Routine routes belong to the Plan surface, which is a secondary screen
    // without a bottom destination.
    if (route == Routes.routines ||
        route.startsWith('${Routes.routines}/')) {
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
    if (route == Routes.meEdit || route == Routes.meSettings) {
      return false;
    }
    if (route == Routes.meLicenses || Routes.legalDocFromRoute(route) != null) {
      return false;
    }
    if (Routes.isRoutineBuilderRoute(route)) {
      return false;
    }
    return selectedTab(route, phase: phase) != null;
  }
}
