import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// One tappable row in the Me and Settings lists.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    this.icon,
    this.assetIcon,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.isDestructive = false,
    this.semanticLabel,
  });

  final IconData? icon;

  /// SVG asset alternative to [icon], used after the icon migration.
  final String? assetIcon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final bool isDestructive;
  final String? semanticLabel;

  Widget _buildIcon() {
    final iconColor = isDestructive ? AppColors.orange : AppColors.muted;
    final asset = assetIcon;
    if (asset != null) {
      return AppIcon(asset: asset, size: 20, color: iconColor);
    }
    return Icon(icon, size: 20, color: iconColor);
  }

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.orange : AppColors.text;
    final details = value == null || value!.isEmpty ? label : '$label, $value';
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: semanticLabel ?? details,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    _buildIcon(),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            label,
                            style: AppTypography.bodyStrong.copyWith(
                              color: color,
                            ),
                          ),
                          if (value != null && value!.isNotEmpty) ...<Widget>[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              value!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ?trailing,
                    if (trailing == null && showChevron && onTap != null)
                      const AppIcon(
                        asset: AppIcons.chevronRight,
                        size: 20,
                        color: AppColors.textDisabled,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
