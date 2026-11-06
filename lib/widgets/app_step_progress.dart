import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ten-segment onboarding progress indicator. The current step and every
/// earlier step are filled with lime.
class AppStepProgress extends StatelessWidget {
  const AppStepProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 10,
  });

  final int currentStep;
  final int totalSteps;

  int get _filledSteps => currentStep.clamp(0, totalSteps);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $_filledSteps of $totalSteps',
      child: Row(
        children: <Widget>[
          for (var index = 0; index < totalSteps; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == totalSteps - 1 ? 0 : 4,
                ),
                child: Container(
                  key: ValueKey<String>('step-segment-$index'),
                  height: 4,
                  decoration: BoxDecoration(
                    color: index < _filledSteps
                        ? AppColors.lime
                        : AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
