import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/wellness_entry.dart';
import 'package:mova/models/weight_entry.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/weight_provider.dart';
import 'package:mova/providers/wellness_provider.dart';
import 'package:mova/screens/progress/progress_screen.dart';
import 'package:mova/widgets/progress_placeholder_card.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
final FakeClock _clock = FakeClock(_now);

const String _exerciseJson = '''
[
  {
    "id": "back-squat",
    "name": "Back Squat",
    "primaryMuscle": "Quads",
    "secondaryMuscles": ["Glutes"],
    "equipment": "Barbell",
    "instructions": ["Squat down."],
    "isCompound": true
  },
  {
    "id": "barbell-bench-press",
    "name": "Barbell Bench Press",
    "primaryMuscle": "Chest",
    "secondaryMuscles": ["Triceps"],
    "equipment": "Barbell",
    "instructions": ["Press the bar."],
    "isCompound": true
  }
]
''';

class _FakeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData(0);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return _exerciseJson;
  }
}

WorkoutSession _session(String id, int daysAgo) {
  final date = DateTime(_now.year, _now.month, _now.day - daysAgo, 18);
  return WorkoutSession(
    id: id,
    name: 'Workout $id',
    source: SessionSource.empty,
    startedAt: date.subtract(const Duration(minutes: 40)),
    completedAt: date,
    status: SessionStatus.completed,
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'exercise-$id',
        exerciseId: 'barbell-bench-press',
        order: 0,
        sets: <WorkoutSet>[
          WorkoutSet(
            id: 'set-$id',
            index: 0,
            weightKg: 100,
            reps: 5,
            completed: true,
            completedAt: date,
          ),
        ],
      ),
    ],
  );
}

PersonalRecord _record(String exerciseId, double bestE1rmKg) {
  return PersonalRecord(
    exerciseId: exerciseId,
    bestE1rmKg: bestE1rmKg,
    weightKg: bestE1rmKg / 1.1667,
    reps: 5,
    achievedAt: _now,
    sessionId: 'recent',
    previousBestKg: 0,
  );
}

Future<StorageService> _seededStorage({double bodyWeightKg = 80}) async {
  final storage = StorageService.inMemory();
  await storage.writeList(kWorkoutsKey, <Map<String, dynamic>>[
    _session('recent', 0).toJson(),
    _session('yesterday', 1).toJson(),
    _session('two-days', 2).toJson(),
  ]);
  await storage.writeMap(kPrsKey, <String, Map<String, dynamic>>{
    'back-squat': _record('back-squat', 160).toJson(),
    'barbell-bench-press': _record('barbell-bench-press', 120).toJson(),
  });
  await storage.writeObject(
    kProfileKey,
    UserProfile(
      id: 'profile-1',
      bodyWeightKg: bodyWeightKg,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: _now,
    ).toJson(),
  );
  return storage;
}

Widget _wrap(StorageService storage) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProgressProvider>(
        create: (_) => ProgressProvider(storage, clock: _clock),
      ),
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(storage, clock: _clock),
      ),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(storage),
      ),
      ChangeNotifierProvider<WeightProvider>(
        create: (_) => WeightProvider(storage, clock: _clock),
      ),
      ChangeNotifierProvider<ExerciseProvider>(
        create: (_) => ExerciseProvider(
          storage,
          SeedDataService(bundle: _FakeBundle()),
          clock: _clock,
        ),
      ),
      ChangeNotifierProvider<WellnessProvider>(
        create: (_) => WellnessProvider(storage, clock: _clock),
      ),
      ChangeNotifierProvider<PlanProvider>(
        create: (_) => PlanProvider(
          storage,
          loadExercises: () async => const <Exercise>[],
          clock: _clock,
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: ProgressScreen(clock: _clock),
    ),
  );
}

