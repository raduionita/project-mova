import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_icon.dart';

/// Centered empty state from DESIGN.md section 8.16.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon,
    this.assetIcon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : assert(icon != null || assetIcon != null);

  final IconData? icon;

  /// SVG asset alternative to [icon], used after the icon migration.
  final String? assetIcon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  Widget _buildIcon() {
    final asset = assetIcon;
    if (asset != null) {
      return AppIcon(asset: asset, size: 48, color: AppColors.muted);
    }
    return Icon(icon, size: 48, color: AppColors.muted);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight =
            constraints.hasBoundedHeight &&
                constraints.maxHeight > AppSpacing.x4l
            ? constraints.maxHeight - AppSpacing.x4l
            : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.x2l),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildIcon(),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.h2.copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.x3l),
                      AppButton(
                        label: actionLabel!,
                        onPressed: onAction,
                        variant: AppButtonVariant.ghost,
                        fullWidth: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
