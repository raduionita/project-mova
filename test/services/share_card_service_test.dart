import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/services/share_card_service.dart';

final DateTime _now = DateTime.utc(2026, 11, 6, 12);

WorkoutSession _session({bool withSets = true}) {
  return WorkoutSession(
    id: 'session-1',
    name: 'Push Day',
    source: SessionSource.plan,
    startedAt: _now.subtract(const Duration(minutes: 40)),
    completedAt: _now,
    status: SessionStatus.completed,
    exercises: withSets
        ? <SessionExercise>[
            SessionExercise(
              id: 'exercise-1',
              exerciseId: 'barbell-bench-press',
              order: 0,
              sets: <WorkoutSet>[
                WorkoutSet(
                  id: 'set-1',
                  index: 0,
                  weightKg: 100,
                  reps: 5,
                  completed: true,
                  completedAt: _now,
                ),
                WorkoutSet(
                  id: 'set-2',
                  index: 1,
                  weightKg: 60,
                  reps: 5,
                  isWarmup: true,
                  completed: true,
                  completedAt: _now,
                ),
              ],
            ),
          ]
        : const <SessionExercise>[],
  );
}

PersonalRecord _record() {
  return PersonalRecord(
    exerciseId: 'barbell-bench-press',
    bestE1rmKg: 116.66,
    weightKg: 100,
    reps: 5,
    achievedAt: _now,
    sessionId: 'session-1',
    previousBestKg: 110,
  );
}

Future<ui.Image> _decode(List<int> bytes) async {
  final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
  final frame = await codec.getNextFrame();
  return frame.image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = ShareCardService();

  test('headlineFor uses the workout headline without a record', () {
    expect(ShareCardService.headlineFor(null), 'WORKOUT');
  });

  test('headlineFor uses the record headline with a record', () {
    expect(ShareCardService.headlineFor(_record()), 'PERSONAL RECORD');
  });

  test('render produces a 1080x1920 PNG', () async {
    final bytes = await service.render(
      _session(),
      exerciseName: (id) => 'Barbell Bench Press',
    );

    expect(bytes, isNotNull);
    expect(bytes!.sublist(0, 4), <int>[0x89, 0x50, 0x4E, 0x47]);

    final image = await _decode(bytes);
    expect(image.width, 1080);
    expect(image.height, 1920);
  });

  test('render works with a personal record and pound units', () async {
    final bytes = await service.render(
      _session(),
      record: _record(),
      exerciseName: (id) => 'Barbell Bench Press',
      weightUnit: WeightUnit.lb,
    );

    expect(bytes, isNotNull);
    final image = await _decode(bytes!);
    expect(image.width, ShareCardService.cardWidth);
    expect(image.height, ShareCardService.cardHeight);
  });

  test('render handles an empty workout without throwing', () async {
    final bytes = await service.render(_session(withSets: false));

    expect(bytes, isNotNull);
    expect(bytes, isNotEmpty);
  });

  test('render falls back to a readable exercise name', () async {
    final bytes = await service.render(_session(), exerciseName: (id) => '');

    expect(bytes, isNotNull);
  });
}
