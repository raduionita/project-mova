import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/split_style.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 12, 9);

PlanProvider _provider(StorageService storage) {
  return PlanProvider(
    storage,
    loadExercises: () => SeedDataService().loadExercises(),
    clock: FakeClock(_fixedNow),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'reordering keeps each session slot and persists the new order',
    () async {
      final storage = StorageService.inMemory();
      final provider = _provider(storage);
      await provider.load();

      expect(
        await provider.generate(
          goals: const <Goal>[Goal.buildMuscle],
          experienceLevel: ExperienceLevel.regular,
          daysPerWeek: 3,
        ),
        isTrue,
      );

      final original = provider.plan!;
      expect(original.days.map((day) => day.slotKey), <String>[
        'push',
        'pull',
        'legs',
      ]);

      expect(await provider.reorderPlanDay(fromIndex: 0, toIndex: 2), isTrue);

      final reordered = provider.plan!;
      expect(reordered.days.map((day) => day.name), <String>[
        'Pull',
        'Legs',
        'Push',
      ]);
      expect(reordered.days.map((day) => day.slotKey), <String>[
        'pull',
        'legs',
        'push',
      ]);
      expect(reordered.days.map((day) => day.order), <int>[0, 1, 2]);

      final reloaded = _provider(storage);
      await reloaded.load();
      expect(reloaded.plan!.days.map((day) => day.name), <String>[
        'Pull',
        'Legs',
        'Push',
      ]);
    },
  );

  test('frequency updates regenerate a weekday-free rotation', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);
    await provider.load();

    await provider.generate(
      goals: const <Goal>[Goal.getStronger],
      experienceLevel: ExperienceLevel.beginner,
      daysPerWeek: 3,
    );

    expect(
      await provider.updateSchedule(
        daysPerWeek: 4,
        splitStyle: SplitStyle.upperLower,
      ),
      isTrue,
    );

    final plan = provider.plan!;
    expect(plan.daysPerWeek, 4);
    expect(plan.splitStyle, SplitStyle.upperLower);
    expect(plan.trainingDays, isEmpty);
    expect(plan.days.every((day) => day.weekday == 0), isTrue);
    expect(plan.days.map((day) => day.slotKey), <String>[
      'upper-a',
      'lower-a',
      'upper-b',
      'lower-b',
    ]);
  });

  test('rotation ids and orders are stable after regeneration', () async {
    final storage = StorageService.inMemory();
    final provider = _provider(storage);
    await provider.load();

    await provider.generate(
      goals: const <Goal>[Goal.buildMuscle],
      experienceLevel: ExperienceLevel.veteran,
      daysPerWeek: 2,
    );
    final first = provider.plan!;

    await provider.updateSchedule(daysPerWeek: 2);
    final second = provider.plan!;

    expect(second.days.map((day) => day.id), first.days.map((day) => day.id));
    expect(
      second.days.map((day) => day.slotKey),
      first.days.map((day) => day.slotKey),
    );
  });
}
