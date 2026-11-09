import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icon.dart';

/// First screen of onboarding. Starts a new draft or resumes a saved one.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.onRoute});

  /// Optional routing hook for tests and the app shell. When null, named
  /// routes are pushed on the ambient navigator.
  final ValueChanged<String>? onRoute;

  void _open(BuildContext context, String route) {
    final handler = onRoute;
    if (handler != null) {
      handler(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _start(BuildContext context, OnboardingProvider provider) async {
    if (provider.hasDraft) {
      _open(context, OnboardingFlow.resumeRoute(provider.draft));
      return;
    }
    final advanced = await provider.next();
    if (!context.mounted) {
      return;
    }
    _open(context, advanced ? OnboardingFlow.firstRoute : Routes.welcome);
  }

  Widget _buildMark() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.lime, Color(0xFF7FC93A)],
        ),
        borderRadius: BorderRadius.circular(AppRadii.x3l),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.lime.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'M',
          style: AppTypography.displayXL.copyWith(
            fontSize: 32,
            height: 1,
            color: AppColors.limeInk,
          ),
        ),
      ),
    );
  }

  Widget _buildValueRow(String asset, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.sm + 1),
            ),
            child: Center(
              child: AppIcon(asset: asset, size: 15, color: AppColors.lime),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppOnboardingType.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  detail,
                  style: AppOnboardingType.caption.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();
    final hasDraft = provider.hasDraft;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.x6l),
              Center(child: _buildMark()),
              const SizedBox(height: AppSpacing.x3l),
              Text(
                'Train with a plan',
                textAlign: TextAlign.center,
                style: AppOnboardingType.title.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'A weekly plan, a live logger, and progress you can see.',
                textAlign: TextAlign.center,
                style: AppOnboardingType.subtitle.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.x4l),
              _buildValueRow(
                AppIcons.plan,
                'A plan for your week',
                'Generated from your goals, level, and schedule.',
              ),
              _buildValueRow(
                AppIcons.clock,
                'Log every set',
                'Weights, reps, and rest tracked while you train.',
              ),
              _buildValueRow(
                AppIcons.trendUp,
                'See progress',
                'History, streaks, and personal records in one place.',
              ),
              const Spacer(),
              AppButton(
                label: hasDraft ? 'Continue' : 'Get started',
                onPressed: provider.isLoading
                    ? null
                    : () => _start(context, provider),
              ),
              const SizedBox(height: AppSpacing.x2l),
            ],
          ),
        ),
      ),
    );
  }
}
