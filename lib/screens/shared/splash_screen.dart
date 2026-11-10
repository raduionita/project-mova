import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/mova_mark.dart';

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
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.lime, AppColors.limeDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadii.x3l + AppSpacing.sm),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.lime.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: MovaMark(height: 44, color: AppColors.limeInk),
    );
  }

  Widget _buildLoadingBar() {
    return Container(
      key: const ValueKey<String>('splash-loading-bar'),
      width: 120,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.stepInactive,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.55,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.lime,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
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
                  'Move. Log. Progress.',
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
