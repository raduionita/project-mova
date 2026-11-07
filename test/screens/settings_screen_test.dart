import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/app_settings.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/social_provider.dart';
import 'package:mova/providers/steps_provider.dart';
import 'package:mova/screens/me/settings_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/health_service.dart';
import 'package:mova/services/notification_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);

class _FakeNotifications extends NotificationService {
  _FakeNotifications({this.granted = true});

  final bool granted;
  int reschedules = 0;
  int cancels = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<void> reschedule(AppSettings settings) async {
    reschedules++;
  }

  @override
  Future<void> cancelAll() async {
    cancels++;
  }
}

class _Harness {
  _Harness({_FakeNotifications? notifications, HealthService? health})
    : notifications = notifications ?? _FakeNotifications(),
      health = health ?? _unavailableHealth() {
    settings = SettingsProvider(
      storage,
      notificationService: this.notifications,
    );
    steps = StepsProvider(
      storage,
      clock: FakeClock(_now),
      healthService: this.health,
    );
    profile = ProfileProvider(storage, clock: FakeClock(_now));
    social = SocialProvider(storage, SeedDataService(), clock: FakeClock(_now));
  }

  final StorageService storage = StorageService.inMemory();
  final _FakeNotifications notifications;
  final HealthService health;
  late final SettingsProvider settings;
  late final ProfileProvider profile;
  late final StepsProvider steps;
  late final SocialProvider social;
}

HealthService _unavailableHealth() {
  return HealthService(availabilityCheck: () async => false);
}

Widget _app(_Harness harness, {double textScale = 1}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: harness.settings),
      ChangeNotifierProvider<ProfileProvider>.value(value: harness.profile),
      ChangeNotifierProvider<StepsProvider>.value(value: harness.steps),
      ChangeNotifierProvider<SocialProvider>.value(value: harness.social),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: SettingsScreen(healthService: harness.health),
      routes: <String, WidgetBuilder>{
        Routes.legalDocument('privacy'): (_) =>
            const Scaffold(body: Text('Privacy route')),
        Routes.legalDocument('terms'): (_) =>
            const Scaffold(body: Text('Terms route')),
        Routes.legalDocument('help'): (_) =>
            const Scaffold(body: Text('Help route')),
        Routes.meLicenses: (_) => const Scaffold(body: Text('Licenses route')),
      },
    ),
  );
}

