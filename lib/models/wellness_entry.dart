import '../common/date_keys.dart';

const Object _noChange = Object();

/// One day of local wellness data.
///
/// A single row per calendar day keeps quick adds idempotent and easy to edit.
class WellnessEntry {
  const WellnessEntry({
    this.schemaVersion = 1,
    required this.date,
    this.calories,
    this.proteinGrams,
    this.sleepMinutes,
    this.restingHeartRate,
    this.waistCm,
  });

  final int schemaVersion;

  /// Local midnight for the day this entry belongs to.
  final DateTime date;
  final int? calories;
  final int? proteinGrams;
  final int? sleepMinutes;
  final int? restingHeartRate;
  final double? waistCm;

  String get dateKey => DateKeys.dayKey(date);

  bool get hasNutrition => calories != null || proteinGrams != null;
  bool get hasSleep => sleepMinutes != null;
  bool get hasRestingHeartRate => restingHeartRate != null;
  bool get hasMeasurement => waistCm != null;

  factory WellnessEntry.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final parsed = rawDate is String ? DateTime.tryParse(rawDate) : null;
    final date = parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
    return WellnessEntry(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      date: DateTime(date.year, date.month, date.day),
      calories: (json['calories'] as num?)?.toInt(),
      proteinGrams: (json['proteinGrams'] as num?)?.toInt(),
      sleepMinutes: (json['sleepMinutes'] as num?)?.toInt(),
      restingHeartRate: (json['restingHeartRate'] as num?)?.toInt(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'date': DateKeys.dayKey(date),
      'calories': calories,
      'proteinGrams': proteinGrams,
      'sleepMinutes': sleepMinutes,
      'restingHeartRate': restingHeartRate,
      'waistCm': waistCm,
    };
  }

  WellnessEntry copyWith({
    int? schemaVersion,
    DateTime? date,
    Object? calories = _noChange,
    Object? proteinGrams = _noChange,
    Object? sleepMinutes = _noChange,
    Object? restingHeartRate = _noChange,
    Object? waistCm = _noChange,
  }) {
    return WellnessEntry(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      date: date ?? this.date,
      calories: identical(calories, _noChange)
          ? this.calories
          : calories as int?,
      proteinGrams: identical(proteinGrams, _noChange)
          ? this.proteinGrams
          : proteinGrams as int?,
      sleepMinutes: identical(sleepMinutes, _noChange)
          ? this.sleepMinutes
          : sleepMinutes as int?,
      restingHeartRate: identical(restingHeartRate, _noChange)
          ? this.restingHeartRate
          : restingHeartRate as int?,
      waistCm: identical(waistCm, _noChange)
          ? this.waistCm
          : waistCm as double?,
    );
  }
}
