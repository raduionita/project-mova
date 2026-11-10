import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/goals_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_spacing.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/widgets/app_button.dart';
import 'package:mova/widgets/app_choice_card.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

Widget _wrap(OnboardingProvider onboarding, ValueChanged<String> onRoute) {
  return ChangeNotifierProvider<OnboardingProvider>.value(
    value: onboarding,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: GoalsScreen(onRoute: onRoute),
    ),
  );
}

Future<OnboardingProvider> _providerAtGoals(
  StorageService storage, {
  List<Goal> goals = const <Goal>[],
}) async {
  await storage.writeObject(
    kOnboardingKey,
    OnboardingDraft(
      currentStep: OnboardingStep.goals,
      goals: goals,
      updatedAt: _fixedNow,
    ).toJson(),
  );
  final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
  await provider.load();
  return provider;
}

void main() {
  testWidgets('renders four goals and blocks continue until one is chosen', (
    tester,
  ) async {
    final provider = await _providerAtGoals(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(find.text('What are you training for?'), findsOneWidget);
    expect(find.text('Build muscle'), findsOneWidget);
    expect(find.text('Get stronger'), findsOneWidget);
    expect(find.text('Lose weight'), findsOneWidget);
    expect(find.text('Stay healthy'), findsOneWidget);
    expect(find.text('Add size with steady volume.'), findsOneWidget);
    expect(find.text('Lift heavier with lower reps.'), findsOneWidget);
    expect(find.text('Burn energy with higher reps.'), findsOneWidget);
    expect(find.text('Train consistently without burnout.'), findsOneWidget);
    expect(find.text('Primary'), findsNothing);

    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('uses the larger icon and padding from the experience step', (
    tester,
  ) async {
    final provider = await _providerAtGoals(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    final cards = tester.widgetList<AppChoiceCard>(find.byType(AppChoiceCard));
    expect(cards, hasLength(4));
    for (final card in cards) {
      expect(card.iconSize, 22);
      expect(card.iconBoxSize, 40);
      final padding = card.contentPadding.resolve(TextDirection.ltr);
      expect(padding.left, AppSpacing.x2l);
      expect(padding.right, AppSpacing.x2l);
      expect(padding.top, AppSpacing.x2l);
      expect(padding.bottom, AppSpacing.x2l);
    }

    final icon = tester.widget<AppIcon>(
      find.byWidgetPredicate(
        (widget) => widget is AppIcon && widget.asset == AppIcons.dumbbell,
      ),
    );
    expect(icon.size, 22);
  });

  testWidgets('selection order decides the primary goal and persists', (
    tester,
  ) async {
    final provider = await _providerAtGoals(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.tap(find.text('Get stronger'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build muscle'));
    await tester.pumpAndSettle();

    expect(find.text('Primary'), findsOneWidget);
    final primaryCard = find.ancestor(
      of: find.text('Primary'),
      matching: find.byType(AppChoiceCard),
    );
    expect(
      find.descendant(
        of: primaryCard.first,
        matching: find.text('Get stronger'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.goals, <Goal>[Goal.getStronger, Goal.buildMuscle]);
    expect(provider.draft.currentStep, OnboardingStep.experience);
    expect(routes, <String>[Routes.onboardingExperience]);
  });

  testWidgets('saved goals are preselected in order', (tester) async {
    final provider = await _providerAtGoals(
      StorageService.inMemory(),
      goals: const <Goal>[Goal.stayHealthy, Goal.loseWeight],
    );

    await tester.pumpWidget(_wrap(provider, (_) {}));

    final primaryCard = find.ancestor(
      of: find.text('Primary'),
      matching: find.byType(AppChoiceCard),
    );
    expect(
      find.descendant(
        of: primaryCard.first,
        matching: find.text('Stay healthy'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('deselecting the primary promotes the next goal', (tester) async {
    final provider = await _providerAtGoals(
      StorageService.inMemory(),
      goals: const <Goal>[Goal.buildMuscle, Goal.loseWeight],
    );

    await tester.pumpWidget(_wrap(provider, (_) {}));

    await tester.tap(find.text('Build muscle'));
    await tester.pumpAndSettle();

    final primaryCard = find.ancestor(
      of: find.text('Primary'),
      matching: find.byType(AppChoiceCard),
    );
    expect(
      find.descendant(
        of: primaryCard.first,
        matching: find.text('Lose weight'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('back returns to the height step', (tester) async {
    final provider = await _providerAtGoals(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingHeight]);
  });
}
