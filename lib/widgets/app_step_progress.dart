import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Dotted onboarding progress indicator. The active step is a lime pill while
/// the remaining steps stay as small dots.
class AppStepProgress extends StatelessWidget {
  const AppStepProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 10,
  });

  final int currentStep;
  final int totalSteps;

  int get _activeIndex {
    if (currentStep <= 0 || totalSteps <= 0) {
      return -1;
    }
    return currentStep.clamp(1, totalSteps) - 1;
  }

  int get _labelStep => _activeIndex + 1;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $_labelStep of $totalSteps',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var index = 0; index < totalSteps; index++) ...<Widget>[
            AnimatedContainer(
              key: ValueKey<String>('step-segment-$index'),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: index == _activeIndex ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: index == _activeIndex
                    ? AppColors.lime
                    : AppColors.stepInactive,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (index != totalSteps - 1) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
