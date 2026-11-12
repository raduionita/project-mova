import 'dart:async';

import 'package:flutter/material.dart';

import '../common/formatters.dart';
import '../models/unit_preferences.dart';
import '../models/workout_session.dart';
import '../services/clock.dart';
import '../services/workout_calculator.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// Live duration, volume, and set totals for an active workout.
class SessionStatsBar extends StatefulWidget {
  const SessionStatsBar({
    super.key,
    required this.session,
    this.weightUnit = WeightUnit.kg,
    this.clock,
  });

  final WorkoutSession session;
  final WeightUnit weightUnit;
  final Clock? clock;

  @override
  State<SessionStatsBar> createState() => _SessionStatsBarState();
}

class _SessionStatsBarState extends State<SessionStatsBar> {
  late final Clock _clock = widget.clock ?? const SystemClock();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Widget _buildStat(String asset, String label, String value, Key key) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.micro.copyWith(color: AppColors.tabInactive),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              AppIcon(asset: asset, size: 15, color: AppColors.muted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    key: key,
                    maxLines: 1,
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      color: AppColors.line,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.session.exercises;
    return Container(
      key: const Key('logger-stats-bar'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x2l,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: <Widget>[
          _buildStat(
            AppIcons.clock,
            'Duration',
            formatDuration(
              WorkoutCalculator.sessionDurationSeconds(
                widget.session,
                _clock.now(),
              ),
            ),
            const Key('logger-stat-duration'),
          ),
          _buildDivider(),
          _buildStat(
            AppIcons.scale,
            'Volume',
            formatVolume(
              WorkoutCalculator.volumeKg(exercises),
              unit: widget.weightUnit,
            ),
            const Key('logger-stat-volume'),
          ),
          _buildDivider(),
          _buildStat(
            AppIcons.check,
            'Sets',
            '${WorkoutCalculator.completedSetCount(exercises)} / '
                '${WorkoutCalculator.workingSetCount(exercises)}',
            const Key('logger-stat-sets'),
          ),
        ],
      ),
    );
  }
}
