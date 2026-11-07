/// How the next weight was selected from the previous performance.
enum ProgressionAction { repeat, increase }

/// A prefill suggestion for one exercise in a new workout.
class ProgressionSuggestion {
  const ProgressionSuggestion({
    required this.exerciseId,
    required this.weightKg,
    required this.reps,
    required this.previousWeightKg,
    required this.previousReps,
    required this.action,
    this.sourceWorkoutId,
    this.sourceSetId,
  });

  final String exerciseId;
  final double weightKg;
  final int reps;
  final double previousWeightKg;
  final int previousReps;
  final ProgressionAction action;
  final String? sourceWorkoutId;
  final String? sourceSetId;

  bool get isIncrease => action == ProgressionAction.increase;

  factory ProgressionSuggestion.fromJson(Map<String, dynamic> json) {
    return ProgressionSuggestion(
      exerciseId: json['exerciseId'] as String? ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      previousWeightKg: (json['previousWeightKg'] as num?)?.toDouble() ?? 0,
      previousReps: (json['previousReps'] as num?)?.toInt() ?? 0,
      action: ProgressionAction.values.firstWhere(
        (item) => item.name == json['action'],
        orElse: () => ProgressionAction.repeat,
      ),
      sourceWorkoutId: json['sourceWorkoutId'] as String?,
      sourceSetId: json['sourceSetId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'weightKg': weightKg,
      'reps': reps,
      'previousWeightKg': previousWeightKg,
      'previousReps': previousReps,
      'action': action.name,
      'sourceWorkoutId': sourceWorkoutId,
      'sourceSetId': sourceSetId,
    };
  }

  ProgressionSuggestion copyWith({
    String? exerciseId,
    double? weightKg,
    int? reps,
    double? previousWeightKg,
    int? previousReps,
    ProgressionAction? action,
    String? sourceWorkoutId,
    String? sourceSetId,
  }) {
    return ProgressionSuggestion(
      exerciseId: exerciseId ?? this.exerciseId,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      previousWeightKg: previousWeightKg ?? this.previousWeightKg,
      previousReps: previousReps ?? this.previousReps,
      action: action ?? this.action,
      sourceWorkoutId: sourceWorkoutId ?? this.sourceWorkoutId,
      sourceSetId: sourceSetId ?? this.sourceSetId,
    );
  }
}
