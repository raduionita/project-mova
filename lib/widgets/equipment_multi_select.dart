import 'package:flutter/material.dart';

import '../models/equipment_group.dart';
import 'app_multi_select.dart';

/// Equipment selection list shared by onboarding and Settings.
class EquipmentMultiSelect extends StatelessWidget {
  const EquipmentMultiSelect({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final List<EquipmentGroup> selected;
  final ValueChanged<List<EquipmentGroup>> onChanged;
  final bool enabled;

  static const List<AppMultiSelectOption<EquipmentGroup>> options =
      <AppMultiSelectOption<EquipmentGroup>>[
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.bodyweight,
          label: 'Bodyweight',
          description: 'No equipment needed',
          icon: Icons.accessibility_new,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.dumbbells,
          label: 'Dumbbells',
          description: 'Fixed or adjustable dumbbells',
          icon: Icons.fitness_center,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.barbell,
          label: 'Barbell and EZ bar',
          description: 'Barbell, rack, and EZ bar',
          icon: Icons.sports_gymnastics,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.machines,
          label: 'Machines',
          description: 'Selectorized and plate-loaded machines',
          icon: Icons.precision_manufacturing_outlined,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.cables,
          label: 'Cable station',
          description: 'Pulleys and cable stacks',
          icon: Icons.cable,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.kettlebells,
          label: 'Kettlebells',
          description: 'One or more kettlebells',
          icon: Icons.sports_mma,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.accessories,
          label: 'Accessories',
          description: 'Ab wheel, medicine ball, and sled',
          icon: Icons.sports_handball,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return AppMultiSelect<EquipmentGroup>(
      options: options,
      selected: selected,
      onChanged: onChanged,
      enabled: enabled,
      showPrimaryTag: false,
    );
  }
}
