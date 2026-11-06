import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/routine_exercise.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/routine_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/screens/train/routine_builder_screen.dart';
import 'package:mova/screens/train/routine_detail_screen.dart';
import 'package:mova/screens/train/routine_list_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_button.dart';
import 'package:mova/widgets/routine_row.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> library;

  setUpAll(() async {
    library = await SeedDataService().loadExercises();
  });

  final now = DateTime.utc(2026, 11, 6, 12);

  Routine buildRoutine() {
    return Routine(
      id: 'routine-1',
      name: 'Push day',
      exercises: const <RoutineExercise>[
        RoutineExercise(
          exerciseId: 'dumbbell-fly',
          sets: 4,
          repsLow: 12,
          repsHigh: 12,
          restSeconds: 60,
          order: 1,
        ),
        RoutineExercise(
          exerciseId: 'barbell-bench-press',
          sets: 3,
          repsLow: 8,
          repsHigh: 10,
          restSeconds: 90,
          order: 0,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<ExerciseProvider> buildExercises(StorageService storage) async {
    final provider = ExerciseProvider(storage, _StaticSeedDataService(library));
    await provider.load();
    return provider;
  }

  Widget wrap(
    RoutineProvider routines,
    ExerciseProvider exercises,
    Widget child, {
    RouteFactory? onGenerateRoute,
    WorkoutProvider? workout,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RoutineProvider>.value(value: routines),
        ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
        ChangeNotifierProvider<WorkoutProvider>.value(
          value:
              workout ??
              WorkoutProvider(
                StorageService.inMemory(),
                clock: FakeClock(now),
                idService: IdService(generator: () => 'session-test'),
              ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: child,
        onGenerateRoute: onGenerateRoute,
      ),
    );
  }

  testWidgets('an empty routine list shows its empty state', (tester) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    final exercises = await buildExercises(storage);

    await tester.pumpWidget(
      wrap(
        routines,
        exercises,
        const RoutineListScreen(),
        onGenerateRoute: (settings) {
          if (settings.name != Routes.routineNew) {
            return null;
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => RoutineBuilderScreen(
              idService: IdService(generator: () => 'routine-test'),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Routines'), findsOneWidget);
    expect(find.text('No routines yet'), findsOneWidget);
    expect(find.text('0 saved routines'), findsOneWidget);

    await tester.tap(find.text('Create routine'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineBuilderScreen), findsOneWidget);
    expect(find.text('New routine'), findsOneWidget);
  });

  testWidgets('the list shows routines and opens the detail route', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    await routines.load();
    await routines.save(buildRoutine());
    final exercises = await buildExercises(storage);

    await tester.pumpWidget(
      wrap(
        routines,
        exercises,
        const RoutineListScreen(),
        onGenerateRoute: (settings) {
          final id = Routes.routineIdFromRoute(settings.name);
          if (id == null) {
            return null;
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => RoutineDetailScreen(routineId: id),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('2 exercises'), findsOneWidget);
    expect(find.byType(RoutineRow), findsOneWidget);

    await tester.tap(find.byType(RoutineRow));
    await tester.pumpAndSettle();

    expect(find.byType(RoutineDetailScreen), findsOneWidget);
    expect(find.text('Push day'), findsOneWidget);
  });

  testWidgets('detail orders exercises, shows sets and reps, and deletes', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    await routines.load();
    await routines.save(buildRoutine());
    final exercises = await buildExercises(storage);

    await tester.pumpWidget(
      wrap(
        routines,
        exercises,
        const _DetailLauncher(routineId: 'routine-1'),
        onGenerateRoute: (settings) {
          final id = Routes.routineEditIdFromRoute(settings.name);
          if (id == null) {
            return null;
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => RoutineBuilderScreen(
              routineId: id,
              idService: IdService(generator: () => 'routine-test'),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('Open routine'));
    await tester.pumpAndSettle();

    expect(find.text('Push day'), findsOneWidget);
    expect(find.text('2 exercises'), findsOneWidget);
    expect(find.text('3 sets · 8-10 reps · Rest 90s'), findsOneWidget);
    expect(find.text('4 sets · 12 reps · Rest 60s'), findsOneWidget);

    final bench = tester.getTopLeft(find.text('Barbell Bench Press')).dy;
    final fly = tester.getTopLeft(find.text('Dumbbell Fly')).dy;
    expect(bench, lessThan(fly));

    final start = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Start now'),
    );
    final edit = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Edit routine'),
    );
    expect(start.onPressed, isNotNull);
    expect(edit.onPressed, isNotNull);

    await tester.tap(find.text('Edit routine'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineBuilderScreen), findsOneWidget);
    expect(find.text('Edit routine'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailScreen), findsOneWidget);

    await tester.tap(find.text('Delete routine'));
    await tester.pumpAndSettle();
    expect(find.text('Delete routine?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(routines.routines, hasLength(1));
    expect(find.byType(RoutineDetailScreen), findsOneWidget);

    await tester.tap(find.text('Delete routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(routines.routines, isEmpty);
    expect(find.text('Open routine'), findsOneWidget);
  });

  testWidgets('starting a routine creates a session and opens the logger', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    await routines.load();
    await routines.save(buildRoutine());
    final exercises = await buildExercises(storage);
    final workout = WorkoutProvider(
      storage,
      clock: FakeClock(now),
      idService: IdService(generator: () => 'session-test'),
    );

    await tester.pumpWidget(
      wrap(
        routines,
        exercises,
        const _DetailLauncher(routineId: 'routine-1'),
        workout: workout,
        onGenerateRoute: (settings) {
          if (settings.name != Routes.logger) {
            return null;
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                const Scaffold(body: Center(child: Text('Logger placeholder'))),
          );
        },
      ),
    );
    await tester.tap(find.text('Open routine'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start now'));
    await tester.pumpAndSettle();

    final session = workout.activeSession;
    expect(session, isNotNull);
    expect(session!.source, SessionSource.routine);
    expect(session.routineId, 'routine-1');
    expect(session.name, 'Push day');
    expect(session.exercises, hasLength(2));
    expect(session.exercises.first.exerciseId, 'barbell-bench-press');
    expect(session.exercises.first.sets, hasLength(3));
    expect(find.text('Logger placeholder'), findsOneWidget);
  });

  testWidgets('a missing routine shows a not-found state', (tester) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    await routines.load();
    final exercises = await buildExercises(storage);

    await tester.pumpWidget(
      wrap(
        routines,
        exercises,
        const RoutineDetailScreen(routineId: 'missing'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Routine not found'), findsOneWidget);
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

class _DetailLauncher extends StatelessWidget {
  const _DetailLauncher({required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RoutineDetailScreen(routineId: routineId),
            ),
          ),
          child: const Text('Open routine'),
        ),
      ),
    );
  }
}
