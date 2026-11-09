import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Seven-day selector from DESIGN.md section 8.6.
///
/// Days use ISO weekday numbers: 1 is Monday and 7 is Sunday.
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.selectedDays,
    this.onChanged,
    this.enabled = true,
    this.textStyle,
  });

  static const List<String> _labels = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  static const List<String> _names = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<int> selectedDays;
  final ValueChanged<List<int>>? onChanged;
  final bool enabled;
  final TextStyle? textStyle;

  bool _isSelected(int day) => selectedDays.contains(day);

  void _toggle(int day) {
    if (!enabled || onChanged == null) {
      return;
    }
    final next = <int>[...selectedDays];
    if (next.contains(day)) {
      next.remove(day);
    } else {
      next.add(day);
    }
    next.sort();
    onChanged!(next);
  }

  Widget _buildDay(int day) {
    final selected = _isSelected(day);
    final background = selected ? AppColors.limeSoft : AppColors.dayCell;
    final foreground = !enabled
        ? AppColors.textDisabled
        : selected
        ? AppColors.lime
        : AppColors.text;
    final border = !enabled
        ? BorderSide.none
        : BorderSide(color: selected ? AppColors.limeBorder45 : AppColors.line);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: _names[day - 1],
        child: ExcludeSemantics(
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.dayCell),
              side: border,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.dayCell),
              onTap: enabled && onChanged != null ? () => _toggle(day) : null,
              child: SizedBox(
                height: 38,
                child: Center(
                  child: Text(
                    _labels[day - 1],
                    style: (textStyle ?? AppTypography.micro).copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var day = 1; day <= 7; day++) ...<Widget>[
          _buildDay(day),
          if (day < 7) const SizedBox(width: AppSpacing.dayGap),
        ],
      ],
    );
  }
}
