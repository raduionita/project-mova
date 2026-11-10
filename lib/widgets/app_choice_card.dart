import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// Full-width selectable card with an optional icon and description.
class AppChoiceCard extends StatelessWidget {
  const AppChoiceCard({
    super.key,
    required this.label,
    this.description,
    this.icon,
    this.assetIcon,
    this.selected = false,
    this.onTap,
    this.trailing,
    this.labelStyle,
    this.descriptionStyle,
    this.iconSize = 17,
    this.iconBoxSize = 32,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl + AppSpacing.xxs,
      vertical: AppSpacing.xl,
    ),
  });

  final String label;
  final String? description;
  final IconData? icon;

  /// SVG asset alternative to [icon], used after the icon migration.
  final String? assetIcon;
  final bool selected;
  final VoidCallback? onTap;
  final TextStyle? labelStyle;
  final TextStyle? descriptionStyle;

  /// Glyph size inside the icon box. Defaults to the standard card size.
  final double iconSize;

  /// Side length of the tinted icon box.
  final double iconBoxSize;

  /// Padding around the label and icon.
  final EdgeInsetsGeometry contentPadding;

  /// Replaces the selected check mark, for example with a Primary tag.
  final Widget? trailing;

  Color get _background =>
      selected ? AppColors.lime.withValues(alpha: 0.08) : AppColors.card;

  Color get _border => selected ? AppColors.lime : AppColors.line;

  Widget _buildIcon() {
    final icon = this.icon;
    final asset = assetIcon;
    final color = selected ? AppColors.lime : AppColors.muted;
    return Container(
      width: iconBoxSize,
      height: iconBoxSize,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.lime.withValues(alpha: 0.16)
            : AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg - 3),
      ),
      child: asset != null
          ? Center(
              child: AppIcon(asset: asset, size: iconSize, color: color),
            )
          : Icon(icon, size: iconSize, color: color),
    );
  }

  Widget _buildTrailing() {
    if (trailing != null) {
      return trailing!;
    }
    if (!selected) {
      return const SizedBox.shrink();
    }
    return const AppIcon(
      asset: AppIcons.check,
      size: 16,
      color: AppColors.lime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.lg);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: _background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: _border),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: contentPadding,
            child: Row(
              children: <Widget>[
                if (icon != null || assetIcon != null) ...<Widget>[
                  _buildIcon(),
                  const SizedBox(width: AppSpacing.lg + 1),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: (labelStyle ?? AppTypography.bodyStrong)
                            .copyWith(color: AppColors.text),
                      ),
                      if (description != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          description!,
                          style: (descriptionStyle ?? AppTypography.caption)
                              .copyWith(color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _buildTrailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
