import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// One tappable row in the Me and Settings lists.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.isDestructive = false,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final bool isDestructive;
  final String? semanticLabel;

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
                    Icon(
                      icon,
                      size: 20,
                      color: isDestructive ? AppColors.orange : AppColors.muted,
                    ),
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
                      const Icon(
                        Icons.chevron_right,
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
