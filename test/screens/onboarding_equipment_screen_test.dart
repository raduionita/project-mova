import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/equipment_group.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/screens/onboarding/equipment_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_button.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

Widget _wrap(OnboardingProvider onboarding, ValueChanged<String> onRoute) {
  return ChangeNotifierProvider<OnboardingProvider>.value(
    value: onboarding,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: OnboardingEquipmentScreen(onRoute: onRoute),
    ),
  );
}

Future<OnboardingProvider> _provider(
  StorageService storage, {
  List<EquipmentGroup> equipment = EquipmentGroup.values,
}) async {
  await storage.writeObject(
    kOnboardingKey,
    OnboardingDraft(
      currentStep: OnboardingStep.equipment,
      availableEquipment: equipment,
      updatedAt: _fixedNow,
    ).toJson(),
  );
  final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
  await provider.load();
  return provider;
}

void main() {
  testWidgets('defaults to every equipment group and can continue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = await _provider(StorageService.inMemory());

    await tester.pumpWidget(_wrap(provider, (_) {}));

    expect(find.text('Your equipment'), findsOneWidget);
    for (final group in EquipmentGroup.values) {
      expect(find.text(group.label), findsOneWidget);
    }
    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('deselecting every option blocks continue', (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = await _provider(
      StorageService.inMemory(),
      equipment: const <EquipmentGroup>[EquipmentGroup.dumbbells],
    );

    await tester.pumpWidget(_wrap(provider, (_) {}));
    await tester.tap(find.text(EquipmentGroup.dumbbells.label));
    await tester.pumpAndSettle();

    final button = tester.widget<AppButton>(find.byType(AppButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('continue persists equipment and opens notifications', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = await _provider(
      StorageService.inMemory(),
      equipment: const <EquipmentGroup>[EquipmentGroup.dumbbells],
    );
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.tap(find.text(EquipmentGroup.dumbbells.label));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(EquipmentGroup.kettlebells.label));
    await tester.tap(find.text(EquipmentGroup.kettlebells.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.availableEquipment, <EquipmentGroup>[
      EquipmentGroup.kettlebells,
    ]);
    expect(provider.draft.currentStep, OnboardingStep.notifications);
    expect(routes, <String>[Routes.onboardingNotifications]);
  });

  testWidgets('quick start preset narrows the list and persists on continue', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = await _provider(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.tap(
      find.byKey(const Key('equipment-preset-bodyweight-only')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(provider.draft.availableEquipment, <EquipmentGroup>[
      EquipmentGroup.bodyweight,
    ]);
    expect(routes, <String>[Routes.onboardingNotifications]);
  });

  testWidgets('back returns to the schedule step', (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final provider = await _provider(StorageService.inMemory());
    final routes = <String>[];

    await tester.pumpWidget(_wrap(provider, routes.add));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingSchedule]);
  });
}
