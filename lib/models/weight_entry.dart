/// One body-weight entry for a local calendar day.
class WeightEntry {
  const WeightEntry({
    this.schemaVersion = 1,
    required this.dateKey,
    required this.weightKg,
    required this.updatedAt,
  });

  final int schemaVersion;

  /// Local day key in `YYYY-MM-DD` form.
  final String dateKey;
  final double weightKg;
  final DateTime updatedAt;

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      dateKey: json['dateKey'] as String? ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'dateKey': dateKey,
      'weightKg': weightKg,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WeightEntry copyWith({
    int? schemaVersion,
    String? dateKey,
    double? weightKg,
    DateTime? updatedAt,
  }) {
    return WeightEntry(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      dateKey: dateKey ?? this.dateKey,
      weightKg: weightKg ?? this.weightKg,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
