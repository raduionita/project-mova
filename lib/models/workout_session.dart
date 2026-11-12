import 'session_exercise.dart';

enum SessionStatus { active, paused, completed, discarded }

enum SessionSource { plan, routine, empty, walk, run }

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
    this.schemaVersion = 2,
    required this.id,
    required this.name,
    this.displayTitle = '',
    this.sourceLabel = '',
    required this.source,
    this.planDayId,
    this.routineId,
    this.slotKey,
    this.muscleGroups = const <String>[],
    this.focusPromptShown = false,
    required this.startedAt,
    this.completedAt,
    required this.status,
    required this.exercises,
    this.notes = '',
    this.distanceMeters,
    this.pausedSeconds = 0,
    this.pausedAt,
  });

  final int schemaVersion;
  final String id;

  /// Legacy session name, kept for v1 sessions and social posts.
  final String name;

  /// Immutable title shown in history and the calendar.
  final String displayTitle;
  final String sourceLabel;
  final SessionSource source;
  final String? planDayId;
  final String? routineId;

  /// Rotation slot captured when the session started.
  final String? slotKey;
  final List<String> muscleGroups;
  final bool focusPromptShown;
  final DateTime startedAt;
  final DateTime? completedAt;
  final SessionStatus status;
  final List<SessionExercise> exercises;
  final String notes;
  final double? distanceMeters;
  final int pausedSeconds;
  final DateTime? pausedAt;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    final rawMuscles = json['muscleGroups'];
    final source = SessionSource.values.firstWhere(
      (source) => source.name == json['source'],
      orElse: () => SessionSource.empty,
    );
    final name = json['name'] as String? ?? '';
    return WorkoutSession(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      name: name,
      displayTitle: json['displayTitle'] as String? ?? name,
      sourceLabel:
          json['sourceLabel'] as String? ?? _defaultSourceLabel(source),
      source: source,
      planDayId: json['planDayId'] as String?,
      routineId: json['routineId'] as String?,
      slotKey: json['slotKey'] as String?,
      muscleGroups: rawMuscles is List
          ? rawMuscles.whereType<String>().toList(growable: false)
          : const <String>[],
      focusPromptShown:
          json['focusPromptShown'] as bool? ?? source != SessionSource.empty,
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
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      pausedSeconds: (json['pausedSeconds'] as num?)?.toInt() ?? 0,
      pausedAt: _parseDate(json['pausedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'name': name,
      'displayTitle': displayTitle,
      'sourceLabel': sourceLabel,
      'source': source.name,
      'planDayId': planDayId,
      'routineId': routineId,
      'slotKey': slotKey,
      'muscleGroups': muscleGroups,
      'focusPromptShown': focusPromptShown,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'exercises': exercises
          .map((exercise) => exercise.toJson())
          .toList(growable: false),
      'notes': notes,
      'distanceMeters': distanceMeters,
      'pausedSeconds': pausedSeconds,
      'pausedAt': pausedAt?.toIso8601String(),
    };
  }

  WorkoutSession copyWith({
    int? schemaVersion,
    String? id,
    String? name,
    String? displayTitle,
    String? sourceLabel,
    SessionSource? source,
    Object? planDayId = _noChange,
    Object? routineId = _noChange,
    Object? slotKey = _noChange,
    List<String>? muscleGroups,
    bool? focusPromptShown,
    DateTime? startedAt,
    Object? completedAt = _noChange,
    SessionStatus? status,
    List<SessionExercise>? exercises,
    String? notes,
    Object? distanceMeters = _noChange,
    int? pausedSeconds,
    Object? pausedAt = _noChange,
  }) {
    return WorkoutSession(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      name: name ?? this.name,
      displayTitle: displayTitle ?? this.displayTitle,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      source: source ?? this.source,
      planDayId: identical(planDayId, _noChange)
          ? this.planDayId
          : planDayId as String?,
      routineId: identical(routineId, _noChange)
          ? this.routineId
          : routineId as String?,
      slotKey: identical(slotKey, _noChange)
          ? this.slotKey
          : slotKey as String?,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      focusPromptShown: focusPromptShown ?? this.focusPromptShown,
      startedAt: startedAt ?? this.startedAt,
      completedAt: identical(completedAt, _noChange)
          ? this.completedAt
          : completedAt as DateTime?,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      distanceMeters: identical(distanceMeters, _noChange)
          ? this.distanceMeters
          : distanceMeters as double?,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      pausedAt: identical(pausedAt, _noChange)
          ? this.pausedAt
          : pausedAt as DateTime?,
    );
  }
}

String _defaultSourceLabel(SessionSource source) {
  switch (source) {
    case SessionSource.plan:
      return 'Plan';
    case SessionSource.routine:
      return 'Routine';
    case SessionSource.empty:
      return 'Empty';
    case SessionSource.walk:
      return 'Walk';
    case SessionSource.run:
      return 'Run';
  }
}
