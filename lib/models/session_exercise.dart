import 'workout_set.dart';

/// Exercise performed inside a workout session.
class SessionExercise {
  const SessionExercise({
    this.schemaVersion = 1,
    required this.id,
    required this.exerciseId,
    required this.order,
    required this.sets,
    this.notes = '',
  });

  final int schemaVersion;
  final String id;
  final String exerciseId;
  final int order;
  final List<WorkoutSet> sets;
  final String notes;

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'];
    return SessionExercise(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      sets: rawSets is List
          ? rawSets
                .whereType<Map<String, dynamic>>()
                .map(WorkoutSet.fromJson)
                .toList(growable: false)
          : const <WorkoutSet>[],
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'exerciseId': exerciseId,
      'order': order,
      'sets': sets.map((set) => set.toJson()).toList(growable: false),
      'notes': notes,
    };
  }

  SessionExercise copyWith({
    int? schemaVersion,
    String? id,
    String? exerciseId,
    int? order,
    List<WorkoutSet>? sets,
    String? notes,
  }) {
    return SessionExercise(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      order: order ?? this.order,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }
}
