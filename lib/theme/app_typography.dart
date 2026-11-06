import 'package:flutter/material.dart';

/// Named text styles and the assembled TextTheme from DESIGN.md section 4.
class AppTypography {
  const AppTypography._();

  static const String displayFamily = 'Barlow Condensed';
  static const String bodyFamily = 'Inter';

  static const TextStyle displayXL = TextStyle(
    fontFamily: displayFamily,
    fontSize: 34,
    height: 36 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 30,
    height: 32 / 30,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: displayFamily,
    fontSize: 24,
    height: 28 / 24,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: displayFamily,
    fontSize: 19,
    height: 24 / 19,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.1,
  );

  static const TextStyle title = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle label = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 11,
    height: 15 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 9.5,
    height: 12 / 9.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static const TextStyle timer = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 32,
    height: 34 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextStyle metric = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 26,
    height: 28 / 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: displayXL,
    displayMedium: display,
    headlineLarge: h1,
    headlineMedium: h2,
    titleLarge: title,
    titleMedium: title,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: label,
    labelMedium: label,
    labelSmall: micro,
  );
}
