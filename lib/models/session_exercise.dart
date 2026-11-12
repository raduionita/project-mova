import 'progression_suggestion.dart';
import 'workout_set.dart';

const Object _noChange = Object();

/// Exercise performed inside a workout session.
class SessionExercise {
  const SessionExercise({
    this.schemaVersion = 2,
    required this.id,
    required this.exerciseId,
    required this.order,
    required this.sets,
    this.notes = '',
    this.progression,
    this.primaryMuscle,
    this.secondaryMuscles = const <String>[],
  });

  final int schemaVersion;
  final String id;
  final String exerciseId;
  final int order;
  final List<WorkoutSet> sets;
  final String notes;
  final ProgressionSuggestion? progression;

  /// Muscle snapshot captured when the exercise enters the session.
  final String? primaryMuscle;
  final List<String> secondaryMuscles;

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'];
    final rawSecondary = json['secondaryMuscles'];
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
      progression: json['progression'] is Map<String, dynamic>
          ? ProgressionSuggestion.fromJson(
              json['progression'] as Map<String, dynamic>,
            )
          : null,
      primaryMuscle: json['primaryMuscle'] as String?,
      secondaryMuscles: rawSecondary is List
          ? rawSecondary.whereType<String>().toList(growable: false)
          : const <String>[],
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
      'progression': progression?.toJson(),
      'primaryMuscle': primaryMuscle,
      'secondaryMuscles': secondaryMuscles,
    };
  }

  SessionExercise copyWith({
    int? schemaVersion,
    String? id,
    String? exerciseId,
    int? order,
    List<WorkoutSet>? sets,
    String? notes,
    Object? progression = _noChange,
    Object? primaryMuscle = _noChange,
    List<String>? secondaryMuscles,
  }) {
    return SessionExercise(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      order: order ?? this.order,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      progression: identical(progression, _noChange)
          ? this.progression
          : progression as ProgressionSuggestion?,
      primaryMuscle: identical(primaryMuscle, _noChange)
          ? this.primaryMuscle
          : primaryMuscle as String?,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
    );
  }
}
