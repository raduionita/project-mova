import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// Local-only kudos toggle. The count is never a network value.
class KudosButton extends StatelessWidget {
  const KudosButton({
    super.key,
    required this.count,
    required this.given,
    this.onPressed,
  });

  final int count;
  final bool given;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = given ? AppColors.lime : AppColors.muted;
    final background = given ? AppColors.limeSoft : AppColors.surfaceAlt;
    final label = given ? 'Remove kudos' : 'Give kudos';
    return Semantics(
      button: true,
      toggled: given,
      label: '$label, $count',
      onTap: onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32, minWidth: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppIcon(
                      asset: given ? AppIcons.heartFilled : AppIcons.heart,
                      size: 14,
                      color: foreground,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '$count',
                      style: AppTypography.caption.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
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
