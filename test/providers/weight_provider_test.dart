import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/providers/weight_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);

void main() {
  test('saves one weight per day and survives a reload', () async {
    final storage = StorageService.inMemory();
    final clock = FakeClock(_now);
    final provider = WeightProvider(storage, clock: clock);

    expect(await provider.logWeight(80), isTrue);
    expect(provider.latest?.weightKg, 80);
    expect(provider.latest?.dateKey, '2026-11-06');
    expect(storage.contains(kWeightsKey), isTrue);

    final reloaded = WeightProvider(storage, clock: clock);
    await reloaded.load();
    expect(reloaded.entries, hasLength(1));
    expect(reloaded.latest?.weightKg, 80);
  });

  test('saving again on the same day replaces the value', () async {
    final storage = StorageService.inMemory();
    final clock = FakeClock(_now);
    final provider = WeightProvider(storage, clock: clock);

    expect(await provider.logWeight(80), isTrue);
    clock.advance(const Duration(hours: 2));
    expect(await provider.logWeight(79.5), isTrue);

    expect(provider.entries, hasLength(1));
    expect(provider.latest?.weightKg, 79.5);

    final reloaded = WeightProvider(storage, clock: clock);
    await reloaded.load();
    expect(reloaded.entries, hasLength(1));
    expect(reloaded.latest?.weightKg, 79.5);
  });

  test('keeps days in newest-first order', () async {
    final storage = StorageService.inMemory();
    final clock = FakeClock(_now);
    final provider = WeightProvider(storage, clock: clock);

    await provider.logWeight(82, date: DateTime(2026, 11, 4));
    await provider.logWeight(80);
    await provider.logWeight(81, date: DateTime(2026, 11, 5));

    expect(provider.entries.map((entry) => entry.dateKey).toList(), <String>[
      '2026-11-06',
      '2026-11-05',
      '2026-11-04',
    ]);
  });

  test('rejects weights outside the supported range', () async {
    final provider = WeightProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
    );

    expect(await provider.logWeight(kMinWeightKg - 1), isFalse);
    expect(provider.error, isNotNull);
    expect(await provider.logWeight(kMaxWeightKg + 1), isFalse);
    expect(provider.entries, isEmpty);
  });

  test('seeds a starting entry once from the profile value', () async {
    final provider = WeightProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
    );

    expect(await provider.seedInitial(80), isTrue);
    expect(provider.entries, hasLength(1));
    await provider.logWeight(79);
    expect(await provider.seedInitial(75), isTrue);
    expect(provider.entries, hasLength(1));
    expect(provider.latest?.weightKg, 79);
  });
}
