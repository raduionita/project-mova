import 'plan_exercise.dart';

/// One training day inside a generated plan.
class PlanDay {
  const PlanDay({
    this.schemaVersion = 1,
    required this.id,
    required this.weekday,
    required this.name,
    required this.muscleGroups,
    required this.estimatedMinutes,
    required this.exercises,
  });

  final int schemaVersion;
  final String id;
  final int weekday;
  final String name;
  final List<String> muscleGroups;
  final int estimatedMinutes;
  final List<PlanExercise> exercises;

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    final rawMuscleGroups = json['muscleGroups'];
    final rawExercises = json['exercises'];
    return PlanDay(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      weekday: (json['weekday'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? '',
      muscleGroups: rawMuscleGroups is List
          ? rawMuscleGroups.whereType<String>().toList(growable: false)
          : const <String>[],
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      exercises: rawExercises is List
          ? rawExercises
                .whereType<Map<String, dynamic>>()
                .map(PlanExercise.fromJson)
                .toList(growable: false)
          : const <PlanExercise>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'weekday': weekday,
      'name': name,
      'muscleGroups': muscleGroups,
      'estimatedMinutes': estimatedMinutes,
      'exercises': exercises
          .map((exercise) => exercise.toJson())
          .toList(growable: false),
    };
  }

  PlanDay copyWith({
    int? schemaVersion,
    String? id,
    int? weekday,
    String? name,
    List<String>? muscleGroups,
    int? estimatedMinutes,
    List<PlanExercise>? exercises,
  }) {
    return PlanDay(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      weekday: weekday ?? this.weekday,
      name: name ?? this.name,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      exercises: exercises ?? this.exercises,
    );
  }
}
