import 'package:flutter/material.dart';

import '../services/streak_badge_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_icons.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// Horizontal, display-only row of streak milestones.
class StreakBadgeRow extends StatelessWidget {
  const StreakBadgeRow({
    super.key,
    required this.dayStreak,
    required this.weekStreak,
    this.service = const StreakBadgeService(),
  });

  final int dayStreak;
  final int weekStreak;
  final StreakBadgeService service;

  @override
  Widget build(BuildContext context) {
    final badges = service.badges(
      dayStreak: dayStreak,
      weekStreak: weekStreak,
    );
    return Column(
      key: const Key('today-badges'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Streak badges',
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              for (var index = 0; index < badges.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                _buildBadge(badges[index]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(StreakBadge badge) {
    final isDay = badge.kind == StreakBadgeKind.day;
    final earnedColor = isDay ? AppColors.gold : AppColors.lime;
    final color = badge.earned ? earnedColor : AppColors.muted;
    return Semantics(
      label:
          '${badge.label} streak badge, '
          '${badge.earned ? 'earned' : badge.progressHint}',
      child: Opacity(
        opacity: badge.earned ? 1 : 0.45,
        child: Container(
          key: Key(
            'today-badge-${isDay ? 'day' : 'week'}-${badge.target}',
          ),
          width: 82,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: badge.earned
                ? (isDay ? AppColors.goldSoft : AppColors.limeSoft)
                : AppColors.card,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: badge.earned ? color.withValues(alpha: 0.4) : AppColors.line,
            ),
          ),
          child: Column(
            children: <Widget>[
              AppIcon(
                asset: isDay ? AppIcons.flame : AppIcons.trophy,
                size: 18,
                color: color,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                badge.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.micro.copyWith(
                  color: badge.earned ? AppColors.text : AppColors.muted,
                  fontWeight: badge.earned ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
