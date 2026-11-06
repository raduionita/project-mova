import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/screens/onboarding/unit_selection_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

Widget _wrap({
  required OnboardingProvider onboarding,
  required SettingsProvider settings,
  required ValueChanged<String> onRoute,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<OnboardingProvider>.value(value: onboarding),
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: UnitSelectionScreen(onRoute: onRoute),
    ),
  );
}

void main() {
  testWidgets('shows kg, km, and cm by default', (tester) async {
    final storage = StorageService.inMemory();
    final onboarding = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
    await onboarding.load();
    final settings = SettingsProvider(storage);
    await settings.load();

    await tester.pumpWidget(
      _wrap(onboarding: onboarding, settings: settings, onRoute: (_) {}),
    );

    expect(find.text('Choose your units'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Body size'), findsOneWidget);
    expect(tester.widget<Text>(find.text('kg')).style?.color, AppColors.lime);
    expect(tester.widget<Text>(find.text('km')).style?.color, AppColors.lime);
    expect(tester.widget<Text>(find.text('cm')).style?.color, AppColors.lime);
    expect(tester.widget<Text>(find.text('lb')).style?.color, AppColors.muted);
  });

  testWidgets('restored drafts show their saved units', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.units,
        unitPreferences: const UnitPreferences(
          weightUnit: WeightUnit.lb,
          distanceUnit: DistanceUnit.mi,
          heightUnit: HeightUnit.inches,
        ),
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final onboarding = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
    await onboarding.load();
    final settings = SettingsProvider(storage);
    await settings.load();

    await tester.pumpWidget(
      _wrap(onboarding: onboarding, settings: settings, onRoute: (_) {}),
    );

    expect(tester.widget<Text>(find.text('lb')).style?.color, AppColors.lime);
    expect(tester.widget<Text>(find.text('mi')).style?.color, AppColors.lime);
    expect(tester.widget<Text>(find.text('in')).style?.color, AppColors.lime);
  });

  testWidgets('continue persists units to the draft and settings', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.units,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final onboarding = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
    await onboarding.load();
    final settings = SettingsProvider(storage);
    await settings.load();
    final routes = <String>[];

    await tester.pumpWidget(
      _wrap(onboarding: onboarding, settings: settings, onRoute: routes.add),
    );

    await tester.tap(find.text('lb'));
    await tester.tap(find.text('mi'));
    await tester.tap(find.text('in'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingGender]);
    expect(onboarding.draft.unitPreferences.weightUnit, WeightUnit.lb);
    expect(onboarding.draft.unitPreferences.distanceUnit, DistanceUnit.mi);
    expect(onboarding.draft.unitPreferences.heightUnit, HeightUnit.inches);
    expect(onboarding.draft.currentStep, OnboardingStep.gender);
    expect(settings.settings.unitPreferences.weightUnit, WeightUnit.lb);
    expect(settings.settings.unitPreferences.distanceUnit, DistanceUnit.mi);
    expect(settings.settings.unitPreferences.heightUnit, HeightUnit.inches);

    final reloaded = SettingsProvider(storage);
    await reloaded.load();
    expect(reloaded.settings.unitPreferences.weightUnit, WeightUnit.lb);
  });

  testWidgets('defaults persist even when nothing is changed', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.units,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final onboarding = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
    await onboarding.load();
    final settings = SettingsProvider(storage);
    await settings.load();

    await tester.pumpWidget(
      _wrap(onboarding: onboarding, settings: settings, onRoute: (_) {}),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(storage.contains(kSettingsKey), isTrue);
    expect(settings.settings.unitPreferences.weightUnit, WeightUnit.kg);
    expect(settings.settings.unitPreferences.distanceUnit, DistanceUnit.km);
    expect(settings.settings.unitPreferences.heightUnit, HeightUnit.cm);
  });

  testWidgets('back returns to welcome', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.units,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final onboarding = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
    await onboarding.load();
    final settings = SettingsProvider(storage);
    await settings.load();
    final routes = <String>[];

    await tester.pumpWidget(
      _wrap(onboarding: onboarding, settings: settings, onRoute: routes.add),
    );

    await tester.tap(find.byTooltip('Back'));
    expect(routes, <String>[Routes.welcome]);
  });
}
