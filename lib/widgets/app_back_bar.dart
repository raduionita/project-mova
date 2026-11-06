import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Compact back bar used by sub-routes from DESIGN.md section 10.10.
class AppBackBar extends StatelessWidget {
  const AppBackBar({super.key, required this.label, this.onBack});

  final String label;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.x5l + AppSpacing.x4l,
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
          ),
          Text(
            label,
            style: AppTypography.label.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
