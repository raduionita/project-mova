import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/equipment_group.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/split_style.dart';
import 'package:mova/services/plan_generator_service.dart';
import 'package:mova/services/seed_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> library;
  final fixedNow = DateTime.utc(2026, 11, 5, 12);

  setUpAll(() async {
    library = await SeedDataService().loadExercises();
  });

  PlanGeneratorService generator() {
    return PlanGeneratorService(
      exercises: library,
      now: () => fixedNow,
      sessionMinutes: 55,
    );
  }

  test('frequency generation creates weekday-free rotations for 1-7 days', () {
    for (var days = 1; days <= 7; days++) {
      final plan = generator().generate(
        goals: const <Goal>[Goal.buildMuscle],
        experienceLevel: ExperienceLevel.beginner,
        daysPerWeek: days,
      );

      expect(plan.isFallback, isFalse, reason: '$days days');
      expect(plan.daysPerWeek, days);
      expect(plan.trainingDays, isEmpty, reason: '$days days');
      expect(plan.days, hasLength(days));
      expect(plan.days.map((day) => day.id).toList(), <String>[
        for (var index = 0; index < days; index++)
          '${plan.id}-day-${index + 1}',
      ]);
      expect(plan.days.every((day) => day.weekday == 0), isTrue);
      expect(plan.days.map((day) => day.order).toList(), <int>[
        for (var index = 0; index < days; index++) index,
      ]);

      final slots = plan.days.map((day) => day.slotKey).toList();
      expect(slots.every((slot) => slot.isNotEmpty), isTrue);
      expect(slots.toSet(), hasLength(days), reason: '$days days');
    }
  });

  test('split style selection is deterministic and valid', () {
    for (final style in SplitStyle.values) {
      for (var days = 1; days <= 7; days++) {
        final plan = generator().generate(
          goals: const <Goal>[Goal.getStronger],
          experienceLevel: ExperienceLevel.regular,
          daysPerWeek: days,
          splitStyle: style,
          availableEquipment: EquipmentGroup.values,
        );

        expect(plan.isFallback, isFalse, reason: '$style $days');
        expect(plan.splitStyle, style);
        expect(plan.days, hasLength(days));
        expect(plan.days.every((day) => day.slotKey.isNotEmpty), isTrue);
        if (style == SplitStyle.fullBody && days > 1) {
          expect(
            plan.days.every((day) => day.name.startsWith('Full Body')),
            isTrue,
          );
        }
        if (style == SplitStyle.upperLower && days > 1) {
          expect(
            plan.days.every(
              (day) => day.name.contains('Upper') || day.name.contains('Lower'),
            ),
            isTrue,
          );
        }
      }
    }
  });

  test('regeneration is stable for the same rotation inputs', () {
    TrainingPlanKey keyOf(PlanGeneratorService service) {
      final plan = service.generate(
        goals: const <Goal>[Goal.buildMuscle],
        experienceLevel: ExperienceLevel.gymRat,
        daysPerWeek: 4,
        splitStyle: SplitStyle.upperLower,
      );
      return TrainingPlanKey(
        plan.id,
        plan.days
            .map((day) => '${day.order}:${day.slotKey}:${day.name}')
            .join('|'),
      );
    }

    expect(keyOf(generator()), keyOf(generator()));
  });
}

class TrainingPlanKey {
  const TrainingPlanKey(this.id, this.days);

  final String id;
  final String days;

  @override
  bool operator ==(Object other) {
    return other is TrainingPlanKey && other.id == id && other.days == days;
  }

  @override
  int get hashCode => Object.hash(id, days);
}
