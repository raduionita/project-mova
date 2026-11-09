import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/schedule_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/theme/app_icons.dart';
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

List<int> _selectedDays(WidgetTester tester) {
  return tester.widget<DaySelector>(find.byType(DaySelector)).selectedDays;
}

bool _canContinue(WidgetTester tester) {
  return tester.widget<AppButton>(find.byType(AppButton)).onPressed != null;
}

Finder _assetIcon(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == asset,
);

void main() {
  testWidgets('defaults to 3 days on Monday, Wednesday, and Friday', (
    tester,
  ) async {
    final provider = await _providerWith(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(tester.widget<StepperRow>(find.byType(StepperRow)).value, 3);
    expect(_selectedDays(tester), <int>[1, 3, 5]);
    expect(_canContinue(tester), isTrue);
    expect(
      find.textContaining('Monday, Wednesday, and Friday'),
      findsOneWidget,
    );
  });

  testWidgets('the day count must match the selected weekdays', (tester) async {
    final provider = await _providerWith(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    await tester.tap(find.text('S').first);
    await tester.pump();
    expect(_selectedDays(tester), <int>[1, 3, 5]);

    await tester.tap(_assetIcon(AppIcons.plus));
    await tester.pump();
    expect(_selectedDays(tester), <int>[1, 2, 3, 5]);

    await tester.tap(find.text('S').first);
    await tester.pump();
    expect(_selectedDays(tester), <int>[1, 2, 3, 5]);

    await tester.tap(_assetIcon(AppIcons.plus));
    await tester.pump();
    expect(_selectedDays(tester), <int>[1, 2, 3, 4, 5]);

    await tester.tap(find.text('W'));
    await tester.pump();
    await tester.tap(find.text('S').first);
    await tester.pump();
    expect(_selectedDays(tester), <int>[1, 2, 4, 5, 6]);
  });

  testWidgets('lowering the day count trims the selected days', (tester) async {
    final provider = await _providerWith(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    await tester.tap(_assetIcon(AppIcons.minus));
    await tester.pump();
    await tester.tap(_assetIcon(AppIcons.minus));
    await tester.pump();

    expect(tester.widget<StepperRow>(find.byType(StepperRow)).value, 1);
    expect(_selectedDays(tester), <int>[1]);
    expect(_canContinue(tester), isTrue);
  });

  testWidgets('deselecting a day blocks continue until the count matches', (
    tester,
  ) async {
    final provider = await _providerWith(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));
    await tester.tap(find.text('W'));
    await tester.pump();

    expect(_selectedDays(tester), <int>[1, 5]);
    expect(_canContinue(tester), isFalse);
    expect(find.text('Select 1 more day to continue.'), findsOneWidget);
  });

  testWidgets('continue persists the schedule and opens equipment', (
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
    expect(provider.draft.trainingDays, <int>[1, 3, 5]);
    expect(provider.draft.currentStep, OnboardingStep.equipment);
    expect(routes, <String>[Routes.onboardingEquipment]);

    final reloaded = await _providerWith(storage);
    expect(reloaded.draft.daysPerWeek, 3);
    expect(reloaded.draft.trainingDays, <int>[1, 3, 5]);
  });

  testWidgets('a saved schedule is restored', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.schedule,
        daysPerWeek: 2,
        trainingDays: const <int>[2, 4],
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = await _providerWith(storage);

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(tester.widget<StepperRow>(find.byType(StepperRow)).value, 2);
    expect(_selectedDays(tester), <int>[2, 4]);
  });

  testWidgets('back returns to the experience step', (tester) async {
    final provider = await _providerWith(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingExperience]);
  });

  testWidgets(
    'editing from plan returns to the preview with the schedule kept',
    (tester) async {
      final storage = StorageService.inMemory();
      await storage.writeObject(
        kOnboardingKey,
        OnboardingDraft(
          currentStep: OnboardingStep.plan,
          daysPerWeek: 4,
          trainingDays: const <int>[1, 2, 3, 5],
          updatedAt: _fixedNow,
        ).toJson(),
      );
      final provider = await _providerWith(storage);
      final routes = <String>[];

      provider.beginPlanEdit();
      await tester.pumpWidget(_wrap(provider, routes.add));
      expect(_selectedDays(tester), <int>[1, 2, 3, 5]);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(routes, <String>[Routes.onboardingPlan]);
      expect(provider.draft.currentStep, OnboardingStep.plan);
      expect(provider.draft.daysPerWeek, 4);
      expect(provider.draft.trainingDays, <int>[1, 2, 3, 5]);
    },
  );
}
