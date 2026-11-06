import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app_coordinator.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/app_settings.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/social_provider.dart';
import 'package:mova/providers/steps_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/notification_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);

class _FakeNotifications extends NotificationService {
  int cancels = 0;

  @override
  Future<void> cancelAll() async {
    cancels++;
  }
}

void main() {
  test(
    'reset clears local keys, cancels reminders, and reseeds social',
    () async {
      final storage = StorageService.inMemory();
      final clock = FakeClock(_now);
      final notifications = _FakeNotifications();
      final settings = SettingsProvider(
        storage,
        notificationService: notifications,
      );
      final profile = ProfileProvider(storage, clock: clock);
      final plan = PlanProvider(
        storage,
        loadExercises: () async => const [],
        clock: clock,
      );
      final onboarding = OnboardingProvider(storage, clock: clock);
      final history = HistoryProvider(storage);
      final progress = ProgressProvider(storage, clock: clock);
      final steps = StepsProvider(storage, clock: clock);
      final social = SocialProvider(storage, SeedDataService(), clock: clock);

      await settings.load();
      await steps.load();
      await social.load();
      await steps.saveManualSteps(4321);
      await settings.setHealthProvider(HealthProvider.healthConnect);
      await settings.setPostWorkoutsToFeed(false);

      expect(social.hasSamples, isTrue);
      expect(
        storage.readObject<AppSettings>(kSettingsKey, AppSettings.fromJson),
        isNotNull,
      );

      final coordinator = AppCoordinator(
        storage: storage,
        profileProvider: profile,
        settingsProvider: settings,
        planProvider: plan,
        onboardingProvider: onboarding,
        historyProvider: history,
        progressProvider: progress,
        stepsProvider: steps,
        socialProvider: social,
        clock: clock,
      );

      expect(await coordinator.resetLocalData(), isTrue);

      expect(notifications.cancels, 1);
      expect(
        storage.readObject<AppSettings>(kSettingsKey, AppSettings.fromJson),
        isNull,
      );
      expect(steps.todaySteps, 0);
      expect(settings.settings.postWorkoutsToFeed, isTrue);
      expect(settings.settings.healthProvider, HealthProvider.none);
      expect(social.hasSamples, isTrue);
      expect(social.posts.every((post) => post.isSample), isTrue);
    },
  );
}
