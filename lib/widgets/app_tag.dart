import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppTagVariant { neutral, lime, gold }

/// Small status tag from DESIGN.md section 8.3.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.variant = AppTagVariant.neutral,
  });

  final String label;
  final AppTagVariant variant;

  Color get _background {
    switch (variant) {
      case AppTagVariant.neutral:
        return AppColors.surfaceAlt;
      case AppTagVariant.lime:
        return AppColors.limeSoft;
      case AppTagVariant.gold:
        return AppColors.goldSoft;
    }
  }

  Color get _foreground {
    switch (variant) {
      case AppTagVariant.neutral:
        return AppColors.muted;
      case AppTagVariant.lime:
        return AppColors.lime;
      case AppTagVariant.gold:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.tagVertical,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.micro.copyWith(color: _foreground),
      ),
    );
  }
}
