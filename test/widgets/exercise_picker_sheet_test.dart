import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_button.dart';
import 'package:mova/widgets/exercise_picker_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> library;

  setUpAll(() async {
    library = await SeedDataService().loadExercises();
  });

  Future<ExerciseProvider> buildExercises(StorageService storage) async {
    final provider = ExerciseProvider(storage, _StaticSeedDataService(library));
    await provider.load();
    return provider;
  }

  testWidgets('browse mode searches, filters, and returns one exercise', (
    tester,
  ) async {
    final exercises = await buildExercises(StorageService.inMemory());
    ExercisePickerResult? result;
    await tester.pumpWidget(
      ChangeNotifierProvider<ExerciseProvider>.value(
        value: exercises,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () async {
                      result = await showExercisePicker(context);
                    },
                    child: const Text('Open picker'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    expect(find.text('Choose exercise'), findsOneWidget);
    expect(find.text('${library.length} exercises'), findsOneWidget);

    await tester.tap(find.text('Chest'));
    await tester.pump();
    expect(find.text('10 exercises'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bench');
    await tester.pump();
    expect(find.text('3 exercises'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Dumbbell Fly'), findsNothing);

    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pump();
    final select = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Select exercise'),
    );
    expect(select.onPressed, isNotNull);

    await tester.tap(find.text('Select exercise'));
    await tester.pumpAndSettle();
    expect(result?.exercises.single.id, 'barbell-bench-press');
  });

  testWidgets('session mode multi-selects and labels the workout action', (
    tester,
  ) async {
    final exercises = await buildExercises(StorageService.inMemory());
    ExercisePickerResult? result;
    await tester.pumpWidget(
      ChangeNotifierProvider<ExerciseProvider>.value(
        value: exercises,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () async {
                      result = await showExercisePicker(
                        context,
                        mode: ExercisePickerMode.session,
                        multiSelect: true,
                      );
                    },
                    child: const Text('Open picker'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    expect(find.text('Add exercise'), findsOneWidget);

    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pump();
    await tester.tap(find.text('Incline Barbell Bench Press'));
    await tester.pump();

    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Add to workout'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Add to workout'));
    await tester.pumpAndSettle();
    expect(result?.exercises, hasLength(2));
    expect(
      result?.exercises.map((exercise) => exercise.id),
      containsAll(<String>[
        'barbell-bench-press',
        'incline-barbell-bench-press',
      ]),
    );
  });

  testWidgets('routine mode uses an initial selection and routine action', (
    tester,
  ) async {
    final exercises = await buildExercises(StorageService.inMemory());
    ExercisePickerResult? result;
    await tester.pumpWidget(
      ChangeNotifierProvider<ExerciseProvider>.value(
        value: exercises,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: TextButton(
                    onPressed: () async {
                      result = await showExercisePicker(
                        context,
                        mode: ExercisePickerMode.routine,
                        initialExerciseIds: const <String>{
                          'barbell-bench-press',
                        },
                      );
                    },
                    child: const Text('Open picker'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();

    expect(find.text('Add to routine'), findsNWidgets(2));
    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Add to routine'),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(AppButton, 'Add to routine'));
    await tester.pumpAndSettle();
    expect(result?.exercises.single.id, 'barbell-bench-press');
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
