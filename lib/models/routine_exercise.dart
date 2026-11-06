/// Prescribed exercise inside a saved routine.
class RoutineExercise {
  const RoutineExercise({
    this.schemaVersion = 1,
    required this.exerciseId,
    required this.sets,
    required this.repsLow,
    required this.repsHigh,
    required this.restSeconds,
    required this.order,
  });

  final int schemaVersion;
  final String exerciseId;
  final int sets;
  final int repsLow;
  final int repsHigh;
  final int restSeconds;
  final int order;

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    return RoutineExercise(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      exerciseId: json['exerciseId'] as String? ?? '',
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      repsLow: (json['repsLow'] as num?)?.toInt() ?? 0,
      repsHigh: (json['repsHigh'] as num?)?.toInt() ?? 0,
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exerciseId': exerciseId,
      'sets': sets,
      'repsLow': repsLow,
      'repsHigh': repsHigh,
      'restSeconds': restSeconds,
      'order': order,
    };
  }

  RoutineExercise copyWith({
    int? schemaVersion,
    String? exerciseId,
    int? sets,
    int? repsLow,
    int? repsHigh,
    int? restSeconds,
    int? order,
  }) {
    return RoutineExercise(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      repsLow: repsLow ?? this.repsLow,
      repsHigh: repsHigh ?? this.repsHigh,
      restSeconds: restSeconds ?? this.restSeconds,
      order: order ?? this.order,
    );
  }
}
