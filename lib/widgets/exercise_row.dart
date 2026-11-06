import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Exercise library row from DESIGN.md section 10.9.
///
/// Shows the exercise name, its primary muscle and equipment, and an add
/// affordance. The row itself opens details when [onTap] is provided.
class ExerciseRow extends StatelessWidget {
  const ExerciseRow({
    super.key,
    required this.exercise,
    this.onTap,
    this.onAdd,
  });

  final Exercise exercise;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  Widget _buildAddButton() {
    return Semantics(
      button: true,
      enabled: onAdd != null,
      label: 'Add ${exercise.name} to workout',
      child: Tooltip(
        message: 'Add ${exercise.name}',
        child: InkResponse(
          onTap: onAdd,
          radius: AppSpacing.x4l,
          child: Container(
            width: AppSpacing.x5l,
            height: AppSpacing.x5l,
            decoration: BoxDecoration(
              color: AppColors.limeSoft,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(Icons.add, size: 18, color: AppColors.lime),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.xl);
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${exercise.primaryMuscle} · ${exercise.equipment}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _buildAddButton(),
            ],
          ),
        ),
      ),
    );
  }
}
