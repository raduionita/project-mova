import 'routine_exercise.dart';

/// User-created routine.
class Routine {
  const Routine({
    this.schemaVersion = 1,
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  final int schemaVersion;
  final String id;
  final String name;
  final List<RoutineExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Routine.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    return Routine(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      exercises: rawExercises is List
          ? rawExercises
                .whereType<Map<String, dynamic>>()
                .map(RoutineExercise.fromJson)
                .toList(growable: false)
          : const <RoutineExercise>[],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'name': name,
      'exercises': exercises
          .map((exercise) => exercise.toJson())
          .toList(growable: false),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Routine copyWith({
    int? schemaVersion,
    String? id,
    String? name,
    List<RoutineExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
