import 'package:flutter/material.dart';

import '../../navigation/onboarding_flow.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_step_progress.dart';

/// Shared chrome for the ten onboarding steps after welcome.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.title,
    required this.currentStep,
    required this.onBack,
    required this.child,
    this.subtitle,
    this.onContinue,
    this.continueLabel = 'Continue',
    this.continueEnabled = true,
    this.isBusy = false,
    this.onSkip,
    this.skipLabel = 'Skip',
    this.totalSteps = OnboardingFlow.totalSteps,
    this.centerContent = false,
  });

  final String title;
  final String? subtitle;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final Widget child;
  final VoidCallback? onContinue;
  final String continueLabel;
  final bool continueEnabled;
  final bool isBusy;
  final VoidCallback? onSkip;
  final String skipLabel;

  /// Centers short content between the header and the actions.
  final bool centerContent;

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: onBack,
                    tooltip: 'Back',
                    icon: const AppIcon(
                      asset: AppIcons.chevronLeft,
                      size: 22,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'STEP $currentStep OF $totalSteps',
                    style: AppOnboardingType.micro.copyWith(
                      color: AppColors.tabInactive,
                    ),
                  ),
                ],
              ),
              AppStepProgress(currentStep: currentStep, totalSteps: totalSteps),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x2l),
        Text(
          title,
          style: AppOnboardingType.title.copyWith(color: AppColors.text),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle!,
            style: AppOnboardingType.subtitle.copyWith(color: AppColors.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.x3l),
      ],
    );
  }

  Widget _buildContent() {
    if (!centerContent) {
      return SingleChildScrollView(child: child);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppButton(
          label: continueLabel,
          onPressed: continueEnabled && !isBusy ? onContinue : null,
          isLoading: isBusy,
        ),
        if (onSkip != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: skipLabel,
            onPressed: isBusy ? null : onSkip,
            variant: AppButtonVariant.ghost,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),
              _buildHeader(),
              Expanded(child: _buildContent()),
              const SizedBox(height: AppSpacing.x3l),
              _buildActions(),
              const SizedBox(height: AppSpacing.x2l),
            ],
          ),
        ),
      ),
    );
  }
}