Future<_Harness> _pump(
  WidgetTester tester, {
  _FakeNotifications? notifications,
  HealthService? health,
  bool loadSamples = true,
  double textScale = 1,
}) async {
  final harness = _Harness(notifications: notifications, health: health);
  await harness.settings.load();
  await harness.profile.load();
  await harness.steps.load();
  if (loadSamples) {
    await harness.social.load();
  }
  await tester.pumpWidget(_app(harness, textScale: textScale));
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  testWidgets('settings renders units, integrations, and legal sections', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Integrations'), findsOneWidget);
    expect(find.text('Privacy and social'), findsOneWidget);
    expect(find.text('Legal and support'), findsOneWidget);
    expect(find.text('Mova version'), findsOneWidget);
  });

  testWidgets('settings switch rows expose a merged accessible label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    final semantics = tester.getSemantics(
      find.byKey(const Key('settings-reminders-row')),
    );
    expect(semantics.label, contains('Workout reminders'));
    expect(semantics.label, contains('Off'));

    handle.dispose();
  });

  testWidgets('unit choices persist and keep storage values metric', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await tester.tap(find.text('Pounds'));
    await tester.pumpAndSettle();
    expect(harness.settings.settings.unitPreferences.weightUnit, WeightUnit.lb);

    await tester.ensureVisible(find.text('Miles'));
    await tester.tap(find.text('Miles'));
    await tester.pumpAndSettle();
    expect(
      harness.settings.settings.unitPreferences.distanceUnit,
      DistanceUnit.mi,
    );

    await tester.ensureVisible(find.text('Inches'));
    await tester.tap(find.text('Inches'));
    await tester.pumpAndSettle();
    expect(
      harness.settings.settings.unitPreferences.heightUnit,
      HeightUnit.inches,
    );
  });

  testWidgets('reminder switch schedules and cancels local reminders', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await tester.ensureVisible(
      find.byKey(const Key('settings-reminders-switch')),
    );
    await tester.tap(find.byKey(const Key('settings-reminders-switch')));
    await tester.pumpAndSettle();

    expect(harness.settings.settings.remindersEnabled, isTrue);
    expect(harness.notifications.reschedules, 1);
    expect(find.byKey(const Key('settings-reminder-days')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('settings-reminders-switch')),
    );
    await tester.tap(find.byKey(const Key('settings-reminders-switch')));
    await tester.pumpAndSettle();

    expect(harness.settings.settings.remindersEnabled, isFalse);
    expect(harness.notifications.cancels, 1);
  });

  testWidgets('denied notification permission explains how to recover', (
    tester,
  ) async {
    await _pump(tester, notifications: _FakeNotifications(granted: false));

    await tester.ensureVisible(
      find.byKey(const Key('settings-reminders-switch')),
    );
    await tester.tap(find.byKey(const Key('settings-reminders-switch')));
    await tester.pumpAndSettle();

    expect(find.text('Allow workout reminders'), findsOneWidget);
    expect(find.byKey(const Key('permissions-open-settings')), findsOneWidget);
  });

  testWidgets('connecting health reads steps and records the provider', (
    tester,
  ) async {
    final health = HealthService(
      availabilityCheck: () async => true,
      permissionRequester: () async => true,
      permissionCheck: () async => true,
      stepReader: (_, _) async => 7000,
    );
    final harness = await _pump(tester, health: health);

    await tester.ensureVisible(find.byKey(const Key('settings-health-row')));
    await tester.tap(find.byKey(const Key('settings-health-row')));
    await tester.pumpAndSettle();

    expect(
      harness.settings.settings.healthProvider,
      HealthProvider.healthConnect,
    );
    expect(harness.steps.todaySteps, 7000);
    expect(
      find.text('Health connected. Today will show your steps.'),
      findsOneWidget,
    );
  });

  testWidgets('unavailable health explains the manual fallback', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await tester.ensureVisible(find.byKey(const Key('settings-health-row')));
    await tester.tap(find.byKey(const Key('settings-health-row')));
    await tester.pumpAndSettle();

    expect(
      harness.settings.settings.healthProvider,
      HealthProvider.unavailable,
    );
    expect(find.text('Health access is not available'), findsOneWidget);
  });

  testWidgets('privacy controls hide own posts and sample posts', (
    tester,
  ) async {
    final harness = await _pump(tester);
    expect(harness.social.hasSamples, isTrue);

    await tester.ensureVisible(
      find.byKey(const Key('settings-share-workouts')),
    );
    await tester.tap(find.byKey(const Key('settings-share-workouts')));
    await tester.pumpAndSettle();
    expect(harness.settings.settings.postWorkoutsToFeed, isFalse);

    await tester.ensureVisible(find.byKey(const Key('settings-hide-samples')));
    await tester.tap(find.byKey(const Key('settings-hide-samples')));
    await tester.pumpAndSettle();

    expect(harness.social.hasSamples, isFalse);
    expect(harness.settings.settings.sampleFeedDismissed, isTrue);
  });

  testWidgets('every legal row opens a destination', (tester) async {
    await _pump(tester);

    final cases = <String, String>{
      'settings-privacy': 'Privacy route',
      'settings-terms': 'Terms route',
      'settings-licenses': 'Licenses route',
      'settings-help': 'Help route',
    };

    for (final entry in cases.entries) {
      await tester.ensureVisible(find.byKey(Key(entry.key)));
      await tester.tap(find.byKey(Key(entry.key)));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      Navigator.of(tester.element(find.text(entry.value))).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('reset row opens a dialog that can be cancelled', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(find.byKey(const Key('settings-reset')));
    await tester.tap(find.byKey(const Key('settings-reset')));
    await tester.pumpAndSettle();
    expect(find.text('Reset local data?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reset-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Reset local data?'), findsNothing);
  });

  testWidgets('settings renders at 1.3x text scale without clipping', (
    tester,
  ) async {
    await _pump(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
  });
}
