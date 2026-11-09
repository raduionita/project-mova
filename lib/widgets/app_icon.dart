import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Tinted SVG icon from `assets/icons/` or any other registered asset.
///
/// All Mova icons share a 24x24 viewBox with a white 1.7 stroke, so a single
/// color filter recolors them for active and inactive states.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.asset,
    this.size = 20,
    this.color = AppColors.muted,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}
