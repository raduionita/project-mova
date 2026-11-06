import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/screens/progress/progress_screen.dart';
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
      ChangeNotifierProvider<ExerciseProvider>(
        create: (_) => ExerciseProvider(
          storage,
          SeedDataService(bundle: _FakeBundle()),
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

    expect(find.text('No workouts yet'), findsOneWidget);
    expect(
      find.text('Finish a workout to see your progress here.'),
      findsOneWidget,
    );
    expect(find.text('Start your first workout'), findsOneWidget);
    expect(find.text('Strength score'), findsNothing);
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
}
