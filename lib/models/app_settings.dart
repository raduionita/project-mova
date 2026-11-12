import 'unit_preferences.dart';

enum HealthProvider { none, appleHealth, healthConnect, unavailable }

/// App-wide preferences persisted locally.
class AppSettings {
  const AppSettings({
    this.schemaVersion = 1,
    this.unitPreferences = const UnitPreferences(),
    this.remindersEnabled = false,
    this.reminderWeekdays = const <int>[1, 3, 5],
    this.reminderHour = 18,
    this.reminderMinute = 0,
    this.healthProvider = HealthProvider.none,
    this.postWorkoutsToFeed = true,
    this.sampleFeedDismissed = false,
    this.restTimerEnabled = true,
  });

  final int schemaVersion;
  final UnitPreferences unitPreferences;
  final bool remindersEnabled;
  final List<int> reminderWeekdays;
  final int reminderHour;
  final int reminderMinute;
  final HealthProvider healthProvider;
  final bool postWorkoutsToFeed;
  final bool sampleFeedDismissed;
  final bool restTimerEnabled;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawUnitPreferences = json['unitPreferences'];
    final rawWeekdays = json['reminderWeekdays'];
    return AppSettings(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      unitPreferences: rawUnitPreferences is Map<String, dynamic>
          ? UnitPreferences.fromJson(rawUnitPreferences)
          : const UnitPreferences(),
      remindersEnabled: json['remindersEnabled'] as bool? ?? false,
      reminderWeekdays: rawWeekdays is List
          ? rawWeekdays
                .whereType<num>()
                .map((day) => day.toInt())
                .toList(growable: false)
          : const <int>[1, 3, 5],
      reminderHour: (json['reminderHour'] as num?)?.toInt() ?? 18,
      reminderMinute: (json['reminderMinute'] as num?)?.toInt() ?? 0,
      healthProvider: HealthProvider.values.firstWhere(
        (provider) => provider.name == json['healthProvider'],
        orElse: () => HealthProvider.none,
      ),
      postWorkoutsToFeed: json['postWorkoutsToFeed'] as bool? ?? true,
      sampleFeedDismissed: json['sampleFeedDismissed'] as bool? ?? false,
      restTimerEnabled: json['restTimerEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'unitPreferences': unitPreferences.toJson(),
      'remindersEnabled': remindersEnabled,
      'reminderWeekdays': reminderWeekdays,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'healthProvider': healthProvider.name,
      'postWorkoutsToFeed': postWorkoutsToFeed,
      'sampleFeedDismissed': sampleFeedDismissed,
      'restTimerEnabled': restTimerEnabled,
    };
  }

  AppSettings copyWith({
    int? schemaVersion,
    UnitPreferences? unitPreferences,
    bool? remindersEnabled,
    List<int>? reminderWeekdays,
    int? reminderHour,
    int? reminderMinute,
    HealthProvider? healthProvider,
    bool? postWorkoutsToFeed,
    bool? sampleFeedDismissed,
    bool? restTimerEnabled,
  }) {
    return AppSettings(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      unitPreferences: unitPreferences ?? this.unitPreferences,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderWeekdays: reminderWeekdays ?? this.reminderWeekdays,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      healthProvider: healthProvider ?? this.healthProvider,
      postWorkoutsToFeed: postWorkoutsToFeed ?? this.postWorkoutsToFeed,
      sampleFeedDismissed: sampleFeedDismissed ?? this.sampleFeedDismissed,
      restTimerEnabled: restTimerEnabled ?? this.restTimerEnabled,
    );
  }
}
