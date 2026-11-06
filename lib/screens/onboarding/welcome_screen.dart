import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';

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

  Widget _buildValueRow(IconData icon, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.lime),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  detail,
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
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
                'Mova',
                textAlign: TextAlign.center,
                style: AppTypography.displayXL.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Train with a plan',
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.x2l),
              Text(
                'A weekly plan, a live logger, and progress you can see.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.x4l),
              _buildValueRow(
                Icons.calendar_month_outlined,
                'A plan for your week',
                'Generated from your goals, level, and schedule.',
              ),
              _buildValueRow(
                Icons.play_circle_outline,
                'Log every set',
                'Weights, reps, and rest tracked while you train.',
              ),
              _buildValueRow(
                Icons.insights_outlined,
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
