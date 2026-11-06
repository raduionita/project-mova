import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/routine_exercise.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/screens/logger/logger_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/haptics_service.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/keep_awake_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_chip.dart';
import 'package:provider/provider.dart';

IdGenerator _sequentialIds() {
  var counter = 0;
  return () => 'id-${++counter}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> library;

  setUpAll(() async {
    library = await SeedDataService().loadExercises();
  });

  final now = DateTime.utc(2026, 11, 6, 12);

  Routine routine() {
    return Routine(
      id: 'routine-1',
      name: 'Push day',
      createdAt: now,
      updatedAt: now,
      exercises: const <RoutineExercise>[
        RoutineExercise(
          exerciseId: 'barbell-bench-press',
          sets: 2,
          repsLow: 8,
          repsHigh: 10,
          restSeconds: 90,
          order: 0,
        ),
        RoutineExercise(
          exerciseId: 'dumbbell-fly',
          sets: 3,
          repsLow: 12,
          repsHigh: 12,
          restSeconds: 60,
          order: 1,
        ),
      ],
    );
  }

  WorkoutSession previousSession() {
    return WorkoutSession(
      id: 'previous-1',
      name: 'Push day',
      source: SessionSource.routine,
      routineId: 'routine-1',
      startedAt: now.subtract(const Duration(days: 1)),
      completedAt: now.subtract(const Duration(days: 1, hours: -1)),
      status: SessionStatus.completed,
      exercises: <SessionExercise>[
        SessionExercise(
          id: 'previous-exercise-1',
          exerciseId: 'barbell-bench-press',
          order: 0,
          sets: <WorkoutSet>[
            WorkoutSet(
              id: 'previous-set-1',
              index: 0,
              weightKg: 80,
              reps: 8,
              completed: true,
              completedAt: now.subtract(const Duration(days: 1)),
            ),
            WorkoutSet(
              id: 'previous-set-2',
              index: 1,
              weightKg: 82.5,
              reps: 6,
              completed: true,
              completedAt: now.subtract(const Duration(days: 1)),
            ),
          ],
        ),
      ],
    );
  }

  Future<WorkoutProvider> pumpLogger(
    WidgetTester tester, {
    WorkoutProvider? workout,
    WeightUnit unit = WeightUnit.kg,
    KeepAwakeService? keepAwake,
    HapticsService? haptics,
    bool reduceMotion = false,
    Clock? clock,
  }) async {
    final activeClock = clock ?? FakeClock(now);
    final storage = StorageService.inMemory();
    final session =
        workout ??
        WorkoutProvider(
          storage,
          clock: activeClock,
          idService: IdService(generator: _sequentialIds()),
        );
    if (session.activeSession == null) {
      await session.startFromRoutine(routine());
    }
    final history = HistoryProvider(storage);
    await history.load();
    await history.addCompleted(previousSession());
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
    );
    await exercises.load();
    final settings = SettingsProvider(storage);
    await settings.load();
    await settings.setUnitPreferences(UnitPreferences(weightUnit: unit));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkoutProvider>.value(value: session),
          ChangeNotifierProvider<HistoryProvider>.value(value: history),
          ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          routes: <String, WidgetBuilder>{
            Routes.today: (_) => const Scaffold(body: Text('Today route')),
          },
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reduceMotion),
              child: LoggerScreen(
                clock: activeClock,
                keepAwake: keepAwake,
                haptics: haptics,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets('shows the session, current exercise, and previous values', (
    tester,
  ) async {
    await pumpLogger(tester);

    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsWidgets);
    expect(find.text('1 of 2 · 2 sets'), findsOneWidget);
    expect(find.text('80 × 8'), findsOneWidget);
    expect(find.text('82.5 × 6'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byTooltip('Edit weight for set 1'),
        matching: find.text('-'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byTooltip('Edit reps for set 1'),
        matching: find.text('8'),
      ),
      findsOneWidget,
    );
    expect(find.text('KG × REPS'), findsOneWidget);
    expect(find.text('Add set'), findsOneWidget);
  });

  testWidgets('edits weight and reps through numeric sheets', (tester) async {
    final workout = await pumpLogger(tester);

    await tester.tap(find.byTooltip('Edit weight for set 1'));
    await tester.pumpAndSettle();
    expect(find.text('Edit weight'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '82.5');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit reps for set 1'));
    await tester.pumpAndSettle();
    expect(find.text('Edit reps'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final set = workout.activeSession!.exercises.first.sets.first;
    expect(set.weightKg, 82.5);
    expect(set.reps, 9);
    expect(find.text('82.5'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('converts pounds when the unit is pounds', (tester) async {
    final workout = await pumpLogger(tester, unit: WeightUnit.lb);

    await tester.tap(find.byTooltip('Edit weight for set 1'));
    await tester.pumpAndSettle();
    expect(find.text('Weight (lb)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '185');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final set = workout.activeSession!.exercises.first.sets.first;
    expect(set.weightKg, 84.0);
    expect(find.text('185.2'), findsOneWidget);
  });

  testWidgets('rejects an out-of-range rep count', (tester) async {
    final workout = await pumpLogger(tester);

    await tester.tap(find.byTooltip('Edit reps for set 1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a value from 1 to 100.'), findsOneWidget);
    expect(find.text('Edit reps'), findsOneWidget);
    expect(workout.activeSession!.exercises.first.sets.first.reps, 8);

    await tester.enterText(find.byType(TextField), '9');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(workout.activeSession!.exercises.first.sets.first.reps, 9);
  });

  testWidgets('starts rest after a completed set and skips it', (tester) async {
    await pumpLogger(tester);

    expect(find.textContaining('Rest ·'), findsNothing);

    await tester.tap(find.byTooltip('Complete set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Rest · 2:00'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Rest ·'), findsNothing);
  });

  testWidgets('fires haptics when a set completes and rest ends', (
    tester,
  ) async {
    final haptics = _FakeHaptics();
    final clock = FakeClock(now);
    await pumpLogger(tester, haptics: haptics, clock: clock);

    await tester.tap(find.byTooltip('Complete set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Rest · 2:00'), findsOneWidget);
    expect(haptics.setCompletedCount, 1);
    expect(haptics.restFinishedCount, 0);

    clock.advance(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.textContaining('Rest ·'), findsNothing);
    expect(haptics.restFinishedCount, 1);
  });

  testWidgets('skipping rest does not fire the rest completion haptic', (
    tester,
  ) async {
    final haptics = _FakeHaptics();
    await pumpLogger(tester, haptics: haptics);

    await tester.tap(find.byTooltip('Complete set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(minutes: 2));

    expect(haptics.setCompletedCount, 1);
    expect(haptics.restFinishedCount, 0);
  });

  testWidgets('suppresses haptics when reduced motion is enabled', (
    tester,
  ) async {
    final haptics = _FakeHaptics();
    await pumpLogger(tester, haptics: haptics, reduceMotion: true);

    await tester.tap(find.byTooltip('Complete set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(haptics.lastReduceMotion, isTrue);
    expect(haptics.setCompletedCount, 0);
  });

  testWidgets('completes, warms up, adds, and removes sets', (tester) async {
    final workout = await pumpLogger(tester);

    await tester.tap(find.byTooltip('Complete set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(workout.activeSession!.exercises.first.sets.first.completed, isTrue);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Toggle warm-up for set 1'));
    await tester.pumpAndSettle();
    expect(workout.activeSession!.exercises.first.sets.first.isWarmup, isTrue);

    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    expect(workout.activeSession!.exercises.first.sets, hasLength(3));

    await tester.tap(find.byTooltip('Remove set 1'));
    await tester.pumpAndSettle();
    expect(workout.activeSession!.exercises.first.sets, hasLength(2));
  });

  testWidgets('switches exercises from the chip row', (tester) async {
    await pumpLogger(tester);

    expect(find.text('1 of 2 · 2 sets'), findsOneWidget);
    expect(find.text('Up next: Dumbbell Fly'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppChip, 'Dumbbell Fly'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 2 · 3 sets'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byTooltip('Edit reps for set 1'),
        matching: find.text('12'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('pausing from the interruption sheet persists the session', (
    tester,
  ) async {
    final workout = await pumpLogger(tester);

    await tester.tap(find.byTooltip('Close workout'));
    await tester.pumpAndSettle();
    expect(find.text('Workout in progress'), findsOneWidget);

    await tester.tap(find.text('Pause and exit'));
    await tester.pumpAndSettle();

    expect(workout.activeSession, isNotNull);
    expect(workout.activeSession!.status, SessionStatus.paused);
    expect(find.text('Today route'), findsOneWidget);
  });

  testWidgets('system back asks before leaving an active workout', (
    tester,
  ) async {
    final workout = await pumpLogger(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Workout in progress'), findsOneWidget);
    expect(workout.activeSession, isNotNull);
  });

  testWidgets('discarding confirms and clears the active session', (
    tester,
  ) async {
    final workout = await pumpLogger(tester);

    await tester.tap(find.byTooltip('Complete set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Skip'));
    await tester.pump();

    await tester.tap(find.byTooltip('Close workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard workout'));
    await tester.pumpAndSettle();

    expect(find.text('Discard this workout?'), findsOneWidget);
    expect(
      find.text('You will lose 1 completed set. This cannot be undone.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(workout.activeSession, isNull);
    expect(find.text('Today route'), findsOneWidget);
  });

  testWidgets('keeps the screen awake only while the workout is active', (
    tester,
  ) async {
    final keepAwake = _FakeKeepAwake();
    await pumpLogger(tester, keepAwake: keepAwake);
    await tester.pump();

    expect(keepAwake.enabled, 1);
    expect(keepAwake.disabled, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(keepAwake.disabled, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(keepAwake.enabled, 2);
  });

  testWidgets('shows an empty state when the session has no exercises', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(now),
      idService: IdService(generator: () => 'empty-1'),
    );
    await workout.startEmpty();

    await pumpLogger(tester, workout: workout);

    expect(find.text('Empty workout'), findsOneWidget);
    expect(find.text('No exercises yet'), findsOneWidget);
    expect(find.text('Add exercise'), findsOneWidget);
  });
}

/// Serves a preloaded library so widget tests never load assets inside a
/// `testWidgets` body.
class _StaticSeedDataService extends SeedDataService {
  _StaticSeedDataService(this._exercises);

  final List<Exercise> _exercises;

  @override
  Future<List<Exercise>> loadExercises() async => _exercises;
}

class _FakeKeepAwake implements KeepAwakeService {
  int enabled = 0;
  int disabled = 0;

  @override
  Future<void> enable() async {
    enabled++;
  }

  @override
  Future<void> disable() async {
    disabled++;
  }
}

class _FakeHaptics implements HapticsService {
  int setCompletedCount = 0;
  int restFinishedCount = 0;
  int personalRecordCount = 0;
  bool? lastReduceMotion;

  @override
  Future<void> setCompleted({bool reduceMotion = false}) async {
    lastReduceMotion = reduceMotion;
    if (reduceMotion) {
      return;
    }
    setCompletedCount++;
  }

  @override
  Future<void> restFinished({bool reduceMotion = false}) async {
    lastReduceMotion = reduceMotion;
    if (reduceMotion) {
      return;
    }
    restFinishedCount++;
  }

  @override
  Future<void> personalRecord({bool reduceMotion = false}) async {
    lastReduceMotion = reduceMotion;
    if (reduceMotion) {
      return;
    }
    personalRecordCount++;
  }
}
