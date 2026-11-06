import 'dart:math' as math;

import '../models/exercise.dart';
import '../models/experience_level.dart';
import '../models/goal.dart';
import '../models/plan_day.dart';
import '../models/plan_exercise.dart';
import '../models/training_plan.dart';

/// Builds the deterministic week 1 training template from DESIGN.md 7.6.
///
/// The generator is pure. Pass the exercise library at construction and a
/// fixed `now` function in tests to keep results reproducible.
class PlanGeneratorService {
  PlanGeneratorService({
    required List<Exercise> exercises,
    DateTime Function()? now,
    this.sessionMinutes = 55,
  }) : _exercises = List<Exercise>.unmodifiable(exercises),
       _now = now ?? DateTime.now;

  final List<Exercise> _exercises;
  final DateTime Function() _now;
  final int sessionMinutes;

  /// Set when the last generation call had to recover from missing input.
  String? lastWarning;

  static const List<int> _defaultWeekdays = <int>[1, 3, 5, 2, 4, 6, 7];

  /// Generates a plan, or a fallback full-body plan when generation fails.
  TrainingPlan generate({
    required List<Goal> goals,
    required ExperienceLevel experienceLevel,
    required int daysPerWeek,
    required List<int> trainingDays,
  }) {
    try {
      lastWarning = null;
      if (daysPerWeek < 1 || daysPerWeek > 7) {
        throw ArgumentError.value(
          daysPerWeek,
          'daysPerWeek',
          'Must be between 1 and 7',
        );
      }
      if (_exercises.isEmpty) {
        throw StateError('Exercise library is empty');
      }

      if (goals.isEmpty) {
        lastWarning = 'No goals provided, defaulting to build muscle.';
      }
      final primaryGoal = goals.isEmpty ? Goal.buildMuscle : goals.first;
      final normalizedDays = _normalizeDays(trainingDays, daysPerWeek);
      final split = _splitFor(normalizedDays.length);
      return _buildPlan(
        goals: goals,
        primaryGoal: primaryGoal,
        experienceLevel: experienceLevel,
        trainingDays: normalizedDays,
        templates: split.days,
        splitName: split.name,
        isFallback: false,
      );
    } catch (_) {
      return fallback(
        goals: goals,
        experienceLevel: experienceLevel,
        daysPerWeek: daysPerWeek,
        trainingDays: trainingDays,
      );
    }
  }

  /// Safe full-body plan used when normal generation fails.
  TrainingPlan fallback({
    required List<Goal> goals,
    required ExperienceLevel experienceLevel,
    required int daysPerWeek,
    required List<int> trainingDays,
  }) {
    lastWarning ??= 'Plan generation failed, using the Starter plan.';
    final normalizedDays = _normalizeDays(
      trainingDays,
      daysPerWeek.clamp(1, 7).toInt(),
    );
    final primaryGoal = goals.isEmpty ? Goal.buildMuscle : goals.first;
    final templates = List<_DayTemplate>.generate(
      normalizedDays.length,
      (_) => const _DayTemplate(name: 'Full Body', muscleGroups: _fullBody),
    );
    return _buildPlan(
      goals: goals,
      primaryGoal: primaryGoal,
      experienceLevel: experienceLevel,
      trainingDays: normalizedDays,
      templates: templates,
      splitName: 'Starter plan',
      isFallback: true,
    );
  }

  TrainingPlan _buildPlan({
    required List<Goal> goals,
    required Goal primaryGoal,
    required ExperienceLevel experienceLevel,
    required List<int> trainingDays,
    required List<_DayTemplate> templates,
    required String splitName,
    required bool isFallback,
  }) {
    final planId = _planId(
      goals: goals,
      experienceLevel: experienceLevel,
      trainingDays: trainingDays,
      isFallback: isFallback,
    );
    final days = <PlanDay>[];
    for (var index = 0; index < templates.length; index++) {
      final template = templates[index];
      final weekday = trainingDays[index];
      final exercises = template.isRecovery
          ? const <PlanExercise>[]
          : _selectExercises(
              template.muscleGroups,
              primaryGoal,
              experienceLevel,
            );
      days.add(
        PlanDay(
          id: '$planId-day-$weekday',
          weekday: weekday,
          name: template.name,
          muscleGroups: template.muscleGroups,
          estimatedMinutes: template.isRecovery
              ? 20
              : _estimatedMinutes(exercises),
          exercises: exercises,
        ),
      );
    }

    return TrainingPlan(
      id: planId,
      goal: primaryGoal,
      goals: List<Goal>.unmodifiable(goals),
      experienceLevel: experienceLevel,
      daysPerWeek: trainingDays.length,
      trainingDays: List<int>.unmodifiable(trainingDays),
      splitName: splitName,
      days: List<PlanDay>.unmodifiable(days),
      generatedAt: _now(),
      isFallback: isFallback,
    );
  }

