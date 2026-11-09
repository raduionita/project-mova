import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// Compact metric tile from DESIGN.md section 8.4.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.assetIcon,
  });

  final String value;
  final String label;
  final IconData? icon;

  /// SVG asset alternative to [icon], used after the icon migration.
  final String? assetIcon;

  Widget _buildIcon() {
    final asset = assetIcon;
    if (asset != null) {
      return AppIcon(asset: asset, size: 16, color: AppColors.muted);
    }
    return Icon(icon, size: 16, color: AppColors.muted);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null || assetIcon != null) ...<Widget>[
            _buildIcon(),
            const SizedBox(height: AppSpacing.sm),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.metric.copyWith(
                color: AppColors.text,
                fontSize: 22,
                height: 24 / 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
