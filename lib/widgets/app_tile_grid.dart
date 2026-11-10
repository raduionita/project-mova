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

/// Grid of square icon tiles used for onboarding goals.
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

  /// Largest width the grid may take. Keeps the square tiles from growing
  /// without bound on tablets and wide web windows.
  static const double _maxGridWidth = 400;

  void _toggle(T value) {
    final next = <T>[...selected];
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    onChanged(next);
  }

  Widget _buildTile(AppTileOption<T> option, double size) {
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
            height: size,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  AppIcon(asset: option.assetIcon, size: 32, color: foreground),
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

  Widget _buildRow(int row, double tileSize) {
    return Row(
      children: <Widget>[
        for (var column = 0; column < columns; column++) ...<Widget>[
          if (column > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: row * columns + column < options.length
                ? _buildTile(options[row * columns + column], tileSize)
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = (options.length / columns).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > _maxGridWidth
            ? _maxGridWidth
            : constraints.maxWidth;
        final tileSize = (width - AppSpacing.md * (columns - 1)) / columns;
        return Center(
          child: SizedBox(
            width: width,
            child: Column(
              children: <Widget>[
                for (var row = 0; row < rows; row++) ...<Widget>[
                  if (row > 0) const SizedBox(height: AppSpacing.md),
                  _buildRow(row, tileSize),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
