import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

Future<OnboardingProvider> _load(StorageService storage) async {
  final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
  await provider.load();
  return provider;
}

/// Waits for the fire-and-forget persist started by [syncStep].
Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  test('syncStep follows the visible screen and persists it', () async {
    final storage = StorageService.inMemory();
    final provider = await _load(storage);

    expect(provider.draft.currentStep, OnboardingStep.welcome);
    expect(provider.hasDraft, isFalse);

    provider.syncStep(OnboardingStep.schedule);

    expect(provider.draft.currentStep, OnboardingStep.schedule);
    expect(provider.hasDraft, isTrue);

    await _flush();

    final reloaded = await _load(storage);
    expect(reloaded.draft.currentStep, OnboardingStep.schedule);
    expect(reloaded.hasDraft, isTrue);
  });

  test('syncStep to welcome clears the saved draft', () async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.goals,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = await _load(storage);
    expect(provider.hasDraft, isTrue);

    provider.syncStep(OnboardingStep.welcome);

    expect(provider.draft.currentStep, OnboardingStep.welcome);
    expect(provider.hasDraft, isFalse);

    await _flush();

    final reloaded = await _load(storage);
    expect(reloaded.draft.currentStep, OnboardingStep.welcome);
    expect(reloaded.hasDraft, isFalse);
  });

  test('syncStep can move backwards without the step gates', () async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.plan,
        updatedAt: _fixedNow,
      ).toJson(),
    );
    final provider = await _load(storage);

    // plan refuses to advance, but walking back must still work.
    expect(await provider.next(), isFalse);
    expect(provider.draft.currentStep, OnboardingStep.plan);

    provider.syncStep(OnboardingStep.equipment);
    expect(provider.draft.currentStep, OnboardingStep.equipment);
    expect(provider.hasDraft, isTrue);
  });
}
