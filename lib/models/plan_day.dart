import 'plan_exercise.dart';
import 'split_style.dart';

/// One session inside a rotation plan.
class PlanDay {
  const PlanDay({
    this.schemaVersion = 2,
    required this.id,
    this.weekday = 0,
    this.order = 0,
    this.slotKey = '',
    required this.name,
    required this.muscleGroups,
    required this.estimatedMinutes,
    required this.exercises,
  });

  final int schemaVersion;
  final String id;

  /// Legacy weekday binding. Kept for v1 plan migration only.
  final int weekday;

  /// Position in the rotation, starting at 0.
  final int order;

  /// Stable identity used to advance the rotation across regeneration.
  final String slotKey;
  final String name;
  final List<String> muscleGroups;
  final int estimatedMinutes;
  final List<PlanExercise> exercises;

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    final rawMuscleGroups = json['muscleGroups'];
    final rawExercises = json['exercises'];
    return PlanDay(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      weekday: (json['weekday'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
      slotKey: json['slotKey'] as String? ?? '',
      name: json['name'] as String? ?? '',
      muscleGroups: rawMuscleGroups is List
          ? rawMuscleGroups.whereType<String>().toList(growable: false)
          : const <String>[],
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      exercises: rawExercises is List
          ? rawExercises
                .whereType<Map<String, dynamic>>()
                .map(PlanExercise.fromJson)
                .toList(growable: false)
          : const <PlanExercise>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'weekday': weekday,
      'order': order,
      'slotKey': slotKey,
      'name': name,
      'muscleGroups': muscleGroups,
      'estimatedMinutes': estimatedMinutes,
      'exercises': exercises
          .map((exercise) => exercise.toJson())
          .toList(growable: false),
    };
  }

  PlanDay copyWith({
    int? schemaVersion,
    String? id,
    int? weekday,
    int? order,
    String? slotKey,
    String? name,
    List<String>? muscleGroups,
    int? estimatedMinutes,
    List<PlanExercise>? exercises,
  }) {
    return PlanDay(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      weekday: weekday ?? this.weekday,
      order: order ?? this.order,
      slotKey: slotKey ?? this.slotKey,
      name: name ?? this.name,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      exercises: exercises ?? this.exercises,
    );
  }
}

/// Returns the stable rotation slot for a session.
String planSlotKeyFor({
  required String name,
  required int order,
  required int count,
  SplitStyle splitStyle = SplitStyle.auto,
}) {
  final lower = name.toLowerCase();
  if (lower.contains('recovery')) {
    return 'recovery';
  }
  if (count <= 1) {
    return 'full';
  }

  if (splitStyle == SplitStyle.fullBody) {
    return 'full-${_slotLetter(order)}';
  }

  if (splitStyle == SplitStyle.upperLower) {
    final letter = _slotLetter(order ~/ 2);
    if (lower.contains('upper')) {
      return 'upper-$letter';
    }
    if (lower.contains('lower')) {
      return 'lower-$letter';
    }
    return 'full-${_slotLetter(order)}';
  }

  if (splitStyle == SplitStyle.ppl) {
    final base = _pplBase(lower);
    if (count == 3) {
      return base;
    }
    return '$base-${_slotLetter(order ~/ 3)}';
  }

  switch (count) {
    case 2:
      return 'full-${_slotLetter(order)}';
    case 3:
      return _pplBase(lower);
    case 4:
      final letter = _slotLetter(order ~/ 2);
      return lower.contains('lower') ? 'lower-$letter' : 'upper-$letter';
    case 5:
      return switch (order) {
        0 => 'push',
        1 => 'pull',
        2 => 'legs',
        3 => 'upper',
        _ => 'lower',
      };
    case 6:
      return '${_pplBase(lower)}-${_slotLetter(order ~/ 3)}';
    case 7:
      if (order == 6) {
        return 'recovery';
      }
      return '${_pplBase(lower)}-${_slotLetter(order ~/ 3)}';
    default:
      return 'session-${order + 1}';
  }
}

String _pplBase(String lower) {
  if (lower.contains('push')) {
    return 'push';
  }
  if (lower.contains('pull')) {
    return 'pull';
  }
  if (lower.contains('legs')) {
    return 'legs';
  }
  if (lower.contains('upper')) {
    return 'upper';
  }
  if (lower.contains('lower')) {
    return 'lower';
  }
  return 'session';
}

String _slotLetter(int index) {
  if (index >= 0 && index < 26) {
    return String.fromCharCode(97 + index);
  }
  return '${index + 1}';
}
