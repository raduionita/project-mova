import 'package:flutter/material.dart';

import '../models/equipment_group.dart';
import '../theme/app_icons.dart';
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
          assetIcon: AppIcons.bodyweight,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.dumbbells,
          label: 'Dumbbells',
          description: 'Fixed or adjustable dumbbells',
          assetIcon: AppIcons.dumbbell,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.barbell,
          label: 'Barbell and EZ bar',
          description: 'Barbell, rack, and EZ bar',
          assetIcon: AppIcons.barbell,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.machines,
          label: 'Machines',
          description: 'Selectorized and plate-loaded machines',
          assetIcon: AppIcons.machine,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.cables,
          label: 'Cable station',
          description: 'Pulleys and cable stacks',
          assetIcon: AppIcons.cable,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.kettlebells,
          label: 'Kettlebells',
          description: 'One or more kettlebells',
          assetIcon: AppIcons.kettlebell,
        ),
        AppMultiSelectOption<EquipmentGroup>(
          value: EquipmentGroup.accessories,
          label: 'Accessories',
          description: 'Ab wheel, medicine ball, and sled',
          assetIcon: AppIcons.accessory,
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
