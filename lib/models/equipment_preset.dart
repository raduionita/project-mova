import 'equipment_group.dart';

/// Ready-made equipment selections for the most common setups.
class EquipmentPreset {
  const EquipmentPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.groups,
  });

  final String id;
  final String label;
  final String description;
  final List<EquipmentGroup> groups;

  /// True when the given selection contains exactly this preset's groups.
  bool matches(List<EquipmentGroup> selected) {
    if (selected.length != groups.length) {
      return false;
    }
    return groups.every(selected.contains);
  }

  static const EquipmentPreset bodyweightOnly = EquipmentPreset(
    id: 'bodyweight-only',
    label: 'Bodyweight only',
    description: 'No equipment needed',
    groups: <EquipmentGroup>[EquipmentGroup.bodyweight],
  );

  static const EquipmentPreset home = EquipmentPreset(
    id: 'home',
    label: 'Home basics',
    description: 'Dumbbells, kettlebells, and accessories',
    groups: <EquipmentGroup>[
      EquipmentGroup.bodyweight,
      EquipmentGroup.dumbbells,
      EquipmentGroup.kettlebells,
      EquipmentGroup.accessories,
    ],
  );

  static const EquipmentPreset fullGym = EquipmentPreset(
    id: 'full-gym',
    label: 'Full gym',
    description: 'Everything, including machines and cables',
    groups: <EquipmentGroup>[
      EquipmentGroup.bodyweight,
      EquipmentGroup.dumbbells,
      EquipmentGroup.barbell,
      EquipmentGroup.machines,
      EquipmentGroup.cables,
      EquipmentGroup.kettlebells,
      EquipmentGroup.accessories,
    ],
  );

  static const List<EquipmentPreset> all = <EquipmentPreset>[
    bodyweightOnly,
    home,
    fullGym,
  ];
}
