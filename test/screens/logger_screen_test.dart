import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/equipment_group.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/progression_suggestion.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/routine_exercise.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/profile_provider.dart';
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
import 'package:mova/theme/app_icons.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:mova/widgets/app_button.dart';
import 'package:mova/widgets/app_chip.dart';
import 'package:mova/widgets/exercise_picker_sheet.dart';
import 'package:mova/widgets/set_row.dart';
import 'package:provider/provider.dart';

IdGenerator _sequentialIds() {
  var counter = 0;
  return () => 'id-${++counter}';
}

Finder _assetIcon(String asset) => find.byWidgetPredicate(
  (widget) => widget is AppIcon && widget.asset == asset,
);

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
    List<EquipmentGroup>? equipment,
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
    final profile = ProfileProvider(storage, clock: activeClock);
    await profile.saveProfile(
      UserProfile(
        id: 'profile-1',
        availableEquipment: equipment ?? EquipmentGroup.values,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WorkoutProvider>.value(value: session),
          ChangeNotifierProvider<HistoryProvider>.value(value: history),
          ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<ProfileProvider>.value(value: profile),
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
    expect(
      find.descendant(
        of: find.byType(SetRow).first,
        matching: _assetIcon(AppIcons.check),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Toggle warm-up for set 1'));
    await tester.pumpAndSettle();
    expect(workout.activeSession!.exercises.first.sets.first.isWarmup, isTrue);

    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();
    expect(workout.activeSession!.exercises.first.sets, hasLength(3));

    await tester.drag(find.byType(SetRow).first, const Offset(-400, 0));
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

  testWidgets('shows the progressive overload hint for a prefilled exercise', (
    tester,
  ) async {
    final workout = WorkoutProvider(
      StorageService.inMemory(),
      clock: FakeClock(now),
      idService: IdService(generator: _sequentialIds()),
    );
    await workout.startFromRoutine(
      routine(),
      suggest: (exerciseId, repsLow, repsHigh) {
        if (exerciseId != 'barbell-bench-press') {
          return null;
        }
        return const ProgressionSuggestion(
          exerciseId: 'barbell-bench-press',
          weightKg: 82.5,
          reps: 8,
          previousWeightKg: 80,
          previousReps: 12,
          action: ProgressionAction.increase,
          sourceWorkoutId: 'previous-1',
          sourceSetId: 'previous-set-1',
        );
      },
    );

    await pumpLogger(tester, workout: workout);

    expect(find.byKey(const Key('logger-progression-hint')), findsOneWidget);
    expect(
      find.textContaining('Progressive overload: +2.5 kg'),
      findsOneWidget,
    );
    expect(find.text('82.5'), findsWidgets);
  });

  testWidgets('swaps an exercise after confirmation and resets its sets', (
    tester,
  ) async {
    final workout = await pumpLogger(
      tester,
      equipment: const <EquipmentGroup>[EquipmentGroup.dumbbells],
    );
    final original = workout.activeSession!.exercises.first;
    await workout.completeSet(
      exerciseId: original.exerciseId,
      setId: original.sets.first.id,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('logger-swap-exercise')));
    await tester.pumpAndSettle();

    expect(find.byType(ExercisePickerSheet), findsOneWidget);
    expect(find.text('Swap exercise'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ExercisePickerSheet),
        matching: find.text('Barbell Bench Press'),
      ),
      findsNothing,
    );
    final replacement = find.descendant(
      of: find.byType(ExercisePickerSheet),
      matching: find.text('Dumbbell Fly'),
    );
    expect(replacement, findsOneWidget);

    await tester.tap(replacement);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ExercisePickerSheet),
        matching: find.widgetWithText(AppButton, 'Add to workout'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Swap exercise?'), findsOneWidget);
    expect(find.textContaining('1 completed set will reset'), findsOneWidget);
    await tester.tap(find.byKey(const Key('swap-confirm')));
    await tester.pumpAndSettle();

    final swapped = workout.activeSession!.exercises.first;
    expect(swapped.exerciseId, 'dumbbell-fly');
    expect(swapped.sets, hasLength(original.sets.length));
    expect(
      swapped.sets.every((set) => set.weightKg == 0 && !set.completed),
      isTrue,
    );
  });

  testWidgets('shows live duration, volume, and set totals', (tester) async {
    final clock = FakeClock(now);
    await pumpLogger(tester, clock: clock);

    expect(find.byKey(const Key('logger-stats-bar')), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('0 kg'), findsOneWidget);
    expect(find.text('0 / 5'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit weight for set 1'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '100');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Complete set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('800 kg'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget);

    clock.advance(const Duration(seconds: 65));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:05'), findsOneWidget);
  });

  testWidgets('saves an exercise note and shows a preview', (tester) async {
    final workout = await pumpLogger(tester);

    await tester.tap(find.byKey(const Key('logger-exercise-notes')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('exercise-notes-field')),
      '  Pause at the chest  ',
    );
    await tester.tap(find.byKey(const Key('exercise-notes-save')));
    await tester.pumpAndSettle();

    expect(workout.activeSession!.exercises.first.notes, 'Pause at the chest');
    expect(find.byKey(const Key('logger-exercise-note')), findsOneWidget);
    expect(find.text('Pause at the chest'), findsOneWidget);
  });

  testWidgets('shows the focus drawer once for an empty workout', (
    tester,
  ) async {
    final clock = FakeClock(now);
    final storage = StorageService.inMemory();
    final workout = WorkoutProvider(
      storage,
      clock: clock,
      idService: IdService(generator: _sequentialIds()),
    );
    await workout.startEmpty();

    await pumpLogger(tester, workout: workout, clock: clock);

    expect(find.byKey(const Key('focus-sheet')), findsOneWidget);
    expect(workout.activeSession!.focusPromptShown, isFalse);

    await tester.tap(find.byKey(const Key('focus-done')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('focus-sheet')), findsNothing);
    expect(workout.activeSession!.focusPromptShown, isTrue);

    await pumpLogger(tester, workout: workout, clock: clock);

    expect(find.byKey(const Key('focus-sheet')), findsNothing);
  });

  testWidgets('routine workouts do not show the focus drawer', (
    tester,
  ) async {
    final workout = await pumpLogger(tester);

    expect(find.byKey(const Key('focus-sheet')), findsNothing);
    expect(workout.activeSession!.focusPromptShown, isTrue);
  });

  testWidgets('rest timer toggle suppresses the rest banner', (tester) async {
    await pumpLogger(tester);

    await tester.tap(find.byKey(const Key('logger-rest-toggle')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Rest timer off'), findsOneWidget);

    await tester.tap(find.byTooltip('Complete set 1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Rest ·'), findsNothing);
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
