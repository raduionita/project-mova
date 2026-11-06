import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/experience_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_choice_card.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

Future<OnboardingProvider> _providerWith(
  StorageService storage, {
  bool load = true,
}) async {
  final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
  if (load) {
    await provider.load();
  }
  return provider;
}

Widget _wrap(OnboardingProvider provider, ValueChanged<String> onRoute) {
  return ChangeNotifierProvider<OnboardingProvider>.value(
    value: provider,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: ExperienceScreen(onRoute: onRoute),
    ),
  );
}

void main() {
  testWidgets('shows four levels and blocks continue until one is picked', (
    tester,
  ) async {
    final provider = await _providerWith(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Regular'), findsOneWidget);
    expect(find.text('Gym rat'), findsOneWidget);
    expect(find.text('Veteran'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(routes, isEmpty);
    expect(provider.draft.experienceLevel, isNull);
  });

  testWidgets('selection persists and routes to the schedule step', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.experience,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = await _providerWith(storage);
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.tap(find.text('Regular'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.experienceLevel, ExperienceLevel.regular);
    expect(provider.draft.currentStep, OnboardingStep.schedule);
    expect(routes, <String>[Routes.onboardingSchedule]);

    final reloaded = await _providerWith(storage);
    expect(reloaded.draft.experienceLevel, ExperienceLevel.regular);
  });

  testWidgets('a saved level is preselected', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.experience,
        experienceLevel: ExperienceLevel.gymRat,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = await _providerWith(storage);

    await tester.pumpWidget(_wrap(provider, (_) {}));

    final cards = tester.widgetList<AppChoiceCard>(find.byType(AppChoiceCard));
    expect(cards.elementAt(2).selected, isTrue);
    expect(cards.where((card) => card.selected), hasLength(1));
  });

  testWidgets('picking another level replaces the saved choice', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.experience,
        experienceLevel: ExperienceLevel.gymRat,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = await _providerWith(storage);

    await tester.pumpWidget(_wrap(provider, (_) {}));
    await tester.tap(find.text('Veteran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.experienceLevel, ExperienceLevel.veteran);
  });

  testWidgets('back returns to the goals step', (tester) async {
    final provider = await _providerWith(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingGoals]);
  });
}
