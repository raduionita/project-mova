import 'package:flutter/material.dart';

import '../models/equipment_group.dart';
import '../models/equipment_preset.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_chip.dart';

/// One-tap equipment presets shown above the full equipment list.
class EquipmentPresetBar extends StatelessWidget {
  const EquipmentPresetBar({
    super.key,
    required this.selected,
    required this.onApply,
    this.enabled = true,
  });

  final List<EquipmentGroup> selected;
  final ValueChanged<EquipmentPreset> onApply;
  final bool enabled;

  List<Widget> _buildChips() {
    return <Widget>[
      for (
        var index = 0;
        index < EquipmentPreset.all.length;
        index++
      ) ...<Widget>[
        if (index > 0) const SizedBox(width: AppSpacing.sm),
        AppChip(
          key: Key('equipment-preset-${EquipmentPreset.all[index].id}'),
          label: EquipmentPreset.all[index].label,
          selected: EquipmentPreset.all[index].matches(selected),
          onTap: enabled ? () => onApply(EquipmentPreset.all[index]) : null,
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Quick start',
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _buildChips()),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tap a preset, then fine-tune the list below.',
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
