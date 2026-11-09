import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/routine_exercise.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/routine_provider.dart';
import 'package:mova/screens/train/routine_builder_screen.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/widgets/app_button.dart';
import 'package:mova/widgets/exercise_picker_sheet.dart';
import 'package:provider/provider.dart';

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

  Routine buildRoutine() {
    return Routine(
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
    Widget child,
  ) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RoutineProvider>.value(value: routines),
        ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: child),
    );
  }

  testWidgets('the builder validates an empty routine', (tester) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    final exercises = await buildExercises(storage);

    await tester.pumpWidget(
      wrap(routines, exercises, const RoutineBuilderScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('New routine'), findsOneWidget);
    expect(find.text('No exercises yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Save routine'));
    await tester.pump();

    expect(find.text('Name your routine.'), findsOneWidget);
    expect(find.text('Add at least one exercise.'), findsOneWidget);
    expect(routines.routines, isEmpty);
  });

  testWidgets('the builder adds exercises, edits sets, and saves', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    final exercises = await buildExercises(storage);

    await tester.pumpWidget(
      wrap(
        routines,
        exercises,
        _BuilderLauncher(idService: IdService(generator: _fixedId)),
      ),
    );
    await tester.tap(find.text('Open builder'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Push day');
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();

    expect(find.text('Add to routine'), findsWidgets);
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Add to routine'));
    await tester.pumpAndSettle();

    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('3 sets · 8-12 reps'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase Sets'));
    await tester.pump();
    expect(find.text('4 sets · 8-12 reps'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Save routine'));
    await tester.pumpAndSettle();

    expect(find.text('Open builder'), findsOneWidget);
    expect(routines.routines, hasLength(1));
    final routine = routines.routines.single;
    expect(routine.id, 'routine-test');
    expect(routine.name, 'Push day');
    expect(routine.exercises.single.exerciseId, 'barbell-bench-press');
    expect(routine.exercises.single.sets, 4);
    expect(routine.exercises.single.order, 0);
  });

  testWidgets('the builder removes an exercise', (tester) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    final exercises = await buildExercises(storage);

    await tester.pumpWidget(
      wrap(
        routines,
        exercises,
        _BuilderLauncher(idService: IdService(generator: _fixedId)),
      ),
    );
    await tester.tap(find.text('Open builder'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Add to routine'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove Barbell Bench Press'));
    await tester.pumpAndSettle();

    expect(find.text('No exercises yet'), findsOneWidget);
  });

  testWidgets('the builder reorders exercises and saves the new order', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    final exercises = await buildExercises(storage);

    await tester.pumpWidget(
      wrap(
        routines,
        exercises,
        _BuilderLauncher(idService: IdService(generator: _fixedId)),
      ),
    );
    await tester.tap(find.text('Open builder'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Upper');
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(ExercisePickerSheet),
        matching: find.byType(TextField),
      ),
      'fly',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dumbbell Fly'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Add to routine'));
    await tester.pumpAndSettle();

    final bench = tester.getTopLeft(find.text('Barbell Bench Press')).dy;
    final fly = tester.getTopLeft(find.text('Dumbbell Fly')).dy;
    expect(bench, lessThan(fly));

    final handle = _assetIcon(AppIcons.drag).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveTo(tester.getCenter(find.text('Dumbbell Fly')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final movedFly = tester.getTopLeft(find.text('Dumbbell Fly')).dy;
    final movedBench = tester.getTopLeft(find.text('Barbell Bench Press')).dy;
    expect(movedFly, lessThan(movedBench));

    await tester.tap(find.widgetWithText(AppButton, 'Save routine'));
    await tester.pumpAndSettle();

    final routine = routines.routines.single;
    expect(routine.exercises.map((exercise) => exercise.exerciseId), <String>[
      'dumbbell-fly',
      'barbell-bench-press',
    ]);
    expect(routine.exercises.first.order, 0);
    expect(routine.exercises.last.order, 1);
  });

  testWidgets('editing an existing routine prefills and saves the same id', (
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
        _BuilderLauncher(
          routineId: 'routine-1',
          idService: IdService(generator: _fixedId),
        ),
      ),
    );
    await tester.tap(find.text('Open builder'));
    await tester.pumpAndSettle();

    expect(find.text('Edit routine'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Push day');
    expect(find.text('3 sets · 8-10 reps'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Push day v2');
    await tester.tap(find.widgetWithText(AppButton, 'Save routine'));
    await tester.pumpAndSettle();

    expect(find.text('Open builder'), findsOneWidget);
    expect(routines.routines, hasLength(1));
    expect(routines.routines.single.id, 'routine-1');
    expect(routines.routines.single.name, 'Push day v2');
  });

  testWidgets('unsaved changes ask before discarding', (tester) async {
    final storage = StorageService.inMemory();
    final routines = RoutineProvider(storage);
    final exercises = await buildExercises(storage);

    await tester.pumpWidget(
      wrap(
        routines,
        exercises,
        _BuilderLauncher(idService: IdService(generator: _fixedId)),
      ),
    );
    await tester.tap(find.text('Open builder'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Draft');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('New routine'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Open builder'), findsOneWidget);
    expect(routines.routines, isEmpty);
  });
}

String _fixedId() => 'routine-test';

/// Serves a preloaded library so widget tests never load assets inside a
/// `testWidgets` body.
class _StaticSeedDataService extends SeedDataService {
  _StaticSeedDataService(this._exercises);

  final List<Exercise> _exercises;

  @override
  Future<List<Exercise>> loadExercises() async => _exercises;
}

class _BuilderLauncher extends StatelessWidget {
  const _BuilderLauncher({this.routineId, required this.idService});

  final String? routineId;
  final IdService idService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => RoutineBuilderScreen(
                routineId: routineId,
                idService: idService,
              ),
            ),
          ),
          child: const Text('Open builder'),
        ),
      ),
    );
  }
}
