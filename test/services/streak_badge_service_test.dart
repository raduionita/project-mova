import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/streak_badge_service.dart';

void main() {
  const service = StreakBadgeService();

  test('awards day badges at the next tiers', () {
    final badges = service.badges(dayStreak: 8, weekStreak: 0);

    expect(badges.where((badge) => badge.kind == StreakBadgeKind.day).length, 4);
    expect(
      badges.where((badge) => badge.kind == StreakBadgeKind.day && badge.earned)
          .map((badge) => badge.target),
      <int>[3, 7],
    );
  });

  test('awards week badges from completed weeks', () {
    final badges = service.badges(dayStreak: 0, weekStreak: 4);
    final weeks = badges
        .where((badge) => badge.kind == StreakBadgeKind.week)
        .toList();

    expect(weeks.map((badge) => badge.target), <int>[1, 4, 12]);
    expect(weeks.map((badge) => badge.earned), <bool>[true, true, false]);
    expect(weeks.last.progressHint, '4 / 12 weeks');
  });

  test('locked badges describe progress toward their target', () {
    final badges = service.badges(dayStreak: 5, weekStreak: 0);
    final sevenDays = badges.firstWhere(
      (badge) => badge.kind == StreakBadgeKind.day && badge.target == 7,
    );

    expect(sevenDays.earned, isFalse);
    expect(sevenDays.progressHint, '5 / 7 days');
    expect(sevenDays.label, '7 days');
  });
}
