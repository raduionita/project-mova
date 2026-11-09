import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_onboarding_type.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_icon.dart';

/// One option in an [AppTileGrid].
class AppTileOption<T> {
  const AppTileOption({
    required this.value,
    required this.label,
    required this.assetIcon,
  });

  final T value;
  final String label;
  final String assetIcon;
}

/// Grid of icon tiles used for onboarding goals.
///
/// The first selected option is the primary one, matching the ordered
/// multi-select behaviour of [AppMultiSelect].
class AppTileGrid<T> extends StatelessWidget {
  const AppTileGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.columns = 2,
  });

  final List<AppTileOption<T>> options;
  final List<T> selected;
  final ValueChanged<List<T>> onChanged;
  final bool enabled;
  final int columns;

  void _toggle(T value) {
    final next = <T>[...selected];
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    onChanged(next);
  }

  Widget _buildTile(AppTileOption<T> option) {
    final isSelected = selected.contains(option.value);
    final isPrimary = isSelected && selected.first == option.value;
    final foreground = isSelected ? AppColors.lime : AppColors.text;
    final radius = BorderRadius.circular(AppRadii.lg);
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      label: option.label,
      child: Material(
        color: isSelected
            ? AppColors.lime.withValues(alpha: 0.08)
            : AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: isSelected ? AppColors.lime : AppColors.line),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? () => _toggle(option.value) : null,
          child: SizedBox(
            height: 108,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AppIcon(asset: option.assetIcon, size: 22, color: foreground),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    option.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppOnboardingType.tileLabel.copyWith(
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 14,
                    child: isPrimary
                        ? Text(
                            'Primary',
                            style: AppOnboardingType.micro.copyWith(
                              color: AppColors.lime,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(int row) {
    return Row(
      children: <Widget>[
        for (var column = 0; column < columns; column++) ...<Widget>[
          if (column > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: row * columns + column < options.length
                ? _buildTile(options[row * columns + column])
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = (options.length / columns).ceil();
    return Column(
      children: <Widget>[
        for (var row = 0; row < rows; row++) ...<Widget>[
          if (row > 0) const SizedBox(height: AppSpacing.md),
          _buildRow(row),
        ],
      ],
    );
  }
}
