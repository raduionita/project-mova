import 'package:flutter_test/flutter_test.dart';
import 'package:mova/navigation/app_navigation.dart';
import 'package:mova/navigation/routes.dart';

void main() {
  test('phase 1 exposes Today only', () {
    final tabs = AppNavigation.visibleTabs(phase: AppPhase.foundation);

    expect(tabs, hasLength(1));
    expect(tabs.single.tab, AppTab.today);
    expect(tabs.single.label, 'Today');
    expect(tabs.single.route, Routes.today);
  });

  test('the shipped phase flag exposes every tab through Me', () {
    expect(AppNavigation.currentPhase, AppPhase.profile);
    expect(AppNavigation.visibleTabs().map((item) => item.tab), <AppTab>[
      AppTab.today,
      AppTab.train,
      AppTab.progress,
      AppTab.social,
      AppTab.me,
    ]);
  });

  test('later phases unlock their own tabs in order', () {
    expect(
      AppNavigation.visibleTabs(phase: AppPhase.training)
          .map((item) => item.tab),
      <AppTab>[AppTab.today, AppTab.train],
    );
    expect(
      AppNavigation.visibleTabs(phase: AppPhase.progress)
          .map((item) => item.tab),
      <AppTab>[AppTab.today, AppTab.train, AppTab.progress],
    );
    expect(
      AppNavigation.visibleTabs(phase: AppPhase.social).map((item) => item.tab),
      <AppTab>[AppTab.today, AppTab.train, AppTab.progress, AppTab.social],
    );
    expect(
      AppNavigation.visibleTabs(phase: AppPhase.profile)
          .map((item) => item.tab),
      <AppTab>[
        AppTab.today,
        AppTab.train,
        AppTab.progress,
        AppTab.social,
        AppTab.me,
      ],
    );
  });

  test('routes resolve to their owning tab, including nested routes', () {
    expect(AppNavigation.tabForRoute(Routes.today)?.tab, AppTab.today);
    expect(AppNavigation.tabForRoute(Routes.train)?.tab, AppTab.train);
    expect(
      AppNavigation.tabForRoute('/train/routines/routine-1')?.tab,
      AppTab.train,
    );
    expect(AppNavigation.tabForRoute(Routes.progress)?.tab, AppTab.progress);
    expect(
      AppNavigation.tabForRoute('/progress/history/1')?.tab,
      AppTab.progress,
    );
    expect(AppNavigation.tabForRoute(Routes.social)?.tab, AppTab.social);
    expect(AppNavigation.tabForRoute(Routes.me)?.tab, AppTab.me);
    expect(AppNavigation.tabForRoute('/me/settings')?.tab, AppTab.me);
  });

  test('non-tab routes have no owning tab', () {
    expect(AppNavigation.tabForRoute(Routes.welcome), isNull);
    expect(AppNavigation.tabForRoute(Routes.logger), isNull);
    expect(AppNavigation.tabForRoute(Routes.summary), isNull);
    expect(AppNavigation.tabForRoute(null), isNull);
  });

  test('selected tab respects the phase flag', () {
    expect(AppNavigation.selectedTab(Routes.today)?.tab, AppTab.today);
    expect(
      AppNavigation.selectedTab(Routes.train, phase: AppPhase.foundation),
      isNull,
    );
    expect(AppNavigation.selectedTab(Routes.train)?.tab, AppTab.train);
    expect(AppNavigation.selectedTab(Routes.me)?.tab, AppTab.me);
    expect(
      AppNavigation.selectedTab(Routes.me, phase: AppPhase.social),
      isNull,
    );
  });

  test('bottom bar hides on onboarding, logger, summary, and locked tabs', () {
    expect(AppNavigation.showsBottomBar(Routes.today), isTrue);
    expect(AppNavigation.showsBottomBar(Routes.logger), isFalse);
    expect(AppNavigation.showsBottomBar(Routes.summary), isFalse);
    expect(AppNavigation.showsBottomBar(Routes.welcome), isFalse);
    expect(AppNavigation.showsBottomBar(Routes.onboardingGoals), isFalse);
    expect(
      AppNavigation.showsBottomBar(Routes.train, phase: AppPhase.foundation),
      isFalse,
    );
    expect(AppNavigation.showsBottomBar(Routes.train), isTrue);
    expect(AppNavigation.showsBottomBar(Routes.routineNew), isFalse);
    expect(
      AppNavigation.showsBottomBar('/train/routines/routine-1/edit'),
      isFalse,
    );
    expect(
      AppNavigation.showsBottomBar('/me/settings', phase: AppPhase.profile),
      isFalse,
    );
    expect(
      AppNavigation.showsBottomBar('/me/licenses', phase: AppPhase.profile),
      isFalse,
    );
    expect(
      AppNavigation.showsBottomBar(
        '/me/legal/privacy',
        phase: AppPhase.profile,
      ),
      isFalse,
    );
  });

  test('onboarding route list covers every step after welcome', () {
    expect(Routes.onboardingSteps, hasLength(10));
    expect(Routes.onboardingSteps.first, Routes.onboardingUnits);
    expect(Routes.onboardingSteps.last, Routes.onboardingPlan);
  });
}
