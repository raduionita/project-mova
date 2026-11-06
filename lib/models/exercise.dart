enum ExerciseDetailMode { browse, session, routine }

/// Exercise library entry.
class Exercise {
  const Exercise({
    this.schemaVersion = 1,
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const <String>[],
    required this.equipment,
    this.instructions = const <String>[],
    this.isCustom = false,
    this.isCompound = false,
  });

  final int schemaVersion;
  final String id;
  final String name;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final String equipment;
  final List<String> instructions;
  final bool isCustom;
  final bool isCompound;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final rawSecondary = json['secondaryMuscles'];
    final rawInstructions = json['instructions'];
    return Exercise(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      primaryMuscle: json['primaryMuscle'] as String? ?? '',
      secondaryMuscles: rawSecondary is List
          ? rawSecondary.whereType<String>().toList(growable: false)
          : const <String>[],
      equipment: json['equipment'] as String? ?? '',
      instructions: rawInstructions is List
          ? rawInstructions.whereType<String>().toList(growable: false)
          : const <String>[],
      isCustom: json['isCustom'] as bool? ?? false,
      isCompound: json['isCompound'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'name': name,
      'primaryMuscle': primaryMuscle,
      'secondaryMuscles': secondaryMuscles,
      'equipment': equipment,
      'instructions': instructions,
      'isCustom': isCustom,
      'isCompound': isCompound,
    };
  }

  Exercise copyWith({
    int? schemaVersion,
    String? id,
    String? name,
    String? primaryMuscle,
    List<String>? secondaryMuscles,
    String? equipment,
    List<String>? instructions,
    bool? isCustom,
    bool? isCompound,
  }) {
    return Exercise(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      name: name ?? this.name,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
      isCustom: isCustom ?? this.isCustom,
      isCompound: isCompound ?? this.isCompound,
    );
  }
}
