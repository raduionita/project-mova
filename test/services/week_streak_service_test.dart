import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/services/week_streak_service.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
const WeekStreakService _service = WeekStreakService();

WorkoutSession _session(
  DateTime date, {
  SessionStatus status = SessionStatus.completed,
}) {
  return WorkoutSession(
    id: 'session-${date.toIso8601String()}',
    name: 'Workout',
    source: SessionSource.empty,
    startedAt: date.subtract(const Duration(minutes: 30)),
    completedAt: date,
    status: status,
    exercises: const [],
  );
}

void main() {
  test('counts complete weeks plus a completed current week', () {
    final streak = _service.currentWeekStreak(
      <WorkoutSession>[
        _session(DateTime(2026, 11, 2)),
        _session(DateTime(2026, 11, 3)),
        _session(DateTime(2026, 11, 4)),
        _session(DateTime(2026, 10, 26)),
        _session(DateTime(2026, 10, 27)),
        _session(DateTime(2026, 10, 28)),
        _session(DateTime(2026, 10, 19)),
        _session(DateTime(2026, 10, 20)),
        _session(DateTime(2026, 10, 21)),
      ],
      _now,
      target: 3,
    );

    expect(streak, 3);
  });

  test('a partial current week does not break the streak', () {
    final streak = _service.currentWeekStreak(
      <WorkoutSession>[
        _session(DateTime(2026, 11, 2)),
        _session(DateTime(2026, 10, 26)),
        _session(DateTime(2026, 10, 27)),
        _session(DateTime(2026, 10, 28)),
        _session(DateTime(2026, 10, 19)),
        _session(DateTime(2026, 10, 20)),
        _session(DateTime(2026, 10, 21)),
      ],
      _now,
      target: 3,
    );

    expect(streak, 2);
  });

  test('the current week joins only after reaching the target', () {
    final history = <WorkoutSession>[
      _session(DateTime(2026, 11, 2)),
      _session(DateTime(2026, 11, 3)),
      _session(DateTime(2026, 11, 4)),
      _session(DateTime(2026, 10, 26)),
      _session(DateTime(2026, 10, 27)),
      _session(DateTime(2026, 10, 28)),
    ];

    expect(_service.currentWeekStreak(history, _now, target: 3), 2);
    expect(_service.currentWeekStreak(history, _now, target: 4), 0);
  });

  test('respects a Sunday week start', () {
    final streak = _service.currentWeekStreak(
      <WorkoutSession>[
        _session(DateTime(2026, 11, 1)),
        _session(DateTime(2026, 11, 2)),
        _session(DateTime(2026, 10, 25)),
        _session(DateTime(2026, 10, 26)),
      ],
      _now,
      weekStart: DateTime.sunday,
      target: 2,
    );

    expect(streak, 2);
    expect(
      _service.sessionsInWeek(
        <WorkoutSession>[
          _session(DateTime(2026, 11, 1)),
          _session(DateTime(2026, 11, 2)),
        ],
        _now,
        weekStart: DateTime.sunday,
      ),
      2,
    );
  });

  test('an empty current week keeps the last completed streak', () {
    final streak = _service.currentWeekStreak(
      <WorkoutSession>[
        _session(DateTime(2026, 10, 26)),
        _session(DateTime(2026, 10, 27)),
        _session(DateTime(2026, 10, 28)),
      ],
      _now,
      target: 3,
    );

    expect(streak, 1);
  });

  test('a missed completed week breaks the streak', () {
    final streak = _service.currentWeekStreak(
      <WorkoutSession>[
        _session(DateTime(2026, 10, 26)),
        _session(DateTime(2026, 10, 27)),
        _session(DateTime(2026, 10, 28)),
        _session(DateTime(2026, 10, 12)),
        _session(DateTime(2026, 10, 13)),
        _session(DateTime(2026, 10, 14)),
      ],
      _now,
      target: 3,
    );

    expect(streak, 1);
  });

  test('ignores unfinished sessions and caps by profile age', () {
    final history = <WorkoutSession>[
      _session(DateTime(2026, 11, 2)),
      _session(DateTime(2026, 11, 3), status: SessionStatus.active),
      _session(DateTime(2026, 10, 26)),
      _session(DateTime(2026, 10, 27)),
      _session(DateTime(2026, 10, 28)),
    ];

    expect(
      _service.currentWeekStreak(
        history,
        _now,
        target: 1,
        profileCreatedAt: DateTime(2026, 10, 27),
      ),
      2,
    );
  });
}
