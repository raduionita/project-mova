import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/weight_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_ruler_slider.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

Widget _wrap(OnboardingProvider onboarding, ValueChanged<String> onRoute) {
  return ChangeNotifierProvider<OnboardingProvider>.value(
    value: onboarding,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: WeightScreen(onRoute: onRoute),
    ),
  );
}

Future<OnboardingProvider> _providerAtWeight(
  StorageService storage, {
  double bodyWeightKg = 0,
  WeightUnit weightUnit = WeightUnit.kg,
}) async {
  await storage.writeObject(
    kOnboardingKey,
    OnboardingDraft(
      currentStep: OnboardingStep.weight,
      bodyWeightKg: bodyWeightKg,
      unitPreferences: UnitPreferences(weightUnit: weightUnit),
      updatedAt: _fixedNow,
    ).toJson(),
  );
  final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
  await provider.load();
  return provider;
}

Finder _rulerGesture() {
  return find.descendant(
    of: find.byType(AppRulerSlider),
    matching: find.byType(GestureDetector),
  );
}

void main() {
  testWidgets('defaults to 78 kg with the full range shown', (tester) async {
    final provider = await _providerAtWeight(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(find.text('Your weight'), findsOneWidget);
    expect(find.text('78'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('30 kg'), findsOneWidget);
    expect(find.text('250 kg'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('a saved weight is preselected', (tester) async {
    final provider = await _providerAtWeight(
      StorageService.inMemory(),
      bodyWeightKg: 82.5,
    );

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(find.text('82.5'), findsOneWidget);
  });

  testWidgets('pounds are shown for the lb unit and stored as kg', (
    tester,
  ) async {
    final provider = await _providerAtWeight(
      StorageService.inMemory(),
      bodyWeightKg: 78,
      weightUnit: WeightUnit.lb,
    );
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    expect(find.text('172'), findsOneWidget);
    expect(find.text('lb'), findsOneWidget);
    expect(find.text('66 lb'), findsOneWidget);
    expect(find.text('551 lb'), findsOneWidget);

    await tester.drag(_rulerGesture(), const Offset(24, 0));
    await tester.pumpAndSettle();
    expect(find.text('174'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.bodyWeightKg, 79.0);
    expect(routes, <String>[Routes.onboardingHeight]);
  });

  testWidgets('continue stores the weight and routes to height', (
    tester,
  ) async {
    final provider = await _providerAtWeight(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.drag(_rulerGesture(), const Offset(24, 0));
    await tester.pumpAndSettle();
    expect(find.text('79'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.bodyWeightKg, 79.0);
    expect(provider.draft.currentStep, OnboardingStep.height);
    expect(routes, <String>[Routes.onboardingHeight]);
  });

  testWidgets('skip stores zero and routes to height', (tester) async {
    final provider = await _providerAtWeight(
      StorageService.inMemory(),
      bodyWeightKg: 95,
    );
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(provider.draft.bodyWeightKg, 0);
    expect(provider.draft.currentStep, OnboardingStep.height);
    expect(routes, <String>[Routes.onboardingHeight]);
  });

  testWidgets('back returns to the birth date step', (tester) async {
    final provider = await _providerAtWeight(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingBirthDate]);
  });
}
