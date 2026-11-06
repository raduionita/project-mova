import 'session_exercise.dart';

enum SessionStatus { active, paused, completed, discarded }

enum SessionSource { plan, routine, empty, walk }

const Object _noChange = Object();

DateTime? _parseDate(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

/// Active, paused, completed, or discarded workout session.
class WorkoutSession {
  const WorkoutSession({
    this.schemaVersion = 1,
    required this.id,
    required this.name,
    required this.source,
    this.planDayId,
    this.routineId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    required this.exercises,
    this.notes = '',
    this.pausedSeconds = 0,
    this.pausedAt,
  });

  final int schemaVersion;
  final String id;
  final String name;
  final SessionSource source;
  final String? planDayId;
  final String? routineId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SessionStatus status;
  final List<SessionExercise> exercises;
  final String notes;
  final int pausedSeconds;
  final DateTime? pausedAt;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    return WorkoutSession(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      source: SessionSource.values.firstWhere(
        (source) => source.name == json['source'],
        orElse: () => SessionSource.empty,
      ),
      planDayId: json['planDayId'] as String?,
      routineId: json['routineId'] as String?,
      startedAt:
          _parseDate(json['startedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt: _parseDate(json['completedAt']),
      status: SessionStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => SessionStatus.active,
      ),
      exercises: rawExercises is List
          ? rawExercises
                .whereType<Map<String, dynamic>>()
                .map(SessionExercise.fromJson)
                .toList(growable: false)
          : const <SessionExercise>[],
      notes: json['notes'] as String? ?? '',
      pausedSeconds: (json['pausedSeconds'] as num?)?.toInt() ?? 0,
      pausedAt: _parseDate(json['pausedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'name': name,
      'source': source.name,
      'planDayId': planDayId,
      'routineId': routineId,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'exercises': exercises
          .map((exercise) => exercise.toJson())
          .toList(growable: false),
      'notes': notes,
      'pausedSeconds': pausedSeconds,
      'pausedAt': pausedAt?.toIso8601String(),
    };
  }

  WorkoutSession copyWith({
    int? schemaVersion,
    String? id,
    String? name,
    SessionSource? source,
    Object? planDayId = _noChange,
    Object? routineId = _noChange,
    DateTime? startedAt,
    Object? completedAt = _noChange,
    SessionStatus? status,
    List<SessionExercise>? exercises,
    String? notes,
    int? pausedSeconds,
    Object? pausedAt = _noChange,
  }) {
    return WorkoutSession(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      planDayId: identical(planDayId, _noChange)
          ? this.planDayId
          : planDayId as String?,
      routineId: identical(routineId, _noChange)
          ? this.routineId
          : routineId as String?,
      startedAt: startedAt ?? this.startedAt,
      completedAt: identical(completedAt, _noChange)
          ? this.completedAt
          : completedAt as DateTime?,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      pausedAt: identical(pausedAt, _noChange)
          ? this.pausedAt
          : pausedAt as DateTime?,
    );
  }
}
