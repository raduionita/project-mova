import 'package:flutter/material.dart';

import '../models/routine.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// Saved routine summary row from DESIGN.md section 10.9.
class RoutineRow extends StatelessWidget {
  const RoutineRow({super.key, required this.routine, this.onTap});

  final Routine routine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final count = routine.exercises.length;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl + AppSpacing.xxs,
        vertical: AppSpacing.xl,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  routine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  count == 1 ? '1 exercise' : '$count exercises',
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
        ],
      ),
    );
  }
}
