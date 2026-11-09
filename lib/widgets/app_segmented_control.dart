import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// One option in an [AppSegmentedControl].
class AppSegmentOption<T> {
  const AppSegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill segmented control used for unit selection.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.labelStyle,
    this.itemPadding = const EdgeInsets.symmetric(vertical: AppSpacing.md),
  });

  final List<AppSegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool enabled;

  /// Overrides the segment label style, for example on onboarding.
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry itemPadding;

  Widget _buildSegment(AppSegmentOption<T> option) {
    final isSelected = option.value == selected;
    final foreground = !enabled
        ? AppColors.textDisabled
        : isSelected
        ? AppColors.lime
        : AppColors.muted;
    final background = isSelected ? AppColors.limeSoft : Colors.transparent;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        enabled: enabled,
        label: option.label,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            onTap: enabled ? () => onChanged(option.value) : null,
            child: Padding(
              padding: itemPadding,
              child: Text(
                option.label,
                textAlign: TextAlign.center,
                style: (labelStyle ?? AppTypography.label).copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < options.length; index++)
            if (index == 0)
              _buildSegment(options[index])
            else ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              _buildSegment(options[index]),
            ],
        ],
      ),
    );
  }
}