  List<PlanExercise> _selectExercises(
    List<String> muscleGroups,
    Goal goal,
    ExperienceLevel experienceLevel,
  ) {
    if (muscleGroups.isEmpty) {
      return const <PlanExercise>[];
    }
    final count = (sessionMinutes / 9).round().clamp(5, 7).toInt();
    final pools = <String, List<Exercise>>{
      for (final group in muscleGroups)
        group: _pool(group, goal, experienceLevel),
    };
    final selected = <Exercise>[];
    final usedIds = <String>{};
    var groupIndex = 0;
    var misses = 0;
    while (selected.length < count && misses < muscleGroups.length) {
      final group = muscleGroups[groupIndex % muscleGroups.length];
      final pool = pools[group] ?? const <Exercise>[];
      Exercise? pick;
      for (final exercise in pool) {
        if (!usedIds.contains(exercise.id)) {
          pick = exercise;
          break;
        }
      }
      if (pick == null) {
        misses++;
      } else {
        selected.add(pick);
        usedIds.add(pick.id);
        misses = 0;
      }
      groupIndex++;
    }

    final groupOrder = <String, int>{
      for (var index = 0; index < muscleGroups.length; index++)
        muscleGroups[index]: index,
    };
    selected.sort((a, b) {
      final compoundRank = (a.isCompound ? 0 : 1).compareTo(
        b.isCompound ? 0 : 1,
      );
      if (compoundRank != 0) {
        return compoundRank;
      }
      final groupRank = (groupOrder[a.primaryMuscle] ?? 99).compareTo(
        groupOrder[b.primaryMuscle] ?? 99,
      );
      if (groupRank != 0) {
        return groupRank;
      }
      return a.id.compareTo(b.id);
    });

    final prescription = _prescriptionFor(goal);
    var addedCompoundSet = false;
    final result = <PlanExercise>[];
    for (var index = 0; index < selected.length; index++) {
      final exercise = selected[index];
      final isFirstCompound = exercise.isCompound && !addedCompoundSet;
      if (isFirstCompound) {
        addedCompoundSet = true;
      }
      result.add(
        PlanExercise(
          exerciseId: exercise.id,
          sets: _setsFor(prescription.sets, experienceLevel, isFirstCompound),
          repsLow: prescription.repsLow,
          repsHigh: prescription.repsHigh,
          restSeconds: prescription.restSeconds,
          order: index,
        ),
      );
    }
    return List<PlanExercise>.unmodifiable(result);
  }

  List<Exercise> _pool(
    String muscle,
    Goal goal,
    ExperienceLevel experienceLevel,
  ) {
    final pool =
        _exercises
            .where((exercise) => exercise.primaryMuscle == muscle)
            .toList()
          ..sort((a, b) {
            final equipmentRank = _equipmentRank(
              experienceLevel,
              a.equipment,
            ).compareTo(_equipmentRank(experienceLevel, b.equipment));
            if (equipmentRank != 0) {
              return equipmentRank;
            }
            final compoundRank = (b.isCompound ? 1 : 0).compareTo(
              a.isCompound ? 1 : 0,
            );
            if (compoundRank != 0) {
              return compoundRank;
            }
            return a.id.compareTo(b.id);
          });
    if (pool.isEmpty) {
      return pool;
    }
    final offset = (goal.index + muscle.length) % pool.length;
    return <Exercise>[...pool.skip(offset), ...pool.take(offset)];
  }

  int _equipmentRank(ExperienceLevel level, String equipment) {
    switch (level) {
      case ExperienceLevel.beginner:
        return switch (equipment) {
          'Machine' => 0,
          'Dumbbell' => 1,
          'Cable' => 2,
          'Bodyweight' => 3,
          'Kettlebell' => 4,
          'EZ Bar' => 5,
          'Barbell' => 6,
          _ => 7,
        };
      case ExperienceLevel.veteran:
        return switch (equipment) {
          'Barbell' => 0,
          'Dumbbell' => 1,
          'Bodyweight' => 2,
          'Kettlebell' => 3,
          'EZ Bar' => 4,
          'Machine' => 5,
          'Cable' => 6,
          _ => 7,
        };
      case ExperienceLevel.regular:
      case ExperienceLevel.gymRat:
        return 0;
    }
  }

  int _setsFor(int baseSets, ExperienceLevel level, bool isFirstCompound) {
    var sets = baseSets;
    switch (level) {
      case ExperienceLevel.beginner:
        sets -= 1;
        break;
      case ExperienceLevel.gymRat:
      case ExperienceLevel.veteran:
        if (isFirstCompound) {
          sets += 1;
        }
        break;
      case ExperienceLevel.regular:
        break;
    }
    return sets.clamp(1, 6).toInt();
  }

  int _estimatedMinutes(List<PlanExercise> exercises) {
    final seconds = exercises.fold<int>(
      0,
      (total, exercise) =>
          total +
          exercise.sets * (exercise.repsHigh * 4 + exercise.restSeconds),
    );
    return math.max(20, (seconds / 60).ceil().clamp(20, 90).toInt());
  }

  List<int> _normalizeDays(List<int> trainingDays, int daysPerWeek) {
    final count = daysPerWeek.clamp(1, 7).toInt();
    final days =
        trainingDays.where((day) => day >= 1 && day <= 7).toSet().toList()
          ..sort();
    for (final day in _defaultWeekdays) {
      if (days.length >= count) {
        break;
      }
      if (!days.contains(day)) {
        days.add(day);
      }
    }
    days.sort();
    if (days.length > count) {
      return days.sublist(0, count);
    }
    return days;
  }

