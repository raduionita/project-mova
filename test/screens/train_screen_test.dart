import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/routine_exercise.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/routine_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/screens/train/train_screen.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/widgets/exercise_row.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime.utc(2026, 11, 6, 12);

/// Serves a preloaded library so widget tests never load assets inside a
/// `testWidgets` body.
class _StaticSeedDataService extends SeedDataService {
  _StaticSeedDataService(this._exercises);

  final List<Exercise> _exercises;

  @override
  Future<List<Exercise>> loadExercises() async => _exercises;
}

class _EmptySeedDataService extends SeedDataService {
  @override
  Future<List<Exercise>> loadExercises() async => const <Exercise>[];
}

IdGenerator _sequentialIds() {
  var counter = 0;
  return () => 'id-${++counter}';
}

Widget _wrap(
  ExerciseProvider exercises,
  WorkoutProvider workout, {
  RoutineProvider? routines,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
      ChangeNotifierProvider<WorkoutProvider>.value(value: workout),
      ChangeNotifierProvider<RoutineProvider>.value(
        value: routines ?? RoutineProvider(StorageService.inMemory()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.dark, home: const TrainScreen()),
  );
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

  testWidgets('lists the local exercise library with row details', (
    tester,
  ) async {
    expect(library.length, greaterThanOrEqualTo(60));
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
    );
    await exercises.load();
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(generator: _sequentialIds()),
    );

    await tester.pumpWidget(_wrap(exercises, workout));
    await tester.pump();

    expect(
      find.text('${exercises.exercises.length} exercises'),
      findsOneWidget,
    );
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ExerciseRow).first,
        matching: find.text('Chest · Barbell'),
      ),
      findsOneWidget,
    );
    expect(find.byType(ExerciseRow), findsWidgets);
    expect(_assetIcon(AppIcons.plus), findsWidgets);
  });

  testWidgets('add without an active workout explains how to start', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
    );
    await exercises.load();
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(generator: _sequentialIds()),
    );

    await tester.pumpWidget(_wrap(exercises, workout));
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(ExerciseRow).first,
        matching: _assetIcon(AppIcons.plus),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(workout.activeSession, isNull);
    expect(
      find.text('Start a workout to add Barbell Bench Press.'),
      findsOneWidget,
    );
  });

  testWidgets('add appends the exercise to the active workout', (tester) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
    );
    await exercises.load();
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(generator: _sequentialIds()),
    );
    await workout.startEmpty();

    await tester.pumpWidget(_wrap(exercises, workout));
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(ExerciseRow).first,
        matching: _assetIcon(AppIcons.plus),
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

  testWidgets('search narrows the library and announces the result count', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
    );
    await exercises.load();
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(generator: _sequentialIds()),
    );

    await tester.pumpWidget(_wrap(exercises, workout));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'bench');
    await tester.pump();

    expect(find.text('5 exercises'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Dumbbell Fly'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(find.text('${library.length} exercises'), findsOneWidget);
  });

  testWidgets('muscle chips filter and combine with search', (tester) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
    );
    await exercises.load();
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(generator: _sequentialIds()),
    );

    await tester.pumpWidget(_wrap(exercises, workout));
    await tester.pump();

    await tester.tap(find.text('Chest'));
    await tester.pump();
    expect(find.text('10 exercises'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'press');
    await tester.pump();
    expect(find.text('5 exercises'), findsOneWidget);
    expect(find.text('Dumbbell Fly'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pump();
    expect(find.text('Chest · Barbell'), findsWidgets);
  });

  testWidgets('an unmatched search offers to clear the filters', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
    );
    await exercises.load();
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(generator: _sequentialIds()),
    );

    await tester.pumpWidget(_wrap(exercises, workout));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();

    expect(find.text('No exercises found'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pump();

    expect(find.text('${library.length} exercises'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
  });

  testWidgets('shows saved routines in the My routines section', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(
      storage,
      _StaticSeedDataService(library),
    );
    await exercises.load();
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(generator: _sequentialIds()),
    );
    final routines = RoutineProvider(storage);
    await routines.load();
    await routines.save(
      Routine(
        id: 'routine-1',
        name: 'Push day',
        exercises: const <RoutineExercise>[
          RoutineExercise(
            exerciseId: 'barbell-bench-press',
            sets: 3,
            repsLow: 8,
            repsHigh: 10,
            restSeconds: 90,
            order: 0,
          ),
        ],
        createdAt: _now,
        updatedAt: _now,
      ),
    );

    await tester.pumpWidget(_wrap(exercises, workout, routines: routines));
    await tester.pump();

    expect(find.text('My routines'), findsOneWidget);
    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
  });

  testWidgets('an empty library renders its empty state', (tester) async {
    final storage = StorageService.inMemory();
    final exercises = ExerciseProvider(storage, _EmptySeedDataService());
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(_now),
      idService: IdService(generator: _sequentialIds()),
    );

    await tester.pumpWidget(_wrap(exercises, workout));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('No exercises yet'), findsOneWidget);
    expect(find.text('Reload library'), findsOneWidget);
  });
}
