import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/services/strength_score_service.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
const StrengthScoreService _service = StrengthScoreService();

WorkoutSession _session(int index) {
  final date = DateTime(_now.year, _now.month, _now.day - index);
  return WorkoutSession(
    id: 'session-$index',
    name: 'Workout',
    source: SessionSource.empty,
    startedAt: date.subtract(const Duration(minutes: 40)),
    completedAt: date,
    status: SessionStatus.completed,
    exercises: const [],
  );
}

PersonalRecord _record(String exerciseId, double bestE1rmKg) {
  return PersonalRecord(
    exerciseId: exerciseId,
    bestE1rmKg: bestE1rmKg,
    weightKg: bestE1rmKg / 1.1667,
    reps: 5,
    achievedAt: _now,
    sessionId: 'session-0',
    previousBestKg: 0,
  );
}

List<WorkoutSession> _threeSessions() {
  return <WorkoutSession>[_session(0), _session(1), _session(2)];
}

void main() {
  test('requires three completed sessions', () {
    final result = _service.compute(
      history: <WorkoutSession>[_session(0), _session(1)],
      records: <String, PersonalRecord>{
        'back-squat': _record('back-squat', 160),
        'barbell-bench-press': _record('barbell-bench-press', 120),
      },
      bodyWeightKg: 80,
    );

    expect(result.score, isNull);
    expect(result.reason, StrengthScoreService.missingHistoryReason);
  });

  test('non-completed sessions do not count', () {
    final active = _session(3).copyWith(status: SessionStatus.active);
    final result = _service.compute(
      history: <WorkoutSession>[_session(0), _session(1), active],
      records: <String, PersonalRecord>{
        'back-squat': _record('back-squat', 160),
        'barbell-bench-press': _record('barbell-bench-press', 120),
      },
      bodyWeightKg: 80,
    );

    expect(result.score, isNull);
    expect(result.reason, StrengthScoreService.missingHistoryReason);
  });

  test('requires a positive body weight', () {
    final result = _service.compute(
      history: _threeSessions(),
      records: <String, PersonalRecord>{
        'back-squat': _record('back-squat', 160),
        'barbell-bench-press': _record('barbell-bench-press', 120),
      },
      bodyWeightKg: 0,
    );

    expect(result.score, isNull);
    expect(result.reason, StrengthScoreService.missingBodyWeightReason);
  });

  test('requires two tracked lifts', () {
    final result = _service.compute(
      history: _threeSessions(),
      records: <String, PersonalRecord>{
        'back-squat': _record('back-squat', 160),
        'barbell-curl': _record('barbell-curl', 60),
      },
      bodyWeightKg: 80,
    );

    expect(result.score, isNull);
    expect(result.reason, StrengthScoreService.missingLiftsReason);
  });

  test('averages tracked lift ratios against body weight', () {
    final result = _service.compute(
      history: _threeSessions(),
      records: <String, PersonalRecord>{
        'back-squat': _record('back-squat', 160),
        'barbell-bench-press': _record('barbell-bench-press', 120),
        'barbell-curl': _record('barbell-curl', 300),
      },
      bodyWeightKg: 80,
    );

    // (160 / 80 * 100 + 120 / 80 * 100) / 2 = 175.
    expect(result.score, 175);
    expect(result.reason, isNull);
  });

  test('tracks four supported lifts and ignores the rest', () {
    final result = _service.compute(
      history: _threeSessions(),
      records: <String, PersonalRecord>{
        'back-squat': _record('back-squat', 160),
        'barbell-bench-press': _record('barbell-bench-press', 120),
        'deadlift': _record('deadlift', 200),
        'overhead-press': _record('overhead-press', 80),
        'barbell-curl': _record('barbell-curl', 400),
      },
      bodyWeightKg: 80,
    );

    // (200 + 150 + 250 + 100) / 4 = 175.
    expect(result.score, 175);
  });
}
