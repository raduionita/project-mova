import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_radii.dart';
import 'package:mova/theme/app_spacing.dart';
import 'package:mova/theme/app_theme.dart';

void main() {
  test('dark theme exposes lime primary and design tokens', () {
    final theme = AppTheme.dark;

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, AppColors.lime);
    expect(theme.colorScheme.onPrimary, AppColors.limeInk);
    expect(theme.colorScheme.surface, AppColors.background);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF0B0F16));
    expect(theme.textTheme.headlineLarge?.fontSize, 24);
    expect(theme.textTheme.headlineLarge?.fontFamily, 'Barlow Condensed');
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
    expect(AppSpacing.xxs, 2);
    expect(AppSpacing.x6l, 40);
    expect(AppRadii.xs, 6);
    expect(AppRadii.pill, 999);
  });
}
