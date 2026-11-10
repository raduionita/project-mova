import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/screens/onboarding/notifications_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/notification_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService({
    super.available = true,
    this.permissionGranted = false,
  });

  final bool permissionGranted;
  int permissionRequests = 0;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }
}

Future<OnboardingProvider> _onboardingWith(
  StorageService storage, {
  bool seed = true,
}) async {
  if (seed) {
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.notifications,
        updatedAt: _fixedNow,
      ).toJson(),
    );
  }
  final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
  await provider.load();
  return provider;
}

Future<SettingsProvider> _settingsWith(StorageService storage) async {
  final provider = SettingsProvider(storage);
  await provider.load();
  return provider;
}

Widget _wrap(
  OnboardingProvider onboarding,
  SettingsProvider settings,
  NotificationService service,
  ValueChanged<String> onRoute,
) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<OnboardingProvider>.value(value: onboarding),
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: NotificationsScreen(onRoute: onRoute, notificationService: service),
    ),
  );
}

void main() {
  testWidgets('granted permission enables reminders and opens the plan', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final onboarding = await _onboardingWith(storage);
    final settings = await _settingsWith(storage);
    final service = _FakeNotificationService(permissionGranted: true);
    final routes = <String>[];

    await tester.pumpWidget(_wrap(onboarding, settings, service, routes.add));
    await tester.tap(find.text('Enable reminders'));
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 1);
    expect(settings.settings.remindersEnabled, isTrue);
    expect(onboarding.draft.notificationsAsked, isTrue);
    expect(onboarding.draft.currentStep, OnboardingStep.plan);
    expect(routes, <String>[Routes.onboardingPlan]);
  });

  testWidgets('denied permission continues with reminders off', (tester) async {
    final storage = StorageService.inMemory();
    final onboarding = await _onboardingWith(storage);
    final settings = await _settingsWith(storage);
    final service = _FakeNotificationService(permissionGranted: false);
    final routes = <String>[];

    await tester.pumpWidget(_wrap(onboarding, settings, service, routes.add));
    await tester.tap(find.text('Enable reminders'));
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 1);
    expect(settings.settings.remindersEnabled, isFalse);
    expect(onboarding.draft.notificationsAsked, isTrue);
    expect(routes, <String>[Routes.onboardingPlan]);
  });

  testWidgets('unavailable notifications skip the permission request', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final onboarding = await _onboardingWith(storage);
    final settings = await _settingsWith(storage);
    final service = _FakeNotificationService(
      available: false,
      permissionGranted: true,
    );
    final routes = <String>[];

    await tester.pumpWidget(_wrap(onboarding, settings, service, routes.add));
    await tester.tap(find.text('Enable reminders'));
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 0);
    expect(settings.settings.remindersEnabled, isFalse);
    expect(onboarding.draft.notificationsAsked, isTrue);
    expect(routes, <String>[Routes.onboardingPlan]);
  });

  testWidgets('Not now continues with reminders off', (tester) async {
    final storage = StorageService.inMemory();
    final onboarding = await _onboardingWith(storage);
    final settings = await _settingsWith(storage);
    final service = _FakeNotificationService(permissionGranted: true);
    final routes = <String>[];

    await tester.pumpWidget(_wrap(onboarding, settings, service, routes.add));
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 0);
    expect(settings.settings.remindersEnabled, isFalse);
    expect(onboarding.draft.notificationsAsked, isTrue);
    expect(routes, <String>[Routes.onboardingPlan]);
  });

  testWidgets('the reminder choice persists', (tester) async {
    final storage = StorageService.inMemory();
    final onboarding = await _onboardingWith(storage);
    final settings = await _settingsWith(storage);

    await tester.pumpWidget(
      _wrap(
        onboarding,
        settings,
        _FakeNotificationService(permissionGranted: true),
        (_) {},
      ),
    );
    await tester.tap(find.text('Enable reminders'));
    await tester.pumpAndSettle();

    final reloaded = await _settingsWith(storage);
    expect(reloaded.settings.remindersEnabled, isTrue);
    expect(reloaded.settings.reminderHour, 18);
    expect(reloaded.settings.reminderWeekdays, <int>[1, 3, 5]);

    final reloadedDraft = await _onboardingWith(storage, seed: false);
    expect(reloadedDraft.draft.notificationsAsked, isTrue);
  });

  testWidgets('the reminder time opens a time picker', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.notifications,
        reminderHour: 7,
        reminderMinute: 30,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final onboarding = await _onboardingWith(storage, seed: false);
    final settings = await _settingsWith(storage);

    await tester.pumpWidget(
      _wrap(
        onboarding,
        settings,
        _FakeNotificationService(permissionGranted: true),
        (_) {},
      ),
    );

    expect(find.text('07:30'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-reminder-time')));
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(onboarding.draft.reminderHour, 7);
    expect(onboarding.draft.reminderMinute, 30);
  });

  testWidgets('back returns to the schedule step', (tester) async {
    final storage = StorageService.inMemory();
    final onboarding = await _onboardingWith(storage);
    final settings = await _settingsWith(storage);
    final routes = <String>[];

    await tester.pumpWidget(
      _wrap(onboarding, settings, _FakeNotificationService(), routes.add),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingEquipment]);
  });

  testWidgets('a plan-step choice returns to the preview', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.plan,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final onboarding = await _onboardingWith(storage, seed: false);
    final settings = await _settingsWith(storage);
    final routes = <String>[];

    await tester.pumpWidget(
      _wrap(onboarding, settings, _FakeNotificationService(), routes.add),
    );
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingPlan]);
    expect(settings.settings.remindersEnabled, isFalse);
    expect(onboarding.draft.currentStep, OnboardingStep.plan);
  });
}
