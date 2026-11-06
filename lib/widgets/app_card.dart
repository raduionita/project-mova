import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// Standard and featured card surfaces from DESIGN.md section 8.2.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.featured = false,
    this.padding = const EdgeInsets.all(AppSpacing.xl + AppSpacing.xxs),
    this.onTap,
  });

  final Widget child;
  final bool featured;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(featured ? AppRadii.x2l : AppRadii.xl);
    final content = Padding(padding: padding, child: child);
    return Material(
      color: featured ? AppColors.cardElevated : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: featured ? AppColors.featuredBorder : AppColors.line,
        ),
      ),
      child: onTap == null
          ? content
          : InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}
