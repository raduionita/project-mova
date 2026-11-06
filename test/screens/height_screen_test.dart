import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/height_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

Widget _wrap(OnboardingProvider onboarding, ValueChanged<String> onRoute) {
  return ChangeNotifierProvider<OnboardingProvider>.value(
    value: onboarding,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: HeightScreen(onRoute: onRoute),
    ),
  );
}

Future<OnboardingProvider> _providerAtHeight(
  StorageService storage, {
  double heightCm = 0,
  HeightUnit heightUnit = HeightUnit.cm,
}) async {
  await storage.writeObject(
    kOnboardingKey,
    OnboardingDraft(
      currentStep: OnboardingStep.height,
      heightCm: heightCm,
      unitPreferences: UnitPreferences(heightUnit: heightUnit),
      updatedAt: _fixedNow,
    ).toJson(),
  );
  final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
  await provider.load();
  return provider;
}

void main() {
  testWidgets('defaults to 175 cm with the skip action', (tester) async {
    final provider = await _providerAtHeight(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(find.text('Your height'), findsOneWidget);
    expect(find.text('175'), findsOneWidget);
    expect(find.text('cm'), findsOneWidget);
    expect(find.text('Drag to adjust'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('a saved height is preselected', (tester) async {
    final provider = await _providerAtHeight(
      StorageService.inMemory(),
      heightCm: 182,
    );

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(find.text('182'), findsOneWidget);
  });

  testWidgets('inches are shown for the body unit', (tester) async {
    final provider = await _providerAtHeight(
      StorageService.inMemory(),
      heightCm: 175,
      heightUnit: HeightUnit.inches,
    );

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(find.text('68.9'), findsOneWidget);
    expect(find.text('in'), findsOneWidget);
  });

  testWidgets('dragging up increases centimeters in one cm steps', (
    tester,
  ) async {
    final provider = await _providerAtHeight(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.drag(find.text('Drag to adjust'), const Offset(0, -20));
    await tester.pumpAndSettle();

    expect(find.text('177'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.heightCm, 177);
    expect(provider.draft.currentStep, OnboardingStep.goals);
    expect(routes, <String>[Routes.onboardingGoals]);
  });

  testWidgets('skip stores zero and routes to goals', (tester) async {
    final provider = await _providerAtHeight(
      StorageService.inMemory(),
      heightCm: 168,
    );
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(provider.draft.heightCm, 0);
    expect(provider.draft.currentStep, OnboardingStep.goals);
    expect(routes, <String>[Routes.onboardingGoals]);
  });

  testWidgets('back returns to the weight step', (tester) async {
    final provider = await _providerAtHeight(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingWeight]);
  });
}
