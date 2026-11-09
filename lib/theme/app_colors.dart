import 'package:flutter/material.dart';

/// Core palette and semantic aliases from DESIGN.md section 3.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFF0B0F16);
  static const Color panel = Color(0xFF101623);
  static const Color card = Color(0xFF171F2E);
  static const Color line = Color(0xFF232D40);
  static const Color text = Color(0xFFE9EEF6);
  static const Color muted = Color(0xFF8D97AB);
  static const Color lime = Color(0xFFB7F24C);
  static const Color limeDeep = Color(0xFF7FC93A);
  static const Color limeInk = Color(0xFF131A04);
  static const Color orange = Color(0xFFFF8A4C);
  static const Color gold = Color(0xFFFFD166);
  static const Color blue = Color(0xFF5EA2FF);
  static const Color surfaceAlt = Color(0xFF20293C);

  static const Color backgroundElevated = Color(0xFF131B2B);
  static const Color cardElevated = Color(0xFF1C2740);
  static const Color limeSoft = Color(0x26B7F24C);
  static const Color goldSoft = Color(0x1FFFD166);
  static const Color blueSoft = Color(0xFF13223D);
  static const Color scrim = Color(0xB805070C);

  static const Color textDisabled = Color(0xFF5D6880);
  static const Color tabInactive = Color(0xFF66718A);
  static const Color featuredBorder = Color(0xFF2B3A58);
  static const Color dayCell = Color(0xFF182134);
  static const Color stepInactive = Color(0xFF2C374D);
  static const Color quickBorder = Color(0xFF33405C);
  static const Color pressedSurface = Color(0xFF2A3548);
  static const Color previousText = Color(0xFF67748E);
  static const Color restBorder = Color(0xFF28406B);
  static const Color restTrack = Color(0xFF1D3155);
  static const Color ringTrack = Color(0xFF223049);
  static const Color ringInner = Color(0xFF111827);
  static const Color volumeEmpty = Color(0xFF263044);
  static const Color volumeFillEnd = Color(0xFF5D8A2C);

  static Color limeBorder45 = lime.withValues(alpha: 0.45);
  static Color orangeBorder50 = orange.withValues(alpha: 0.5);
  static Color line60 = line.withValues(alpha: 0.6);
  static Color limeDisabled30 = lime.withValues(alpha: 0.3);
  static Color limeInkDisabled50 = limeInk.withValues(alpha: 0.5);
}
