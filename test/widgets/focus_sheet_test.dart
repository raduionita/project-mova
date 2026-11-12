import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_chip.dart';
import 'package:mova/widgets/focus_sheet.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime.utc(2026, 11, 12, 9);

Widget _host({
  required ExerciseProvider exercises,
  required WorkoutProvider workout,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
      ChangeNotifierProvider<WorkoutProvider>.value(value: workout),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('open-focus'),
              onPressed: () => showFocusSheet(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> library;

  setUpAll(() async {
    library = await SeedDataService().loadExercises();
  });

  Future<(ExerciseProvider, WorkoutProvider)> pumpFocus(
    WidgetTester tester,
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
    await workout.startEmpty();

    await tester.pumpWidget(_host(exercises: exercises, workout: workout));
    await tester.tap(find.byKey(const Key('open-focus')));
    await tester.pumpAndSettle();
    return (exercises, workout);
  }

  testWidgets('shows every focus chip and the default suggestions', (
    tester,
  ) async {
    await pumpFocus(tester);

    expect(find.byKey(const Key('focus-sheet')), findsOneWidget);
    expect(find.text('Choose a focus'), findsOneWidget);
    expect(find.text('All suggestions'), findsOneWidget);
    expect(find.byType(AppChip), findsNWidgets(12));
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Full body'), findsOneWidget);
    expect(find.text('Core'), findsOneWidget);
    expect(find.byKey(const Key('focus-browse')), findsOneWidget);
    expect(find.byKey(const Key('focus-done')), findsOneWidget);

    final actions = tester.widgetList<AppChip>(find.byType(AppChip));
    expect(actions.where((chip) => chip.selected), hasLength(1));
    expect(
      actions.singleWhere((chip) => chip.selected).label,
      'All',
    );
    expect(
      find.byKey(const Key('focus-suggestion-barbell-bench-press')),
      findsOneWidget,
    );
  });

  testWidgets('filters suggestions by the selected focus', (tester) async {
    await pumpFocus(tester);

    await tester.tap(find.byKey(const Key('focus-option-chest')));
    await tester.pumpAndSettle();

    expect(find.text('Chest suggestions'), findsOneWidget);
    expect(
      find.byKey(const Key('focus-suggestion-barbell-bench-press')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('focus-suggestion-barbell-row')),
      findsNothing,
    );

    final chips = tester.widgetList<AppChip>(find.byType(AppChip));
    final selected = chips.singleWhere((chip) => chip.selected);
    expect(selected.label, 'Chest');
  });

  testWidgets('adds a suggestion to the empty workout', (tester) async {
    final (_, workout) = await pumpFocus(tester);

    await tester.tap(
      find.byKey(const Key('focus-add-barbell-bench-press')),
    );
    await tester.pumpAndSettle();

    expect(workout.activeSession!.exercises, hasLength(1));
    expect(
      workout.activeSession!.exercises.single.exerciseId,
      'barbell-bench-press',
    );
    expect(find.text('Added Barbell Bench Press.'), findsOneWidget);
    expect(
      find.byKey(const Key('focus-suggestion-barbell-bench-press')),
      findsNothing,
    );
  });

  testWidgets('browse opens the exercise picker with the focus applied', (
    tester,
  ) async {
    final (_, workout) = await pumpFocus(tester);

    await tester.tap(find.byKey(const Key('focus-option-chest')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('focus-browse')));
    await tester.pumpAndSettle();

    expect(find.text('Add exercise'), findsOneWidget);
    expect(workout.activeSession!.exercises, isEmpty);
    expect(find.byKey(const Key('exercise-filter-focus')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('exercise-filter-focus')),
        matching: find.text('Chest'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('done closes the drawer', (tester) async {
    await pumpFocus(tester);

    await tester.tap(find.byKey(const Key('focus-done')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('focus-sheet')), findsNothing);
    expect(find.byKey(const Key('open-focus')), findsOneWidget);
  });
}

IdGenerator _sequentialIds() {
  var counter = 0;
  return () => 'id-${++counter}';
}

class _StaticSeedDataService extends SeedDataService {
  _StaticSeedDataService(this._exercises);

  final List<Exercise> _exercises;

  @override
  Future<List<Exercise>> loadExercises() async => _exercises;
}
