const Object _noChange = Object();

/// One set inside a workout session.
class WorkoutSet {
  const WorkoutSet({
    this.schemaVersion = 1,
    required this.id,
    required this.index,
    required this.weightKg,
    required this.reps,
    this.isWarmup = false,
    this.completed = false,
    this.completedAt,
  });

  final int schemaVersion;
  final String id;
  final int index;
  final double weightKg;
  final int reps;
  final bool isWarmup;
  final bool completed;
  final DateTime? completedAt;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      index: (json['index'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      isWarmup: json['isWarmup'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'index': index,
      'weightKg': weightKg,
      'reps': reps,
      'isWarmup': isWarmup,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  WorkoutSet copyWith({
    int? schemaVersion,
    String? id,
    int? index,
    double? weightKg,
    int? reps,
    bool? isWarmup,
    bool? completed,
    Object? completedAt = _noChange,
  }) {
    return WorkoutSet(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      index: index ?? this.index,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      isWarmup: isWarmup ?? this.isWarmup,
      completed: completed ?? this.completed,
      completedAt: identical(completedAt, _noChange)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }
}
