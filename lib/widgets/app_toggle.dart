import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Small lime pill toggle from DESIGN.md section 8.11.
///
/// Pass a null [onChanged] for a read-only state indicator.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  Widget _buildKnob() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: value ? AppColors.lime : AppColors.muted,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Semantics(
      toggled: value,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: Container(
          width: 34,
          height: 20,
          padding: const EdgeInsets.all(2),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? AppColors.limeDisabled30 : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: _buildKnob(),
        ),
      ),
    );
  }
}