void main() {
  testWidgets('empty dashboard points at the first workout', (tester) async {
    await tester.pumpWidget(_wrap(StorageService.inMemory()));
    await tester.pumpAndSettle();

    expect(find.text('No workouts yet'), findsNothing);
    expect(find.text('Strength score'), findsOneWidget);
    expect(find.text('Weekly consistency'), findsOneWidget);
    expect(find.text('Weekly volume'), findsOneWidget);
    expect(find.text('Muscle balance'), findsOneWidget);
    expect(find.text('Personal records'), findsOneWidget);
    expect(find.text('Measurements'), findsOneWidget);
    expect(find.text('Progress photos'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Resting heart rate'), findsOneWidget);
    expect(find.byKey(const Key('progress-consistency-start')), findsOneWidget);
    expect(find.byKey(const Key('progress-pr-start')), findsOneWidget);
    expect(find.byType(ProgressPlaceholderCard), findsWidgets);
  });

  testWidgets('compact progress cards share one height', (tester) async {
    await tester.pumpWidget(_wrap(StorageService.inMemory()));
    await tester.pumpAndSettle();

    const keys = <Key>[
      Key('progress-measurements-card'),
      Key('progress-photos-card'),
      Key('progress-nutrition-card'),
      Key('progress-sleep-card'),
      Key('progress-rhr-card'),
    ];
    final heights = <double>[
      for (final key in keys) tester.getSize(find.byKey(key)).height,
    ];

    expect(heights.toSet().length, 1);
    expect(heights.first, 168);
  });

  testWidgets('dashboard shows hand-calculated lifetime metrics', (
    tester,
  ) async {
    final storage = await _seededStorage();
    await tester.pumpWidget(_wrap(storage));
    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('1.5 t'), findsWidgets);
    expect(find.text('1.5 t this week'), findsOneWidget);
    expect(find.text('Strength score'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('175'), findsOneWidget);
    expect(find.text('Personal records'), findsOneWidget);
    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('Workout history'), findsOneWidget);
    expect(find.text('Body weight'), findsOneWidget);
    expect(find.text('80 kg'), findsOneWidget);
    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.text('Target reached for this week.'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('progress-week-streak')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('score explanation avoids rankings', (tester) async {
    final storage = await _seededStorage();
    await tester.pumpWidget(_wrap(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('score-explanation')));
    await tester.pumpAndSettle();

    expect(find.text('How the score works'), findsOneWidget);
    expect(
      find.textContaining('no gym, global, or percentile ranking'),
      findsOneWidget,
    );
  });

  testWidgets('metrics info explains what every number counts', (
    tester,
  ) async {
    final storage = await _seededStorage();
    await tester.pumpWidget(_wrap(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('progress-metrics-info')));
    await tester.pumpAndSettle();

    expect(find.text('What counts'), findsOneWidget);
    expect(
      find.textContaining('Discarded or unfinished sessions never count'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Weight times reps for every completed set'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Consecutive days with at least one'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('What counts'), findsNothing);
  });

  testWidgets('missing body weight CTA saves weight and unlocks the score', (
    tester,
  ) async {
    final storage = await _seededStorage(bodyWeightKg: 0);
    await tester.pumpWidget(_wrap(storage));
    await tester.pumpAndSettle();

    expect(find.text('-'), findsWidgets);
    expect(find.text('Add body weight'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-body-weight')));
    await tester.pumpAndSettle();
    expect(find.text('Body weight'), findsWidgets);

    await tester.enterText(find.byKey(const Key('body-weight-field')), '80');
    await tester.pump();
    await tester.tap(find.text('Save body weight'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your body weight.'), findsNothing);

    final profile = storage.readObject<UserProfile>(
      kProfileKey,
      UserProfile.fromJson,
    );
    expect(profile?.bodyWeightKg, 80);
    expect(find.text('175'), findsOneWidget);
    expect(find.text('Add body weight'), findsNothing);
  });

  testWidgets('measurement quick add persists and updates the card', (
    tester,
  ) async {
    final storage = await _seededStorage();
    await tester.pumpWidget(_wrap(storage));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('progress-measurements-add')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress-measurements-add')));
    await tester.pumpAndSettle();

    expect(find.text('Measurements'), findsWidgets);
    expect(find.text('Waist (cm)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '82');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final entries = storage.readList<WellnessEntry>(
      kWellnessKey,
      WellnessEntry.fromJson,
    );
    expect(entries.single.waistCm, 82);
    expect(find.text('82.0 cm'), findsOneWidget);
  });

  testWidgets('nutrition quick add saves calories and protein', (tester) async {
    final storage = await _seededStorage();
    await tester.pumpWidget(_wrap(storage));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('progress-nutrition-add')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress-nutrition-add')));
    await tester.pumpAndSettle();

    expect(find.text('Calories'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '2100');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Protein (g)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '140');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final entries = storage.readList<WellnessEntry>(
      kWellnessKey,
      WellnessEntry.fromJson,
    );
    expect(entries.single.calories, 2100);
    expect(entries.single.proteinGrams, 140);
    expect(find.text('2100 kcal'), findsOneWidget);
  });

  testWidgets('quick add records weight and updates the card', (tester) async {
    final storage = await _seededStorage();
    await tester.pumpWidget(_wrap(storage));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('progress-add-weight')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('progress-add-weight')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('body-weight-field')), '79');
    await tester.tap(find.text('Save body weight'));
    await tester.pumpAndSettle();

    final entries = storage.readList<WeightEntry>(
      kWeightsKey,
      WeightEntry.fromJson,
    );
    expect(entries.single.weightKg, 79);
    expect(find.text('79 kg'), findsOneWidget);

    final profile = storage.readObject<UserProfile>(
      kProfileKey,
      UserProfile.fromJson,
    );
    expect(profile?.bodyWeightKg, 79);
  });
}
