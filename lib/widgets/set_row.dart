import 'package:flutter/material.dart';

import '../models/unit_preferences.dart';
import '../models/workout_set.dart';
import '../services/unit_conversion_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// One row in the live logger set table from DESIGN.md section 8.8.
class SetRow extends StatelessWidget {
  const SetRow({
    super.key,
    required this.set,
    this.previous,
    required this.unitLabel,
    this.weightUnit = WeightUnit.kg,
    this.active = false,
    this.onEdit,
    this.onEditWeight,
    this.onEditReps,
    this.onToggleComplete,
    this.onToggleWarmup,
    this.onRemove,
  });

  final WorkoutSet set;
  final WorkoutSet? previous;
  final String unitLabel;
  final WeightUnit weightUnit;
  final bool active;
  final VoidCallback? onEdit;
  final VoidCallback? onEditWeight;
  final VoidCallback? onEditReps;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onToggleWarmup;
  final VoidCallback? onRemove;

  String _formatValue(double weightKg, int reps) {
    if (weightKg <= 0) {
      return '- × $reps';
    }
    final displayWeight = weightUnit == WeightUnit.kg
        ? weightKg
        : const UnitConversionService().kgToLb(weightKg);
    final fixed = displayWeight.toStringAsFixed(1);
    final weight = fixed.endsWith('.0')
        ? fixed.substring(0, fixed.length - 2)
        : fixed;
    return '$weight × $reps';
  }

  String get _semanticsLabel {
    final number = set.index + 1;
    final previousLabel = previous == null
        ? 'no previous set'
        : 'previous ${_formatValue(previous!.weightKg, previous!.reps)} '
              '$unitLabel';
    final currentLabel = 'current ${_formatValue(set.weightKg, set.reps)}';
    final states = <String>[
      if (set.isWarmup) 'warm-up',
      if (set.completed) 'completed',
    ];
    return 'Set $number, $previousLabel, $currentLabel'
        '${states.isEmpty ? '' : ', ${states.join(', ')}'}';
  }

  Widget _buildSetNumber() {
    final color = set.isWarmup ? AppColors.lime : AppColors.muted;
    return Tooltip(
      message: 'Toggle warm-up for set ${set.index + 1}',
      child: Semantics(
        button: onToggleWarmup != null,
        label: set.isWarmup
            ? 'Warm-up set ${set.index + 1}'
            : 'Set ${set.index + 1}',
        child: InkResponse(
          onTap: onToggleWarmup,
          radius: AppSpacing.x2l,
          child: Container(
            width: AppSpacing.x5l - AppSpacing.xs,
            height: AppSpacing.x5l - AppSpacing.xs,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: set.isWarmup ? AppColors.limeSoft : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(
                color: set.isWarmup ? AppColors.limeBorder45 : AppColors.line,
              ),
            ),
            child: Text(
              '${set.index + 1}',
              style: AppTypography.label.copyWith(color: color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrevious() {
    final text = previous == null
        ? '-'
        : _formatValue(previous!.weightKg, previous!.reps);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: AppColors.previousText,
        decoration: TextDecoration.lineThrough,
      ),
    );
  }

  Widget _buildValueTap({
    required String text,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: AppSpacing.x2l,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyStrong.copyWith(
              color: set.completed ? AppColors.text : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrent() {
    final displayWeight = weightUnit == WeightUnit.kg
        ? set.weightKg
        : const UnitConversionService().kgToLb(set.weightKg);
    final weightFixed = displayWeight.toStringAsFixed(1);
    final weight = set.weightKg <= 0
        ? '-'
        : weightFixed.endsWith('.0')
        ? weightFixed.substring(0, weightFixed.length - 2)
        : weightFixed;
    final weightTap = onEditWeight ?? onEdit;
    final repsTap = onEditReps ?? onEdit;
    final usesSharedEdit = onEditWeight == null && onEditReps == null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: _buildValueTap(
            text: weight,
            tooltip: usesSharedEdit
                ? 'Edit set ${set.index + 1}'
                : 'Edit weight for set ${set.index + 1}',
            onTap: weightTap,
          ),
        ),
        Text(
          ' × ',
          style: AppTypography.bodyStrong.copyWith(
            color: set.completed ? AppColors.text : AppColors.textDisabled,
          ),
        ),
        Flexible(
          child: _buildValueTap(
            text: '${set.reps}',
            tooltip: 'Edit reps for set ${set.index + 1}',
            onTap: repsTap,
          ),
        ),
      ],
    );
  }

  Widget _buildCheck() {
    return IconButton(
      tooltip: set.completed
          ? 'Mark set ${set.index + 1} incomplete'
          : 'Complete set ${set.index + 1}',
      onPressed: onToggleComplete,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: AppSpacing.x5l - AppSpacing.xs,
        height: AppSpacing.x5l - AppSpacing.xs,
      ),
      icon: AppIcon(
        asset: set.completed ? AppIcons.check : AppIcons.circle,
        size: AppSpacing.x2l + AppSpacing.xs,
        color: set.completed ? AppColors.lime : AppColors.muted,
      ),
    );
  }

  Widget _buildRemove() {
    return IconButton(
      tooltip: 'Remove set ${set.index + 1}',
      onPressed: onRemove,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(
        width: AppSpacing.x4l,
        height: AppSpacing.x5l - AppSpacing.xs,
      ),
      icon: const AppIcon(
        asset: AppIcons.close,
        size: AppSpacing.x2l,
        color: AppColors.textDisabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: _semanticsLabel,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: active
                ? AppColors.blue.withValues(alpha: 0.6)
                : AppColors.line,
          ),
        ),
        child: Row(
          children: <Widget>[
            _buildSetNumber(),
            const SizedBox(width: AppSpacing.md),
            Expanded(flex: 3, child: _buildPrevious()),
            const SizedBox(width: AppSpacing.sm),
            Expanded(flex: 3, child: _buildCurrent()),
            const SizedBox(width: AppSpacing.xs),
            _buildCheck(),
            _buildRemove(),
          ],
        ),
      ),
    );
  }
}
