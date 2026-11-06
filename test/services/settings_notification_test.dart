import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/app_settings.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/services/notification_service.dart';
import 'package:mova/services/storage_service.dart';

class _FakeNotifications extends NotificationService {
  int reschedules = 0;
  int cancels = 0;
  AppSettings? lastScheduled;

  @override
  Future<void> reschedule(AppSettings settings) async {
    reschedules++;
    lastScheduled = settings;
  }

  @override
  Future<void> cancelAll() async {
    cancels++;
  }
}

void main() {
  test(
    'missing settings payload returns every preference to defaults',
    () async {
      final storage = StorageService.inMemory();
      final provider = SettingsProvider(
        storage,
        notificationService: _FakeNotifications(),
      );

      await provider.load();

      expect(provider.settings.remindersEnabled, isFalse);
      expect(provider.settings.healthProvider, HealthProvider.none);
      expect(provider.settings.unitPreferences, const UnitPreferences());
    },
  );

  test('loading enabled reminders reschedules them', () async {
    final storage = StorageService.inMemory();
    final notifications = _FakeNotifications();
    const stored = AppSettings(
      remindersEnabled: true,
      reminderWeekdays: <int>[2, 4],
      reminderHour: 7,
      reminderMinute: 30,
    );
    await storage.writeObject(kSettingsKey, stored.toJson());

    final provider = SettingsProvider(
      storage,
      notificationService: notifications,
    );
    await provider.load();

    expect(provider.settings.remindersEnabled, isTrue);
    expect(notifications.reschedules, 1);
    expect(notifications.lastScheduled?.reminderWeekdays, <int>[2, 4]);
    expect(notifications.lastScheduled?.reminderHour, 7);
    expect(notifications.lastScheduled?.reminderMinute, 30);
  });

  test('disabling reminders cancels scheduled notifications', () async {
    final storage = StorageService.inMemory();
    final notifications = _FakeNotifications();
    final provider = SettingsProvider(
      storage,
      notificationService: notifications,
    );
    await provider.load();

    expect(
      await provider.setReminders(
        enabled: false,
        weekdays: <int>[1, 3, 5],
        hour: 18,
        minute: 0,
      ),
      isTrue,
    );
    expect(notifications.cancels, 1);
    expect(provider.settings.remindersEnabled, isFalse);
  });

  test('enabling reminders persists settings and reschedules', () async {
    final storage = StorageService.inMemory();
    final notifications = _FakeNotifications();
    final provider = SettingsProvider(
      storage,
      notificationService: notifications,
    );
    await provider.load();

    expect(
      await provider.setReminders(
        enabled: true,
        weekdays: <int>[1, 3, 5],
        hour: 19,
        minute: 15,
      ),
      isTrue,
    );
    expect(notifications.reschedules, 1);
    expect(notifications.cancels, 0);

    final reloaded = SettingsProvider(
      storage,
      notificationService: _FakeNotifications(),
    );
    await reloaded.load();
    expect(reloaded.settings.remindersEnabled, isTrue);
    expect(reloaded.settings.reminderHour, 19);
    expect(reloaded.settings.reminderMinute, 15);
  });

  test('setting the health provider persists the choice', () async {
    final storage = StorageService.inMemory();
    final provider = SettingsProvider(
      storage,
      notificationService: _FakeNotifications(),
    );
    await provider.load();

    expect(
      await provider.setHealthProvider(HealthProvider.healthConnect),
      isTrue,
    );
    expect(provider.settings.healthProvider, HealthProvider.healthConnect);

    final reloaded = SettingsProvider(
      storage,
      notificationService: _FakeNotifications(),
    );
    await reloaded.load();
    expect(reloaded.settings.healthProvider, HealthProvider.healthConnect);
  });

  test('privacy toggles and sample dismissal persist', () async {
    final storage = StorageService.inMemory();
    final provider = SettingsProvider(
      storage,
      notificationService: _FakeNotifications(),
    );
    await provider.load();

    expect(await provider.setPostWorkoutsToFeed(false), isTrue);
    expect(await provider.dismissSampleFeed(), isTrue);
    expect(provider.settings.postWorkoutsToFeed, isFalse);
    expect(provider.settings.sampleFeedDismissed, isTrue);

    final reloaded = SettingsProvider(
      storage,
      notificationService: _FakeNotifications(),
    );
    await reloaded.load();
    expect(reloaded.settings.postWorkoutsToFeed, isFalse);
    expect(reloaded.settings.sampleFeedDismissed, isTrue);
  });

  test('unavailable notifications fail soft', () async {
    const service = NotificationService(available: false);
    expect(await service.isAvailable(), isFalse);
    expect(await service.requestPermission(), isFalse);
    await service.cancelAll();
    await service.reschedule(const AppSettings(remindersEnabled: true));
  });
}
