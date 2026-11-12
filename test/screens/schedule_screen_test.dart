import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/schedule_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_button.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:mova/widgets/day_selector.dart';
import 'package:mova/widgets/stepper_row.dart';
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
      home: ScheduleScreen(onRoute: onRoute),
    ),
  );
}

bool _canContinue(WidgetTester tester) {
  return tester.widget<AppButton>(find.byType(AppButton)).onPressed != null;
}

Finder _assetIcon(String asset) => find.descendant(
  of: find.byType(StepperRow),
  matching: find.byWidgetPredicate(
    (widget) => widget is AppIcon && widget.asset == asset,
  ),
);

void main() {
  testWidgets('defaults to an average of 3 days with no weekday selector', (
    tester,
  ) async {
    final provider = await _providerWith(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(tester.widget<StepperRow>(find.byType(StepperRow)).value, 3);
    expect(find.byType(DaySelector), findsNothing);
    expect(_canContinue(tester), isTrue);
    expect(
      find.textContaining('average target, not fixed weekdays'),
      findsOneWidget,
    );
  });

  testWidgets('the stepper changes the average frequency', (tester) async {
    final provider = await _providerWith(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    await tester.tap(_assetIcon(AppIcons.plus));
    await tester.pump();
    expect(tester.widget<StepperRow>(find.byType(StepperRow)).value, 4);

    await tester.tap(_assetIcon(AppIcons.minus));
    await tester.pump();
    await tester.tap(_assetIcon(AppIcons.minus));
    await tester.pump();
    expect(tester.widget<StepperRow>(find.byType(StepperRow)).value, 2);
    expect(_canContinue(tester), isTrue);
  });

  testWidgets('frequency stays within the supported range', (tester) async {
    final provider = await _providerWith(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    for (var index = 0; index < 6; index++) {
      await tester.tap(_assetIcon(AppIcons.plus));
      await tester.pump();
    }

    expect(
      tester.widget<StepperRow>(find.byType(StepperRow)).value,
      kMaxTrainingDays,
    );
  });

  testWidgets('continue persists the frequency and opens equipment', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.schedule,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = await _providerWith(storage);
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.daysPerWeek, 3);
    expect(provider.draft.currentStep, OnboardingStep.equipment);
    expect(routes, <String>[Routes.onboardingEquipment]);

    final reloaded = await _providerWith(storage);
    expect(reloaded.draft.daysPerWeek, 3);
  });

  testWidgets('a saved frequency is restored', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.schedule,
        daysPerWeek: 2,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = await _providerWith(storage);

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(tester.widget<StepperRow>(find.byType(StepperRow)).value, 2);
  });

  testWidgets('back returns to the experience step', (tester) async {
    final provider = await _providerWith(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingExperience]);
  });

  testWidgets('tracking mode hides the frequency and can continue', (
    tester,
  ) async {
    final provider = await _providerWith(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.tap(find.byKey(const Key('onboarding-track-choice')));
    await tester.pumpAndSettle();

    expect(find.byType(StepperRow), findsNothing);
    expect(find.text('Track on my own'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.planEnabled, isFalse);
    expect(provider.draft.daysPerWeek, 3);
    expect(routes, <String>[Routes.onboardingEquipment]);
  });

  testWidgets(
    'editing from plan returns to the preview with the frequency kept',
    (tester) async {
      final storage = StorageService.inMemory();
      await storage.writeObject(
        kOnboardingKey,
        OnboardingDraft(
          currentStep: OnboardingStep.plan,
          daysPerWeek: 4,
          updatedAt: _fixedNow,
        ).toJson(),
      );
      final provider = await _providerWith(storage);
      final routes = <String>[];

      provider.beginPlanEdit();
      await tester.pumpWidget(_wrap(provider, routes.add));

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(routes, <String>[Routes.onboardingPlan]);
      expect(provider.draft.currentStep, OnboardingStep.plan);
      expect(provider.draft.daysPerWeek, 4);
    },
  );
}
