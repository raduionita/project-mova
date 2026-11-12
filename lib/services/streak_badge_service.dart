enum StreakBadgeKind { day, week }

/// One display-only streak milestone.
class StreakBadge {
  const StreakBadge({
    required this.kind,
    required this.target,
    required this.label,
    required this.earned,
    required this.progressHint,
  });

  final StreakBadgeKind kind;
  final int target;
  final String label;
  final bool earned;
  final String progressHint;
}

/// Derives local, display-only streak milestones from existing streak values.
class StreakBadgeService {
  const StreakBadgeService();

  static const List<int> dayTargets = <int>[3, 7, 14, 30];
  static const List<int> weekTargets = <int>[1, 4, 12];

  List<StreakBadge> badges({
    required int dayStreak,
    required int weekStreak,
  }) {
    return <StreakBadge>[
      for (final target in dayTargets)
        StreakBadge(
          kind: StreakBadgeKind.day,
          target: target,
          label: target == 1 ? '1 day' : '$target days',
          earned: dayStreak >= target,
          progressHint: '$dayStreak / $target days',
        ),
      for (final target in weekTargets)
        StreakBadge(
          kind: StreakBadgeKind.week,
          target: target,
          label: target == 1 ? '1 week' : '$target weeks',
          earned: weekStreak >= target,
          progressHint: '$weekStreak / $target weeks',
        ),
    ];
  }
}
