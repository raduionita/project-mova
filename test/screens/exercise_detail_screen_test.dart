import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/screens/train/exercise_detail_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_button.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime.utc(2026, 11, 6, 12);

class _StaticSeedDataService extends SeedDataService {
  _StaticSeedDataService(this._exercises);

  final List<Exercise> _exercises;

  @override
  Future<List<Exercise>> loadExercises() async => _exercises;
}

Widget _wrap({
  required ExerciseProvider exercises,
  required ProgressProvider progress,
  required SettingsProvider settings,
  required WorkoutProvider workout,
  String exerciseId = 'barbell-bench-press',
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
      ChangeNotifierProvider<ProgressProvider>.value(value: progress),
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<WorkoutProvider>.value(value: workout),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: Text('logger-stub', key: Key('logger-stub')),
        ),
      ),
      home: ExerciseDetailScreen(exerciseId: exerciseId),
    ),
  );
}

void main() {
  late List<Exercise> library;

  setUpAll(() async {
    library = await SeedDataService().loadExercises();
  });

  testWidgets('renders tags, instructions, and the first-time best state', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
      clock: FakeClock(_now),
    );
    await exercises.load();
    final progress = ProgressProvider(storage);
    final settings = SettingsProvider(storage);
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(),
    );

    await tester.pumpWidget(
      _wrap(
        exercises: exercises,
        progress: progress,
        settings: settings,
        workout: workout,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Chest'), findsOneWidget);
    expect(find.text('Triceps'), findsOneWidget);
    expect(find.text('Shoulders'), findsOneWidget);
    expect(find.text('Barbell'), findsOneWidget);
    expect(find.text('Lie on a flat bench with feet planted.'), findsOneWidget);
    expect(
      find.text('First time? Log a set to start tracking.'),
      findsOneWidget,
    );

    final start = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Start workout with this exercise'),
    );
    expect(start.onPressed, isNotNull);
    expect(find.text('Add to saved workout'), findsOneWidget);
    expect(find.text('View history'), findsOneWidget);
  });

  testWidgets('renders the previous best weight, reps, and date', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final pr = PersonalRecord(
      exerciseId: 'barbell-bench-press',
      bestE1rmKg: 100,
      weightKg: 80,
      reps: 8,
      achievedAt: DateTime.utc(2026, 11, 1),
      sessionId: 'session-1',
      previousBestKg: 75,
    );
    await storage.writeMap(kPrsKey, <String, Map<String, dynamic>>{
      pr.exerciseId: pr.toJson(),
    });

    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
      clock: FakeClock(_now),
    );
    await exercises.load();
    final progress = ProgressProvider(storage);
    final settings = SettingsProvider(storage);
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(),
    );

    await tester.pumpWidget(
      _wrap(
        exercises: exercises,
        progress: progress,
        settings: settings,
        workout: workout,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('80 kg × 8'), findsOneWidget);
    expect(find.text('Estimated 1RM 100 kg'), findsOneWidget);
    expect(find.text('Nov 1, 2026'), findsOneWidget);
    expect(find.text('First time? Log a set to start tracking.'), findsNothing);
  });

  testWidgets('add to current workout appends the exercise directly', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
      clock: FakeClock(_now),
    );
    await exercises.load();
    final progress = ProgressProvider(storage);
    final settings = SettingsProvider(storage);
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(),
    );
    await workout.startEmpty();

    await tester.pumpWidget(
      _wrap(
        exercises: exercises,
        progress: progress,
        settings: settings,
        workout: workout,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('exercise-action-primary')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(workout.activeSession?.exercises, hasLength(1));
    expect(
      workout.activeSession?.exercises.single.exerciseId,
      'barbell-bench-press',
    );
    expect(find.text('Added Barbell Bench Press.'), findsOneWidget);
  });

  testWidgets('start workout with this exercise starts and adds it', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
      clock: FakeClock(_now),
    );
    await exercises.load();
    final progress = ProgressProvider(storage);
    final settings = SettingsProvider(storage);
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(),
    );

    await tester.pumpWidget(
      _wrap(
        exercises: exercises,
        progress: progress,
        settings: settings,
        workout: workout,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('exercise-action-primary')));
    await tester.pumpAndSettle();

    expect(workout.activeSession, isNotNull);
    expect(
      workout.activeSession?.exercises.single.exerciseId,
      'barbell-bench-press',
    );
    expect(find.byKey(const Key('logger-stub')), findsOneWidget);
  });

  testWidgets('already logged exercise offers view in workout', (tester) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
      clock: FakeClock(_now),
    );
    await exercises.load();
    final progress = ProgressProvider(storage);
    final settings = SettingsProvider(storage);
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(),
    );
    await workout.startEmpty();
    await workout.addExercise('barbell-bench-press');

    await tester.pumpWidget(
      _wrap(
        exercises: exercises,
        progress: progress,
        settings: settings,
        workout: workout,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Already in workout'), findsOneWidget);
    expect(
      find.widgetWithText(AppButton, 'View in workout'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(AppButton, 'Add to current workout'),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('exercise-action-primary')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logger-stub')), findsOneWidget);
  });

  testWidgets('view history opens the recent sets sheet', (tester) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
      clock: FakeClock(_now),
    );
    await exercises.load();
    final progress = ProgressProvider(storage);
    final settings = SettingsProvider(storage);
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(),
    );

    await tester.pumpWidget(
      _wrap(
        exercises: exercises,
        progress: progress,
        settings: settings,
        workout: workout,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('exercise-action-history')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exercise-history-sheet')), findsOneWidget);
    expect(
      find.text('No sets logged yet. Finish a workout to see history.'),
      findsOneWidget,
    );
  });

  testWidgets('an unknown exercise id shows the not found state', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
      clock: FakeClock(_now),
    );
    await exercises.load();
    final progress = ProgressProvider(storage);
    final settings = SettingsProvider(storage);
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(),
    );

    await tester.pumpWidget(
      _wrap(
        exercises: exercises,
        progress: progress,
        settings: settings,
        workout: workout,
        exerciseId: 'missing-exercise',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Exercise not found'), findsOneWidget);
  });
}
