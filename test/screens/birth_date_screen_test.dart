import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/birth_date_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_wheel_picker.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);
const int _minYear = 1906;

Widget _wrap(OnboardingProvider onboarding, ValueChanged<String> onRoute) {
  return ChangeNotifierProvider<OnboardingProvider>.value(
    value: onboarding,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: BirthDateScreen(onRoute: onRoute, clock: FakeClock(_fixedNow)),
    ),
  );
}

Future<OnboardingProvider> _providerAtBirth(
  StorageService storage, {
  DateTime? birthDate,
}) async {
  await storage.writeObject(
    kOnboardingKey,
    OnboardingDraft(
      currentStep: OnboardingStep.birthDate,
      birthDate: birthDate,
      updatedAt: _fixedNow,
    ).toJson(),
  );
  final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
  await provider.load();
  return provider;
}

AppWheelPicker _wheel(WidgetTester tester, String key) {
  return tester.widget<AppWheelPicker>(find.byKey(ValueKey<String>(key)));
}

void main() {
  testWidgets('defaults to 25 years before today', (tester) async {
    final provider = await _providerAtBirth(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('When were you born?'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);
    expect(_wheel(tester, 'birth-month-wheel').selectedIndex, 10);
    expect(_wheel(tester, 'birth-day-wheel').selectedIndex, 4);
    expect(_wheel(tester, 'birth-year-wheel').selectedIndex, 2001 - _minYear);
  });

  testWidgets('continue persists the date and routes to weight', (
    tester,
  ) async {
    final provider = await _providerAtBirth(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingWeight]);
    expect(provider.draft.birthDate, DateTime(2001, 11, 5));
    expect(provider.draft.currentStep, OnboardingStep.weight);
  });

  testWidgets('back returns to gender', (tester) async {
    final provider = await _providerAtBirth(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));

    expect(routes, <String>[Routes.onboardingGender]);
  });

  testWidgets('a saved birth date is preselected', (tester) async {
    final provider = await _providerAtBirth(
      StorageService.inMemory(),
      birthDate: DateTime(1990, 3, 15),
    );

    await tester.pumpWidget(_wrap(provider, (_) {}));
    await tester.pumpAndSettle();

    expect(_wheel(tester, 'birth-month-wheel').selectedIndex, 2);
    expect(_wheel(tester, 'birth-day-wheel').selectedIndex, 14);
    expect(_wheel(tester, 'birth-year-wheel').selectedIndex, 1990 - _minYear);
  });

  testWidgets('changing off a leap day clamps the day', (tester) async {
    final provider = await _providerAtBirth(
      StorageService.inMemory(),
      birthDate: DateTime(2000, 2, 29),
    );
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.pumpAndSettle();
    expect(_wheel(tester, 'birth-day-wheel').selectedIndex, 28);

    _wheel(tester, 'birth-year-wheel').onSelectedIndexChanged(2001 - _minYear);
    await tester.pumpAndSettle();

    expect(_wheel(tester, 'birth-day-wheel').selectedIndex, 27);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(provider.draft.birthDate, DateTime(2001, 2, 28));
    expect(routes, <String>[Routes.onboardingWeight]);
  });

  testWidgets('under 13 shows an error and blocks continue', (tester) async {
    final provider = await _providerAtBirth(
      StorageService.inMemory(),
      birthDate: DateTime(2013, 12, 31),
    );
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.pumpAndSettle();

    expect(find.text('You must be at least 13 years old.'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(routes, isEmpty);
    expect(provider.draft.currentStep, OnboardingStep.birthDate);
  });
}
