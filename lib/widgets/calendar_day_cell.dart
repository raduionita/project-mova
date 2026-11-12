import 'package:flutter/material.dart';

import '../common/date_keys.dart';
import '../models/workout_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';
import 'dashed_circle.dart';

/// One day in the Calendar month grid.
///
/// Logged sessions show a source icon, today gets an accent ring and label,
/// and suggested future sessions use a dashed circle.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.date,
    required this.sessions,
    this.isToday = false,
    this.isSuggested = false,
    this.suggestedName,
    this.onTap,
  });

  final DateTime date;
  final List<WorkoutSession> sessions;
  final bool isToday;
  final bool isSuggested;
  final String? suggestedName;
  final VoidCallback? onTap;

  String get _semanticsLabel {
    final parts = <String>['${date.month}/${date.day}'];
    if (isToday) {
      parts.add('Today');
    }
    if (sessions.isNotEmpty) {
      parts.add(
        sessions.length == 1 ? '1 workout' : '${sessions.length} workouts',
      );
    } else if (isSuggested) {
      parts.add('Suggested ${suggestedName ?? 'session'}');
    } else {
      parts.add('Rest day');
    }
    return parts.join(', ');
  }

  Widget _buildMarkers() {
    if (sessions.isNotEmpty) {
      final visible = sessions.take(2).toList(growable: false);
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final session in visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: AppIcon(
                asset: _iconFor(session.source),
                size: 9,
                color: _colorFor(session.source),
              ),
            ),
          if (sessions.length > 2)
            Text(
              '+${sessions.length - 2}',
              style: AppTypography.micro.copyWith(
                fontSize: 8,
                color: AppColors.muted,
              ),
            ),
        ],
      );
    }
    if (isSuggested) {
      return const AppIcon(
        asset: AppIcons.plan,
        size: 9,
        color: AppColors.lime,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final dateColor = isToday ? AppColors.lime : AppColors.text;
    final circle = Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isToday ? AppColors.limeSoft : null,
        border: isToday
            ? Border.all(color: AppColors.lime, width: 1.4)
            : null,
      ),
      child: Text(
        '${date.day}',
        style: AppTypography.label.copyWith(
          color: dateColor,
          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: _semanticsLabel,
      child: InkResponse(
        key: Key('calendar-day-${DateKeys.dayKey(date)}'),
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  if (isSuggested)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: DashedCirclePainter(
                          color: AppColors.lime.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  circle,
                  if (isToday && sessions.isNotEmpty)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        key: const Key('calendar-today-check'),
                        width: 13,
                        height: 13,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                        ),
                        child: const AppIcon(
                          asset: AppIcons.check,
                          size: 8,
                          color: AppColors.limeInk,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              SizedBox(height: 12, child: Center(child: _buildMarkers())),
              if (isToday)
                Text(
                  'Today',
                  style: AppTypography.micro.copyWith(
                    fontSize: 8,
                    color: AppColors.lime,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _iconFor(SessionSource source) {
  switch (source) {
    case SessionSource.plan:
      return AppIcons.plan;
    case SessionSource.routine:
      return AppIcons.list;
    case SessionSource.walk:
      return AppIcons.walk;
    case SessionSource.run:
      return AppIcons.run;
    case SessionSource.empty:
      return AppIcons.dumbbell;
  }
}

Color _colorFor(SessionSource source) {
  switch (source) {
    case SessionSource.plan:
      return AppColors.lime;
    case SessionSource.routine:
      return AppColors.blue;
    case SessionSource.walk:
      return AppColors.gold;
    case SessionSource.run:
      return AppColors.blue;
    case SessionSource.empty:
      return AppColors.muted;
  }
}