  String _planId({
    required List<Goal> goals,
    required ExperienceLevel experienceLevel,
    required List<int> trainingDays,
    required bool isFallback,
  }) {
    final goalKey = goals.isEmpty
        ? Goal.buildMuscle.name
        : goals.map((goal) => goal.name).join('-');
    final prefix = isFallback ? 'starter' : 'plan';
    return '$prefix-$goalKey-${experienceLevel.name}-${trainingDays.join('-')}';
  }

  _GoalPrescription _prescriptionFor(Goal goal) {
    switch (goal) {
      case Goal.buildMuscle:
        return const _GoalPrescription(
          sets: 3,
          repsLow: 8,
          repsHigh: 12,
          restSeconds: 75,
        );
      case Goal.getStronger:
        return const _GoalPrescription(
          sets: 4,
          repsLow: 3,
          repsHigh: 6,
          restSeconds: 150,
        );
      case Goal.loseWeight:
        return const _GoalPrescription(
          sets: 3,
          repsLow: 12,
          repsHigh: 15,
          restSeconds: 50,
        );
      case Goal.stayHealthy:
        return const _GoalPrescription(
          sets: 2,
          repsLow: 10,
          repsHigh: 15,
          restSeconds: 60,
        );
    }
  }

  _SplitTemplate _splitFor(int days) {
    switch (days) {
      case 1:
        return const _SplitTemplate(
          name: 'Full Body',
          days: <_DayTemplate>[
            _DayTemplate(name: 'Full Body', muscleGroups: _fullBody),
          ],
        );
      case 2:
        return const _SplitTemplate(
          name: 'Full Body A / Full Body B',
          days: <_DayTemplate>[
            _DayTemplate(name: 'Full Body A', muscleGroups: _fullBodyA),
            _DayTemplate(name: 'Full Body B', muscleGroups: _fullBodyB),
          ],
        );
      case 3:
        return const _SplitTemplate(
          name: 'Push / Pull / Legs',
          days: <_DayTemplate>[_push, _pull, _legs],
        );
      case 4:
        return const _SplitTemplate(
          name: 'Upper / Lower / Upper / Lower',
          days: <_DayTemplate>[_upper, _lower, _upper, _lower],
        );
      case 5:
        return const _SplitTemplate(
          name: 'Push / Pull / Legs / Upper / Lower',
          days: <_DayTemplate>[_push, _pull, _legs, _upper, _lower],
        );
      case 6:
        return const _SplitTemplate(
          name: 'Push / Pull / Legs / Push / Pull / Legs',
          days: <_DayTemplate>[_push, _pull, _legs, _push, _pull, _legs],
        );
      case 7:
      default:
        return const _SplitTemplate(
          name: 'Push / Pull / Legs / Push / Pull / Legs / Active Recovery',
          days: <_DayTemplate>[
            _push,
            _pull,
            _legs,
            _push,
            _pull,
            _legs,
            _DayTemplate(
              name: 'Active Recovery',
              muscleGroups: <String>[],
              isRecovery: true,
            ),
          ],
        );
    }
  }
}

const List<String> _fullBody = <String>[
  'Chest',
  'Back',
  'Quads',
  'Hamstrings',
  'Shoulders',
  'Core',
];

const List<String> _fullBodyA = <String>['Chest', 'Back', 'Quads', 'Core'];

const List<String> _fullBodyB = <String>[
  'Shoulders',
  'Back',
  'Hamstrings',
  'Glutes',
];

const _DayTemplate _push = _DayTemplate(
  name: 'Push',
  muscleGroups: <String>['Chest', 'Shoulders', 'Triceps'],
);

const _DayTemplate _pull = _DayTemplate(
  name: 'Pull',
  muscleGroups: <String>['Back', 'Biceps', 'Forearms'],
);

const _DayTemplate _legs = _DayTemplate(
  name: 'Legs',
  muscleGroups: <String>['Quads', 'Hamstrings', 'Glutes', 'Calves'],
);

const _DayTemplate _upper = _DayTemplate(
  name: 'Upper',
  muscleGroups: <String>['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps'],
);

const _DayTemplate _lower = _DayTemplate(
  name: 'Lower',
  muscleGroups: <String>['Quads', 'Hamstrings', 'Glutes', 'Calves', 'Core'],
);

class _DayTemplate {
  const _DayTemplate({
    required this.name,
    required this.muscleGroups,
    this.isRecovery = false,
  });

  final String name;
  final List<String> muscleGroups;
  final bool isRecovery;
}

class _SplitTemplate {
  const _SplitTemplate({required this.name, required this.days});

  final String name;
  final List<_DayTemplate> days;
}

class _GoalPrescription {
  const _GoalPrescription({
    required this.sets,
    required this.repsLow,
    required this.repsHigh,
    required this.restSeconds,
  });

  final int sets;
  final int repsLow;
  final int repsHigh;
  final int restSeconds;
}
