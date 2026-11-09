import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/gender.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/gender_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:mova/widgets/app_choice_card.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

Widget _wrap(OnboardingProvider onboarding, ValueChanged<String> onRoute) {
  return ChangeNotifierProvider<OnboardingProvider>.value(
    value: onboarding,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: GenderScreen(onRoute: onRoute),
    ),
  );
}

Future<OnboardingProvider> _providerAtGender(StorageService storage) async {
  await storage.writeObject(
    kOnboardingKey,
    OnboardingDraft(
      currentStep: OnboardingStep.gender,
      updatedAt: _fixedNow,
    ).toJson(),
  );
  final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
  await provider.load();
  return provider;
}

Finder _assetIcon(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == asset,
);

void main() {
  testWidgets('renders three options with icons and text', (tester) async {
    final provider = await _providerAtGender(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(
      tester
          .widgetList<AppIcon>(find.byType(AppIcon))
          .map((icon) => icon.asset),
      containsAll(<String>[AppIcons.male, AppIcons.female, AppIcons.other]),
    );
  });

  testWidgets('continue is disabled until a gender is chosen', (tester) async {
    final provider = await _providerAtGender(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(routes, isEmpty);

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingBirthDate]);
    expect(provider.draft.gender, Gender.female);
    expect(provider.draft.currentStep, OnboardingStep.birthDate);
  });

  testWidgets('selection persists and reloads from the draft', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.gender,
        gender: Gender.other,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
    await provider.load();

    await tester.pumpWidget(_wrap(provider, (_) {}));

    final cards = tester.widgetList<AppChoiceCard>(find.byType(AppChoiceCard));
    final selected = cards.where((card) => card.selected);
    expect(selected, hasLength(1));
    expect(selected.single.label, 'Other');
    expect(_assetIcon(AppIcons.check), findsOneWidget);
  });

  testWidgets('back returns to units', (tester) async {
    final provider = await _providerAtGender(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.tap(find.byTooltip('Back'));
    expect(routes, <String>[Routes.onboardingUnits]);
  });
}
