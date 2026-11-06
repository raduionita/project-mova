import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Full-width selectable card with an optional icon and description.
class AppChoiceCard extends StatelessWidget {
  const AppChoiceCard({
    super.key,
    required this.label,
    this.description,
    this.icon,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String? description;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  /// Replaces the selected check mark, for example with a Primary tag.
  final Widget? trailing;

  Color get _background =>
      selected ? AppColors.lime.withValues(alpha: 0.08) : AppColors.card;

  Color get _border => selected ? AppColors.lime : AppColors.line;

  Widget _buildIcon() {
    final icon = this.icon;
    if (icon == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.lime.withValues(alpha: 0.16)
            : AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg - 3),
      ),
      child: Icon(
        icon,
        size: 17,
        color: selected ? AppColors.lime : AppColors.muted,
      ),
    );
  }

  Widget _buildTrailing() {
    if (trailing != null) {
      return trailing!;
    }
    if (!selected) {
      return const SizedBox.shrink();
    }
    return const Icon(Icons.check, size: 16, color: AppColors.lime);
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl + AppSpacing.xxs,
              vertical: AppSpacing.xl,
            ),
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  _buildIcon(),
                  const SizedBox(width: AppSpacing.lg + 1),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: AppTypography.bodyStrong.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      if (description != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          description!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.muted,
                          ),
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
