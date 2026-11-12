import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/onboarding_flow.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/mova_mark.dart';

/// Mid tone between [AppColors.text] and [AppColors.muted] for the value rows.
const Color _kValueTextColor = Color(0xFFC3CDDD);

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
    if (!advanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Could not start onboarding.'),
        ),
      );
      return;
    }
    _open(context, OnboardingFlow.firstRoute);
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
        child: MovaMark(
          height: 30,
          color: AppColors.limeInk,
          semanticLabel: 'Mova logo',
        ),
      ),
    );
  }

  Widget _buildValueRow(String asset, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Center(
              child: AppIcon(asset: asset, size: 18, color: AppColors.lime),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Text(
              label,
              style: AppOnboardingType.tileLabel.copyWith(
                color: _kValueTextColor,
              ),
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
                'A weekly plan shaped by your goals and schedule',
              ),
              _buildValueRow(
                AppIcons.clock,
                'A fast logger that remembers your last set',
              ),
              _buildValueRow(
                AppIcons.trendUp,
                'Progress you can trust, built from your own data',
              ),
              const Spacer(),
              AppButton(
                label: hasDraft ? 'Continue' : 'Get started',
                isLoading: provider.isLoading,
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
