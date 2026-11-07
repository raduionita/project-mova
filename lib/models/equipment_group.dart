/// User-facing equipment groups that map onto exercise library values.
enum EquipmentGroup {
  bodyweight(
    label: 'Bodyweight',
    description: 'No equipment needed',
    equipment: <String>['Bodyweight'],
  ),
  dumbbells(
    label: 'Dumbbells',
    description: 'Fixed or adjustable dumbbells',
    equipment: <String>['Dumbbell'],
  ),
  barbell(
    label: 'Barbell and EZ bar',
    description: 'Barbell, rack, and EZ bar',
    equipment: <String>['Barbell', 'EZ Bar'],
  ),
  machines(
    label: 'Machines',
    description: 'Selectorized and plate-loaded machines',
    equipment: <String>['Machine'],
  ),
  cables(
    label: 'Cable station',
    description: 'Pulleys and cable stacks',
    equipment: <String>['Cable'],
  ),
  kettlebells(
    label: 'Kettlebells',
    description: 'One or more kettlebells',
    equipment: <String>['Kettlebell'],
  ),
  accessories(
    label: 'Accessories',
    description: 'Ab wheel, medicine ball, and sled',
    equipment: <String>['Ab Wheel', 'Medicine Ball', 'Sled'],
  );

  const EquipmentGroup({
    required this.label,
    required this.description,
    required this.equipment,
  });

  final String label;
  final String description;
  final List<String> equipment;

  /// Every group, used as the backward-compatible default.
  static List<EquipmentGroup> get all =>
      List<EquipmentGroup>.unmodifiable(values);

  /// Reads stored names. Unknown names are ignored. Missing or empty data
  /// means legacy storage, so every group is available.
  static List<EquipmentGroup> fromJson(Object? value) {
    if (value is! List) {
      return all;
    }
    final groups = <EquipmentGroup>[];
    for (final item in value) {
      final match = values.where((group) => group.name == item).firstOrNull;
      if (match != null && !groups.contains(match)) {
        groups.add(match);
      }
    }
    return groups.isEmpty ? all : List<EquipmentGroup>.unmodifiable(groups);
  }

  static List<String> toJson(List<EquipmentGroup> groups) {
    return List<String>.unmodifiable(groups.map((group) => group.name));
  }

  /// Expands groups into exercise library equipment values.
  static Set<String> expand(Iterable<EquipmentGroup> groups) {
    final values = <String>{};
    for (final group in groups) {
      values.addAll(group.equipment);
    }
    return Set<String>.unmodifiable(values);
  }
}
