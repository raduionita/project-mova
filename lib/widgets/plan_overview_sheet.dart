import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plan_day.dart';
import '../providers/plan_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_chip.dart';

const List<String> _weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _weekdayShort = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Week overview with day moves and a safe plan regeneration.
class PlanOverviewSheet extends StatefulWidget {
  const PlanOverviewSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.panel,
      builder: (_) => const PlanOverviewSheet(),
    );
  }

  @override
  State<PlanOverviewSheet> createState() => _PlanOverviewSheetState();
}

class _PlanOverviewSheetState extends State<PlanOverviewSheet> {
  int? _fromWeekday;
  int? _toWeekday;
  bool _isWorking = false;
  String? _error;
  String? _notice;

  Future<void> _moveDay() async {
    final from = _fromWeekday;
    final to = _toWeekday;
    if (from == null || to == null) {
      setState(() => _error = 'Pick a training day and a new weekday.');
      return;
    }
    if (from == to) {
      setState(() => _error = 'Pick a different weekday.');
      return;
    }
    setState(() {
      _isWorking = true;
      _error = null;
      _notice = null;
    });
    final plan = context.read<PlanProvider>();
    final moved = await plan.movePlanDay(fromWeekday: from, toWeekday: to);
    if (!mounted) {
      return;
    }
    setState(() {
      _isWorking = false;
      if (moved) {
        _notice =
            '${_weekdayNames[from - 1]} moved to ${_weekdayNames[to - 1]}.';
        _fromWeekday = null;
        _toWeekday = null;
      } else {
        _error = plan.error ?? 'Could not move that day.';
      }
    });
  }

  Future<void> _confirmRegenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.x2l),
          ),
          title: Text(
            'Regenerate plan?',
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
          content: Text(
            'Your workout history, personal records, and streak stay intact. '
            'The weekly split is rebuilt from your goals and schedule.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: AppTypography.label.copyWith(color: AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Regenerate',
                style: AppTypography.label.copyWith(color: AppColors.lime),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final planProvider = context.read<PlanProvider>();
    final plan = planProvider.plan;
    if (plan == null) {
      setState(() => _error = 'No plan to regenerate.');
      return;
    }
    setState(() {
      _isWorking = true;
      _error = null;
      _notice = null;
    });
    final profile = context.read<ProfileProvider>().profile;
    final regenerated = await planProvider.updateSchedule(
      daysPerWeek: plan.daysPerWeek,
      trainingDays: plan.trainingDays,
      availableEquipment:
          profile?.availableEquipment ?? plan.availableEquipment,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isWorking = false;
      if (regenerated) {
        final warning = planProvider.lastWarning;
        _notice = warning == null || warning.isEmpty
            ? 'Plan regenerated with your current equipment. History and PRs '
                  'are unchanged.'
            : 'Plan regenerated. $warning History and PRs are unchanged.';
      } else {
        _error = planProvider.error ?? 'Could not regenerate the plan.';
      }
    });
  }

  Widget _buildWeek(List<PlanDay> days) {
    return Column(
      children: <Widget>[
        for (var weekday = 1; weekday <= 7; weekday++) ...<Widget>[
          if (weekday > 1)
            const Divider(height: AppSpacing.x2l, color: AppColors.line),
          _buildWeekdayRow(weekday, days),
        ],
      ],
    );
  }

  Widget _buildWeekdayRow(int weekday, List<PlanDay> days) {
    final day = days.where((item) => item.weekday == weekday).firstOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(
              _weekdayShort[weekday - 1],
              style: AppTypography.label.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              day?.name ?? 'Rest',
              style: AppTypography.bodyStrong.copyWith(
                color: day == null ? AppColors.muted : AppColors.text,
              ),
            ),
          ),
          Text(
            day == null ? 'Recovery' : '${day.exercises.length} exercises',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveControls(List<PlanDay> days) {
    final trainingDays = days.map((day) => day.weekday).toList(growable: false)
      ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Move a training day',
          style: AppTypography.title.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pick a training day, then its new weekday. Moving onto another '
          'training day swaps the two days.',
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Training day',
          style: AppTypography.micro.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final weekday in trainingDays)
              AppChip(
                key: Key('plan-from-$weekday'),
                label: _weekdayShort[weekday - 1],
                selected: _fromWeekday == weekday,
                onTap: () => setState(() {
                  _fromWeekday = weekday;
                  _error = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'New weekday',
          style: AppTypography.micro.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (var weekday = 1; weekday <= 7; weekday++)
              AppChip(
                key: Key('plan-to-$weekday'),
                label: _weekdayShort[weekday - 1],
                selected: _toWeekday == weekday,
                onTap: () => setState(() {
                  _toWeekday = weekday;
                  _error = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x2l),
        AppButton(
          key: const Key('plan-move-submit'),
          label: 'Move day',
          isLoading: _isWorking,
          onPressed: _isWorking ? null : _moveDay,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();
    final plan = provider.plan;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3l,
          AppSpacing.x2l,
          AppSpacing.x3l,
          AppSpacing.x3l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: AppSpacing.x6l,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x2l),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Plan',
                    style: AppTypography.h2.copyWith(color: AppColors.text),
                  ),
                ),
                IconButton(
                  tooltip: 'Close plan',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.muted),
                ),
              ],
            ),
            if (plan == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4l),
                child: Text(
                  'No plan yet. Finish onboarding to build one.',
                  style: AppTypography.body.copyWith(color: AppColors.muted),
                ),
              )
            else ...<Widget>[
              Text(
                plan.splitName,
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${plan.daysPerWeek} training days this week',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.x2l),
              _buildWeek(plan.days),
              const SizedBox(height: AppSpacing.x3l),
              _buildMoveControls(plan.days),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _error!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.orange,
                  ),
                ),
              ],
              if (_notice != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _notice!,
                  style: AppTypography.caption.copyWith(color: AppColors.lime),
                ),
              ],
              const SizedBox(height: AppSpacing.x3l),
              AppButton(
                key: const Key('plan-regenerate'),
                label: 'Regenerate plan',
                variant: AppButtonVariant.ghost,
                isLoading: _isWorking,
                onPressed: _isWorking ? null : _confirmRegenerate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
