import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Larger type scale used only by the welcome and onboarding screens.
///
/// The app-wide tokens in [AppTypography] stay unchanged so the core tabs keep
/// their density. Onboarding screens opt in by using these styles directly or
/// by passing them to the shared widgets.
class AppOnboardingType {
  const AppOnboardingType._();

  static const TextStyle title = TextStyle(
    fontFamily: AppTypography.displayFamily,
    fontSize: 27,
    height: 30 / 27,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 15,
    height: 21 / 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle label = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle control = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle choiceTitle = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 15,
    height: 21 / 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle choiceDesc = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 12.5,
    height: 17 / 12.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 12.5,
    height: 17 / 12.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 10.5,
    height: 14 / 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static const TextStyle value = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 42,
    height: 44 / 42,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle tileLabel = TextStyle(
    fontFamily: AppTypography.bodyFamily,
    fontSize: 14,
    height: 18 / 14,
    fontWeight: FontWeight.w600,
  );
}
