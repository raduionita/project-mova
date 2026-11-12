import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/session_stats_bar.dart';

final DateTime _now = DateTime.utc(2026, 11, 6, 12);

WorkoutSet _set({
  required String id,
  required int index,
  required double weightKg,
  required int reps,
  bool isWarmup = false,
  bool completed = true,
}) {
  return WorkoutSet(
    id: id,
    index: index,
    weightKg: weightKg,
    reps: reps,
    isWarmup: isWarmup,
    completed: completed,
  );
}

WorkoutSession _session() {
  return WorkoutSession(
    id: 'session-1',
    name: 'Push day',
    source: SessionSource.empty,
    startedAt: _now,
    status: SessionStatus.active,
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'exercise-1',
        exerciseId: 'barbell-bench-press',
        order: 0,
        sets: <WorkoutSet>[
          _set(id: 'set-1', index: 0, weightKg: 100, reps: 5, isWarmup: true),
          _set(id: 'set-2', index: 1, weightKg: 100, reps: 5),
          _set(id: 'set-3', index: 2, weightKg: 50, reps: 5, completed: false),
        ],
      ),
      SessionExercise(
        id: 'exercise-2',
        exerciseId: 'dumbbell-fly',
        order: 1,
        sets: <WorkoutSet>[_set(id: 'set-4', index: 0, weightKg: 20, reps: 10)],
      ),
    ],
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('shows completed working volume and set totals', (tester) async {
    await tester.pumpWidget(
      _wrap(SessionStatsBar(session: _session(), clock: FakeClock(_now))),
    );

    expect(find.byKey(const Key('logger-stats-bar')), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('700 kg'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('ticks the duration every second', (tester) async {
    final clock = FakeClock(_now);
    await tester.pumpWidget(
      _wrap(SessionStatsBar(session: _session(), clock: clock)),
    );

    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('01:05'), findsOneWidget);
  });

  testWidgets('converts volume for pounds', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SessionStatsBar(
          session: _session(),
          weightUnit: WeightUnit.lb,
          clock: FakeClock(_now),
        ),
      ),
    );

    expect(find.text('1543.2 lb'), findsOneWidget);
  });

  testWidgets('fits long values on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final session = _session().copyWith(
      startedAt: _now.subtract(const Duration(hours: 12)),
      exercises: <SessionExercise>[
        SessionExercise(
          id: 'exercise-1',
          exerciseId: 'barbell-bench-press',
          order: 0,
          sets: <WorkoutSet>[
            _set(id: 'set-1', index: 0, weightKg: 400, reps: 100),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      _wrap(
        SessionStatsBar(
          session: session,
          weightUnit: WeightUnit.lb,
          clock: FakeClock(_now),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('88184.9 lb'), findsOneWidget);
  });
}
