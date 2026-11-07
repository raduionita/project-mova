import 'equipment_group.dart';
import 'experience_level.dart';
import 'goal.dart';
import 'plan_day.dart';

/// Generated weekly training plan.
class TrainingPlan {
  const TrainingPlan({
    this.schemaVersion = 1,
    required this.id,
    required this.goal,
    this.goals = const <Goal>[],
    required this.experienceLevel,
    required this.daysPerWeek,
    required this.trainingDays,
    required this.splitName,
    required this.days,
    required this.generatedAt,
    this.availableEquipment = EquipmentGroup.values,
    this.isFallback = false,
  });

  final int schemaVersion;
  final String id;
  final Goal goal;
  final List<Goal> goals;
  final ExperienceLevel experienceLevel;
  final int daysPerWeek;
  final List<int> trainingDays;
  final String splitName;
  final List<PlanDay> days;
  final DateTime generatedAt;
  final List<EquipmentGroup> availableEquipment;
  final bool isFallback;

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    final rawGoals = json['goals'];
    final rawTrainingDays = json['trainingDays'];
    final rawDays = json['days'];
    return TrainingPlan(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      goal: Goal.values.firstWhere(
        (goal) => goal.name == json['goal'],
        orElse: () => Goal.stayHealthy,
      ),
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
      experienceLevel: ExperienceLevel.values.firstWhere(
        (level) => level.name == json['experienceLevel'],
        orElse: () => ExperienceLevel.beginner,
      ),
      daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? 0,
      trainingDays: rawTrainingDays is List
          ? rawTrainingDays
                .whereType<num>()
                .map((day) => day.toInt())
                .toList(growable: false)
          : const <int>[],
      splitName: json['splitName'] as String? ?? '',
      days: rawDays is List
          ? rawDays
                .whereType<Map<String, dynamic>>()
                .map(PlanDay.fromJson)
                .toList(growable: false)
          : const <PlanDay>[],
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      availableEquipment: EquipmentGroup.fromJson(json['availableEquipment']),
      isFallback: json['isFallback'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'goal': goal.name,
      'goals': goals.map((goal) => goal.name).toList(growable: false),
      'experienceLevel': experienceLevel.name,
      'daysPerWeek': daysPerWeek,
      'trainingDays': trainingDays,
      'splitName': splitName,
      'days': days.map((day) => day.toJson()).toList(growable: false),
      'generatedAt': generatedAt.toIso8601String(),
      'availableEquipment': EquipmentGroup.toJson(availableEquipment),
      'isFallback': isFallback,
    };
  }

  TrainingPlan copyWith({
    int? schemaVersion,
    String? id,
    Goal? goal,
    List<Goal>? goals,
    ExperienceLevel? experienceLevel,
    int? daysPerWeek,
    List<int>? trainingDays,
    String? splitName,
    List<PlanDay>? days,
    DateTime? generatedAt,
    List<EquipmentGroup>? availableEquipment,
    bool? isFallback,
  }) {
    return TrainingPlan(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      goal: goal ?? this.goal,
      goals: goals ?? this.goals,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      trainingDays: trainingDays ?? this.trainingDays,
      splitName: splitName ?? this.splitName,
      days: days ?? this.days,
      generatedAt: generatedAt ?? this.generatedAt,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}
