import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/step_entry.dart';
import 'package:mova/providers/steps_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/health_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);

HealthService _health({
  bool available = true,
  bool permission = true,
  int? steps = 8123,
}) {
  return HealthService(
    availabilityCheck: () async => available,
    permissionCheck: () async => permission,
    stepReader: (_, _) async => steps,
  );
}

void main() {
  test(
    'manual steps save with the manual source and survive a reload',
    () async {
      final storage = StorageService.inMemory();
      final clock = FakeClock(_now);
      final provider = StepsProvider(storage, clock: clock);

      expect(await provider.saveManualSteps(6400), isTrue);
      expect(provider.todaySteps, 6400);
      expect(provider.todayEntry?.source, StepSource.manual);

      final reloaded = StepsProvider(storage, clock: clock);
      await reloaded.load();
      expect(reloaded.todaySteps, 6400);
      expect(reloaded.todayEntry?.source, StepSource.manual);
    },
  );

  test('negative manual steps are rejected with an error', () async {
    final provider = StepsProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
    );
    expect(await provider.saveManualSteps(-1), isFalse);
    expect(provider.error, 'Steps cannot be negative.');
    expect(provider.todayEntry, isNull);
  });

  test('health sync writes the daily total with the health source', () async {
    final storage = StorageService.inMemory();
    final clock = FakeClock(_now);
    final provider = StepsProvider(
      storage,
      clock: clock,
      healthService: _health(steps: 9100),
    );

    expect(await provider.syncHealth(enabled: true), isTrue);
    expect(provider.todaySteps, 9100);
    expect(provider.todayEntry?.source, StepSource.health);
  });

  test('health sync is skipped when disabled or unavailable', () async {
    final disabled = StepsProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
      healthService: _health(),
    );
    expect(await disabled.syncHealth(enabled: false), isFalse);
    expect(disabled.todayEntry, isNull);

    final unavailable = StepsProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
      healthService: _health(available: false),
    );
    expect(await unavailable.syncHealth(enabled: true), isFalse);
    expect(unavailable.todayEntry, isNull);
  });

  test(
    'health sync keeps the manual value when permission is denied',
    () async {
      final provider = StepsProvider(
        StorageService.inMemory(),
        clock: FakeClock(_now),
        healthService: _health(permission: false),
      );
      await provider.saveManualSteps(3000);
      expect(await provider.syncHealth(enabled: true), isFalse);
      expect(provider.todaySteps, 3000);
      expect(provider.todayEntry?.source, StepSource.manual);
    },
  );

  test(
    'health sync keeps the manual value when no steps are returned',
    () async {
      final provider = StepsProvider(
        StorageService.inMemory(),
        clock: FakeClock(_now),
        healthService: _health(steps: null),
      );
      await provider.saveManualSteps(3000);
      expect(await provider.syncHealth(enabled: true), isFalse);
      expect(provider.todaySteps, 3000);
    },
  );

  test('loading keeps the latest entry per local day', () async {
    final storage = StorageService.inMemory();
    final older = StepEntry(
      dateKey: '2026-11-06',
      steps: 1000,
      source: StepSource.manual,
      updatedAt: _now.subtract(const Duration(hours: 2)),
    );
    final newer = StepEntry(
      dateKey: '2026-11-06',
      steps: 2000,
      source: StepSource.health,
      updatedAt: _now,
    );
    await storage.writeList(kStepsKey, <Map<String, dynamic>>[
      older.toJson(),
      newer.toJson(),
    ]);

    final provider = StepsProvider(storage, clock: FakeClock(_now));
    await provider.load();
    expect(provider.todaySteps, 2000);
    expect(provider.todayEntry?.source, StepSource.health);
  });

  test('reset clears in-memory entries', () async {
    final provider = StepsProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
    );
    await provider.saveManualSteps(100);
    expect(provider.todayEntry, isNotNull);
    provider.reset();
    expect(provider.todayEntry, isNull);
    expect(provider.todaySteps, 0);
  });
}
