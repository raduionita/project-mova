import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/welcome_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

class _FailingStorage extends StorageService {
  _FailingStorage() : super.inMemory();

  @override
  Future<bool> writeObject(String key, Map<String, dynamic> value) async {
    return false;
  }
}

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
      home: WelcomeScreen(onRoute: onRoute),
    ),
  );
}

void main() {
  testWidgets('new users see Get started and route to units', (tester) async {
    final storage = StorageService.inMemory();
    final provider = await _providerWith(storage);
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    expect(find.text('Train with a plan'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
    expect(find.text('I have a profile'), findsNothing);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingUnits]);
    expect(provider.draft.currentStep, OnboardingStep.units);
    expect(storage.contains(kOnboardingKey), isTrue);
  });

  testWidgets('saved drafts show Continue and resume the saved step', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.goals,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = await _providerWith(storage);
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingGoals]);
    expect(provider.draft.currentStep, OnboardingStep.goals);
  });

  testWidgets('a welcome-only draft is not resumed', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(updatedAt: _fixedNow).toJson(),
    );
    final provider = await _providerWith(storage);
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));

    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('value rows describe plan, logger, and progress', (tester) async {
    final provider = await _providerWith(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(
      find.text('A weekly plan shaped by your goals and schedule'),
      findsOneWidget,
    );
    expect(
      find.text('A fast logger that remembers your last set'),
      findsOneWidget,
    );
    expect(
      find.text('Progress you can trust, built from your own data'),
      findsOneWidget,
    );
    expect(find.text('Mova'), findsNothing);
    expect(
      tester
          .widgetList<AppIcon>(find.byType(AppIcon))
          .map((icon) => icon.asset),
      <String>[AppIcons.plan, AppIcons.clock, AppIcons.trendUp],
    );
  });

  test('advances even when the draft cannot be saved', () async {
    final provider = await _providerWith(_FailingStorage());

    final advanced = await provider.next();

    expect(advanced, isTrue);
    expect(provider.draft.currentStep, OnboardingStep.units);
    expect(provider.error, 'Could not save onboarding draft.');
  });

  test('hasDraft tracks saved progress and reset', () async {
    final storage = StorageService.inMemory();
    final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
    await provider.load();
    expect(provider.hasDraft, isFalse);

    await provider.next();
    expect(provider.hasDraft, isTrue);

    await provider.reset();
    expect(provider.hasDraft, isFalse);
    expect(storage.contains(kOnboardingKey), isFalse);
  });
}
