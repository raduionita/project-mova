import 'equipment_group.dart';
import 'experience_level.dart';
import 'gender.dart';
import 'goal.dart';

const Object _noChange = Object();

DateTime? _parseDate(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

String _parseDisplayName(Object? value) {
  if (value is! String) {
    return '';
  }
  final trimmed = value.trim();
  return trimmed == 'Athlete' ? '' : trimmed;
}

/// Local guest profile.
class UserProfile {
  const UserProfile({
    this.schemaVersion = 1,
    required this.id,
    this.displayName = '',
    this.gender,
    this.birthDate,
    this.heightCm = 0.0,
    this.goals = const <Goal>[],
    this.experienceLevel,
    this.bodyWeightKg = 0.0,
    this.availableEquipment = EquipmentGroup.values,
    required this.createdAt,
    required this.updatedAt,
  });

  final int schemaVersion;
  final String id;
  final String displayName;
  final Gender? gender;
  final DateTime? birthDate;
  final double heightCm;
  final List<Goal> goals;
  final ExperienceLevel? experienceLevel;
  final double bodyWeightKg;
  final List<EquipmentGroup> availableEquipment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal? get primaryGoal => goals.isEmpty ? null : goals.first;

  bool get isComplete =>
      gender != null &&
      birthDate != null &&
      goals.isNotEmpty &&
      experienceLevel != null;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawGoals = json['goals'];
    return UserProfile(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      displayName: _parseDisplayName(json['displayName']),
      gender: Gender.values
          .where((gender) => gender.name == json['gender'])
          .firstOrNull,
      birthDate: _parseDate(json['birthDate']),
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
      experienceLevel: ExperienceLevel.values
          .where((level) => level.name == json['experienceLevel'])
          .firstOrNull,
      bodyWeightKg: (json['bodyWeightKg'] as num?)?.toDouble() ?? 0.0,
      availableEquipment: EquipmentGroup.fromJson(json['availableEquipment']),
      createdAt:
          _parseDate(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _parseDate(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'displayName': displayName,
      'gender': gender?.name,
      'birthDate': birthDate?.toIso8601String(),
      'heightCm': heightCm,
      'goals': goals.map((goal) => goal.name).toList(growable: false),
      'experienceLevel': experienceLevel?.name,
      'bodyWeightKg': bodyWeightKg,
      'availableEquipment': EquipmentGroup.toJson(availableEquipment),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? schemaVersion,
    String? id,
    String? displayName,
    Object? gender = _noChange,
    Object? birthDate = _noChange,
    double? heightCm,
    List<Goal>? goals,
    Object? experienceLevel = _noChange,
    double? bodyWeightKg,
    List<EquipmentGroup>? availableEquipment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      gender: identical(gender, _noChange) ? this.gender : gender as Gender?,
      birthDate: identical(birthDate, _noChange)
          ? this.birthDate
          : birthDate as DateTime?,
      heightCm: heightCm ?? this.heightCm,
      goals: goals ?? this.goals,
      experienceLevel: identical(experienceLevel, _noChange)
          ? this.experienceLevel
          : experienceLevel as ExperienceLevel?,
      bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
