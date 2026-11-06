enum StepSource { health, manual }

/// Daily step count entry.
class StepEntry {
  const StepEntry({
    this.schemaVersion = 1,
    required this.dateKey,
    required this.steps,
    required this.source,
    required this.updatedAt,
  });

  final int schemaVersion;
  final String dateKey;
  final int steps;
  final StepSource source;
  final DateTime updatedAt;

  factory StepEntry.fromJson(Map<String, dynamic> json) {
    return StepEntry(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      dateKey: json['dateKey'] as String? ?? '',
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      source: StepSource.values.firstWhere(
        (source) => source.name == json['source'],
        orElse: () => StepSource.manual,
      ),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'dateKey': dateKey,
      'steps': steps,
      'source': source.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  StepEntry copyWith({
    int? schemaVersion,
    String? dateKey,
    int? steps,
    StepSource? source,
    DateTime? updatedAt,
  }) {
    return StepEntry(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      dateKey: dateKey ?? this.dateKey,
      steps: steps ?? this.steps,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
