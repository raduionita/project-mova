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
import 'package:mova/widgets/exercise_picker_sheet.dart';
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

    final add = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Add to workout'),
    );
    expect(add.onPressed, isNull);
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

  testWidgets('add to workout opens the picker and adds the exercise', (
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

    await tester.tap(find.widgetWithText(AppButton, 'Add to workout'));
    await tester.pumpAndSettle();

    expect(find.byType(ExercisePickerSheet), findsOneWidget);
    expect(find.text('Add exercise'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ExercisePickerSheet),
        matching: find.text('Barbell Bench Press'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(ExercisePickerSheet),
        matching: find.widgetWithText(AppButton, 'Add to workout'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(workout.activeSession?.exercises, hasLength(1));
    expect(
      workout.activeSession?.exercises.single.exerciseId,
      'barbell-bench-press',
    );
    expect(find.text('Added Barbell Bench Press.'), findsOneWidget);
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
