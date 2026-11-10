import 'equipment_group.dart';
import 'experience_level.dart';
import 'gender.dart';
import 'goal.dart';
import 'unit_preferences.dart';

enum OnboardingStep {
  welcome,
  units,
  gender,
  birthDate,
  weight,
  height,
  goals,
  experience,
  schedule,
  equipment,
  notifications,
  plan,
}

const Object _noChange = Object();

DateTime? _parseDate(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

/// Draft persisted before every onboarding transition.
class OnboardingDraft {
  const OnboardingDraft({
    this.schemaVersion = 1,
    this.currentStep = OnboardingStep.welcome,
    this.unitPreferences = const UnitPreferences(),
    this.gender,
    this.birthDate,
    this.bodyWeightKg = 0.0,
    this.heightCm = 0.0,
    this.goals = const <Goal>[],
    this.experienceLevel = ExperienceLevel.regular,
    this.daysPerWeek,
    this.trainingDays = const <int>[],
    this.availableEquipment = EquipmentGroup.values,
    this.notificationsAsked = false,
    this.reminderHour = 18,
    this.reminderMinute = 0,
    required this.updatedAt,
  });

  final int schemaVersion;
  final OnboardingStep currentStep;
  final UnitPreferences unitPreferences;
  final Gender? gender;
  final DateTime? birthDate;
  final double bodyWeightKg;
  final double heightCm;
  final List<Goal> goals;
  final ExperienceLevel? experienceLevel;
  final int? daysPerWeek;
  final List<int> trainingDays;
  final List<EquipmentGroup> availableEquipment;
  final bool notificationsAsked;
  final int reminderHour;
  final int reminderMinute;
  final DateTime updatedAt;

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) {
    final rawGoals = json['goals'];
    final rawTrainingDays = json['trainingDays'];
    return OnboardingDraft(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      currentStep: OnboardingStep.values.firstWhere(
        (step) => step.name == json['currentStep'],
        orElse: () => OnboardingStep.welcome,
      ),
      unitPreferences: json['unitPreferences'] is Map<String, dynamic>
          ? UnitPreferences.fromJson(
              json['unitPreferences'] as Map<String, dynamic>,
            )
          : const UnitPreferences(),
      gender: Gender.values
          .where((gender) => gender.name == json['gender'])
          .firstOrNull,
      birthDate: _parseDate(json['birthDate']),
      bodyWeightKg: (json['bodyWeightKg'] as num?)?.toDouble() ?? 0.0,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0.0,
      goals: rawGoals is List
          ? rawGoals
                .whereType<String>()
                .map(
                  (name) => Goal.values
                      .where((goal) => goal.name == name)
                      .firstOrNull,
                )
                .whereType<Goal>()
                .toList(growable: false)
          : const <Goal>[],
      experienceLevel:
          ExperienceLevel.values
              .where((level) => level.name == json['experienceLevel'])
              .firstOrNull ??
          ExperienceLevel.regular,
      daysPerWeek: (json['daysPerWeek'] as num?)?.toInt(),
      trainingDays: rawTrainingDays is List
          ? rawTrainingDays
                .whereType<num>()
                .map((day) => day.toInt())
                .toList(growable: false)
          : const <int>[],
      availableEquipment: EquipmentGroup.fromJson(json['availableEquipment']),
      notificationsAsked: json['notificationsAsked'] as bool? ?? false,
      reminderHour: ((json['reminderHour'] as num?)?.toInt() ?? 18)
          .clamp(0, 23)
          .toInt(),
      reminderMinute: ((json['reminderMinute'] as num?)?.toInt() ?? 0)
          .clamp(0, 59)
          .toInt(),
      updatedAt:
          _parseDate(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'currentStep': currentStep.name,
      'unitPreferences': unitPreferences.toJson(),
      'gender': gender?.name,
      'birthDate': birthDate?.toIso8601String(),
      'bodyWeightKg': bodyWeightKg,
      'heightCm': heightCm,
      'goals': goals.map((goal) => goal.name).toList(growable: false),
      'experienceLevel': experienceLevel?.name,
      'daysPerWeek': daysPerWeek,
      'trainingDays': trainingDays,
      'availableEquipment': EquipmentGroup.toJson(availableEquipment),
      'notificationsAsked': notificationsAsked,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  OnboardingDraft copyWith({
    int? schemaVersion,
    OnboardingStep? currentStep,
    UnitPreferences? unitPreferences,
    Object? gender = _noChange,
    Object? birthDate = _noChange,
    double? bodyWeightKg,
    double? heightCm,
    List<Goal>? goals,
    Object? experienceLevel = _noChange,
    Object? daysPerWeek = _noChange,
    List<int>? trainingDays,
    List<EquipmentGroup>? availableEquipment,
    bool? notificationsAsked,
    int? reminderHour,
    int? reminderMinute,
    DateTime? updatedAt,
  }) {
    return OnboardingDraft(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      currentStep: currentStep ?? this.currentStep,
      unitPreferences: unitPreferences ?? this.unitPreferences,
      gender: identical(gender, _noChange) ? this.gender : gender as Gender?,
      birthDate: identical(birthDate, _noChange)
          ? this.birthDate
          : birthDate as DateTime?,
      bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
      heightCm: heightCm ?? this.heightCm,
      goals: goals ?? this.goals,
      experienceLevel: identical(experienceLevel, _noChange)
          ? this.experienceLevel
          : experienceLevel as ExperienceLevel?,
      daysPerWeek: identical(daysPerWeek, _noChange)
          ? this.daysPerWeek
          : daysPerWeek as int?,
      trainingDays: trainingDays ?? this.trainingDays,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      notificationsAsked: notificationsAsked ?? this.notificationsAsked,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
