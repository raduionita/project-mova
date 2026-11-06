/// Best estimated one-rep max for an exercise.
class PersonalRecord {
  const PersonalRecord({
    this.schemaVersion = 1,
    required this.exerciseId,
    required this.bestE1rmKg,
    required this.weightKg,
    required this.reps,
    required this.achievedAt,
    required this.sessionId,
    required this.previousBestKg,
  });

  final int schemaVersion;
  final String exerciseId;
  final double bestE1rmKg;
  final double weightKg;
  final int reps;
  final DateTime achievedAt;
  final String sessionId;
  final double previousBestKg;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      exerciseId: json['exerciseId'] as String? ?? '',
      bestE1rmKg: (json['bestE1rmKg'] as num?)?.toDouble() ?? 0.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      achievedAt:
          DateTime.tryParse(json['achievedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sessionId: json['sessionId'] as String? ?? '',
      previousBestKg: (json['previousBestKg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exerciseId': exerciseId,
      'bestE1rmKg': bestE1rmKg,
      'weightKg': weightKg,
      'reps': reps,
      'achievedAt': achievedAt.toIso8601String(),
      'sessionId': sessionId,
      'previousBestKg': previousBestKg,
    };
  }

  PersonalRecord copyWith({
    int? schemaVersion,
    String? exerciseId,
    double? bestE1rmKg,
    double? weightKg,
    int? reps,
    DateTime? achievedAt,
    String? sessionId,
    double? previousBestKg,
  }) {
    return PersonalRecord(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      exerciseId: exerciseId ?? this.exerciseId,
      bestE1rmKg: bestE1rmKg ?? this.bestE1rmKg,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      achievedAt: achievedAt ?? this.achievedAt,
      sessionId: sessionId ?? this.sessionId,
      previousBestKg: previousBestKg ?? this.previousBestKg,
    );
  }
}
