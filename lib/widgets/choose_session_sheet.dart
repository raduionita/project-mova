import 'package:flutter/material.dart';

import '../models/plan_day.dart';
import '../models/routine.dart';
import '../models/training_plan.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'app_tag.dart';

/// Opens the session picker used from Today.
Future<void> showChooseSessionSheet(
  BuildContext context, {
  required TrainingPlan? plan,
  required List<Routine> routines,
  required int? nextIndex,
  required ValueChanged<PlanDay> onStartPlanDay,
  required ValueChanged<Routine> onStartRoutine,
  required VoidCallback onStartEmpty,
  required VoidCallback onStartWalk,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.panel,
    builder: (_) => ChooseSessionSheet(
      plan: plan,
      routines: routines,
      nextIndex: nextIndex,
      onStartPlanDay: onStartPlanDay,
      onStartRoutine: onStartRoutine,
      onStartEmpty: onStartEmpty,
      onStartWalk: onStartWalk,
    ),
  );
}

/// Bottom sheet that lists every way to start a session.
class ChooseSessionSheet extends StatelessWidget {
  const ChooseSessionSheet({
    super.key,
    required this.plan,
    required this.routines,
    this.nextIndex,
    required this.onStartPlanDay,
    required this.onStartRoutine,
    required this.onStartEmpty,
    required this.onStartWalk,
  });

  final TrainingPlan? plan;
  final List<Routine> routines;
  final int? nextIndex;
  final ValueChanged<PlanDay> onStartPlanDay;
  final ValueChanged<Routine> onStartRoutine;
  final VoidCallback onStartEmpty;
  final VoidCallback onStartWalk;

  void _select(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.label.copyWith(color: AppColors.muted),
      ),
    );
  }

  Widget _buildRow({
    required Key key,
    required String title,
    required String subtitle,
    required String assetIcon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                AppIcon(asset: assetIcon, size: 18, color: AppColors.muted),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.bodyStrong.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSessions(BuildContext context) {
    final days = plan?.days ?? const <PlanDay>[];
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionTitle('Rotation'),
        for (var index = 0; index < days.length; index++)
          _buildRow(
            key: Key('choose-session-day-$index'),
            title: days[index].name,
            subtitle:
                '${days[index].exercises.length} exercises · '
                '~${days[index].estimatedMinutes} min',
            assetIcon: AppIcons.plan,
            onTap: () => _select(context, () => onStartPlanDay(days[index])),
            trailing: index == nextIndex
                ? const AppTag(label: 'Next', variant: AppTagVariant.lime)
                : null,
          ),
      ],
    );
  }

  Widget _buildRoutines(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionTitle('Saved workouts'),
        if (routines.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'No saved workouts yet. Build one from the planner.',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ),
        for (final routine in routines)
          _buildRow(
            key: Key('choose-session-routine-${routine.id}'),
            title: routine.name,
            subtitle: '${routine.exercises.length} exercises',
            assetIcon: AppIcons.list,
            onTap: () => _select(context, () => onStartRoutine(routine)),
          ),
      ],
    );
  }

  Widget _buildQuickStart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionTitle('Quick start'),
        _buildRow(
          key: const Key('choose-session-empty'),
          title: 'Empty workout',
          subtitle: 'Build the session as you go',
          assetIcon: AppIcons.plus,
          onTap: () => _select(context, onStartEmpty),
        ),
        _buildRow(
          key: const Key('choose-session-walk'),
          title: 'Walk',
          subtitle: 'Log time outside the gym',
          assetIcon: AppIcons.walk,
          onTap: () => _select(context, onStartWalk),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('choose-session-sheet'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2l,
            AppSpacing.xl,
            AppSpacing.x2l,
            AppSpacing.x2l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Choose another session',
                      style: AppTypography.h2.copyWith(color: AppColors.text),
                    ),
                  ),
                  IconButton(
                    key: const Key('choose-session-close'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const AppIcon(
                      asset: AppIcons.close,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildPlanSessions(context),
              const SizedBox(height: AppSpacing.md),
              _buildRoutines(context),
              const SizedBox(height: AppSpacing.md),
              _buildQuickStart(context),
            ],
          ),
        ),
      ),
    );
  }
}
