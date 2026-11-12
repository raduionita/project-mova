import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'dashed_border.dart';

/// Dashed, faded metric card for data that does not exist yet.
///
/// The preview copy is dimmed, while the title and action stay fully readable.
class ProgressPlaceholderCard extends StatelessWidget {
  const ProgressPlaceholderCard({
    super.key,
    required this.title,
    required this.message,
    required this.iconAsset,
    this.actionLabel,
    this.actionKey,
    this.onAction,
  });

  final String title;
  final String message;
  final String iconAsset;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: AppSpacing.x4l,
                  height: AppSpacing.x4l,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: AppIcon(
                    asset: iconAsset,
                    size: 17,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Opacity(
              opacity: 0.72,
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                key: actionKey,
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  actionLabel!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.lime,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
