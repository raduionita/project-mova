import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/services/streak_service.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
const StreakService _service = StreakService();

WorkoutSession _session(
  int daysAgo, {
  SessionStatus status = SessionStatus.completed,
  SessionSource source = SessionSource.empty,
  String? id,
}) {
  final date = DateTime(_now.year, _now.month, _now.day - daysAgo);
  return WorkoutSession(
    id: id ?? 'session-$daysAgo',
    name: source == SessionSource.walk ? 'Walk' : 'Workout',
    source: source,
    startedAt: date.subtract(const Duration(minutes: 30)),
    completedAt: date,
    status: status,
    exercises: const [],
  );
}

void main() {
  test('counts consecutive days ending today', () {
    final streak = _service.currentStreak(<WorkoutSession>[
      _session(0),
      _session(1),
      _session(2),
    ], _now);

    expect(streak, 3);
  });

  test('counts a streak that ends yesterday', () {
    final streak = _service.currentStreak(<WorkoutSession>[
      _session(1),
      _session(2),
    ], _now);

    expect(streak, 2);
  });

  test('breaks at the first missing day', () {
    final streak = _service.currentStreak(<WorkoutSession>[
      _session(0),
      _session(2),
      _session(3),
    ], _now);

    expect(streak, 1);
  });

  test('returns zero when the last activity is older than yesterday', () {
    final streak = _service.currentStreak(<WorkoutSession>[
      _session(2),
      _session(3),
    ], _now);

    expect(streak, 0);
  });

  test('counts completed walks and ignores active sessions', () {
    final streak = _service.currentStreak(<WorkoutSession>[
      _session(0, source: SessionSource.walk),
      _session(1),
      _session(2, status: SessionStatus.active),
    ], _now);

    expect(streak, 2);
  });

  test('never exceeds the days since profile creation', () {
    final streak = _service.currentStreak(
      <WorkoutSession>[
        _session(0),
        _session(1),
        _session(2),
        _session(3),
        _session(4),
      ],
      _now,
      profileCreatedAt: DateTime(2026, 11, 4),
    );

    expect(streak, 3);
  });

  test('two workouts on one day count once', () {
    final streak = _service.currentStreak(<WorkoutSession>[
      _session(0, id: 'a'),
      _session(0, id: 'b'),
    ], _now);

    expect(streak, 1);
  });
}
