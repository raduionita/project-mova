import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/screens/summary/summary_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/haptics_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime.utc(2026, 11, 6, 12, 30);
late List<Exercise> _library;

WorkoutSession _session() {
  return WorkoutSession(
    id: 'session-1',
    name: 'Push Day',
    source: SessionSource.routine,
    routineId: 'routine-1',
    startedAt: _now.subtract(const Duration(minutes: 30)),
    completedAt: _now,
    status: SessionStatus.completed,
    exercises: <SessionExercise>[
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
            weightKg: 100,
            reps: 5,
            isWarmup: true,
            completed: true,
            completedAt: _now,
          ),
          WorkoutSet(id: 'set-3', index: 2, weightKg: 100, reps: 5),
        ],
      ),
      SessionExercise(
        id: 'exercise-2',
        exerciseId: 'dumbbell-fly',
        order: 1,
        sets: <WorkoutSet>[
          WorkoutSet(
            id: 'set-4',
            index: 0,
            weightKg: 20,
            reps: 10,
            completed: true,
            completedAt: _now,
          ),
        ],
      ),
    ],
  );
}

PersonalRecord _record({
  required String exerciseId,
  required double best,
  required double previous,
}) {
  return PersonalRecord(
    exerciseId: exerciseId,
    bestE1rmKg: best,
    weightKg: 100,
    reps: 5,
    achievedAt: _now,
    sessionId: 'session-1',
    previousBestKg: previous,
  );
}

Future<void> _pumpSummary(
  WidgetTester tester, {
  List<PersonalRecord> records = const <PersonalRecord>[],
  VoidCallback? onSave,
  HapticsService? haptics,
}) async {
  final storage = StorageService.inMemory();
  final library = ExerciseProvider(
    storage,
    _StaticSeedDataService(_library),
    clock: FakeClock(_now),
  );
  await library.load();
  final settings = SettingsProvider(storage);
  await settings.load();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ExerciseProvider>.value(value: library),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: SummaryScreen(
          session: _session(),
          records: records,
          onSave: onSave,
          clock: FakeClock(_now),
          haptics: haptics,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    _library = await SeedDataService().loadExercises();
  });

  testWidgets('shows time, volume, and completed set totals', (tester) async {
    await _pumpSummary(tester);

    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('30:00'), findsOneWidget);
    expect(find.text('700 kg'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('NEW PR'), findsNothing);
    expect(find.text('Also new'), findsNothing);
  });

  testWidgets('shows the top personal record with its previous best', (
    tester,
  ) async {
    await _pumpSummary(
      tester,
      records: <PersonalRecord>[
        _record(exerciseId: 'barbell-bench-press', best: 116.66, previous: 110),
      ],
    );

    expect(find.text('NEW PR'), findsOneWidget);
    expect(find.text('Barbell Bench Press · est. 1RM'), findsOneWidget);
    expect(find.text('116.7 kg'), findsOneWidget);
    expect(find.text('+6.7 kg vs last best'), findsOneWidget);
  });

  testWidgets('lists remaining personal records under Also new', (
    tester,
  ) async {
    await _pumpSummary(
      tester,
      records: <PersonalRecord>[
        _record(exerciseId: 'dumbbell-fly', best: 30, previous: 0),
        _record(exerciseId: 'barbell-bench-press', best: 116.66, previous: 110),
      ],
    );

    expect(find.text('NEW PR'), findsOneWidget);
    expect(find.text('Also new'), findsOneWidget);
    expect(find.text('Dumbbell Fly 30 kg'), findsOneWidget);
    expect(find.text('Barbell Bench Press · est. 1RM'), findsOneWidget);
  });

  testWidgets('does not fire the personal record haptic without records', (
    tester,
  ) async {
    final haptics = _FakeHaptics();
    await _pumpSummary(tester, haptics: haptics);

    expect(haptics.personalRecordCount, 0);
  });

  testWidgets('fires the personal record haptic when records exist', (
    tester,
  ) async {
    final haptics = _FakeHaptics();
    await _pumpSummary(
      tester,
      haptics: haptics,
      records: <PersonalRecord>[
        _record(exerciseId: 'barbell-bench-press', best: 116.66, previous: 110),
      ],
    );

    expect(haptics.personalRecordCount, 1);
    expect(haptics.lastReduceMotion, isFalse);
  });

  testWidgets('save workout invokes the save callback', (tester) async {
    var saved = false;
    await _pumpSummary(tester, onSave: () => saved = true);

    await tester.tap(find.text('Save workout'));
    await tester.pump();

    expect(saved, isTrue);
  });
}

class _StaticSeedDataService extends SeedDataService {
  _StaticSeedDataService(this._exercises);

  final List<Exercise> _exercises;

  @override
  Future<List<Exercise>> loadExercises() async => _exercises;
}

class _FakeHaptics implements HapticsService {
  int personalRecordCount = 0;
  bool? lastReduceMotion;

  @override
  Future<void> personalRecord({bool reduceMotion = false}) async {
    lastReduceMotion = reduceMotion;
    if (reduceMotion) {
      return;
    }
    personalRecordCount++;
  }

  @override
  Future<void> restFinished({bool reduceMotion = false}) async {}

  @override
  Future<void> setCompleted({bool reduceMotion = false}) async {}
}
