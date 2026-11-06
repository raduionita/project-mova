import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Cold-start brand screen shown while local state loads.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  String get _platformLabel {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.fuchsia:
        return 'Fuchsia';
    }
  }

  Widget _buildMark() {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.x3l + AppRadii.xs),
        border: Border.all(color: AppColors.lime, width: 2),
      ),
      child: const Icon(Icons.fitness_center, size: 40, color: AppColors.lime),
    );
  }

  Widget _buildLoadingBar() {
    return Container(
      key: const ValueKey<String>('splash-loading-bar'),
      width: 120,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Semantics(
          container: true,
          label: 'Mova is starting',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Spacer(),
                _buildMark(),
                const SizedBox(height: AppSpacing.x2l),
                Text(
                  'mova',
                  style: AppTypography.displayXL.copyWith(
                    color: AppColors.text,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Train with a plan.',
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.x4l),
                _buildLoadingBar(),
                const Spacer(),
                Text(
                  '$_platformLabel · Mova 1.0',
                  style: AppTypography.micro.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.x2l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
