import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app_coordinator.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/screens/progress/history_detail_screen.dart';
import 'package:mova/screens/progress/history_screen.dart';
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

WorkoutSession _session({
  required String id,
  required String name,
  required DateTime date,
  required double weightKg,
  String notes = '',
}) {
  return WorkoutSession(
    id: id,
    name: name,
    source: SessionSource.empty,
    startedAt: date.subtract(const Duration(minutes: 40)),
    completedAt: date,
    status: SessionStatus.completed,
    notes: notes,
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'exercise-$id',
        exerciseId: 'barbell-bench-press',
        order: 0,
        notes: 'Elbows tucked.',
        sets: <WorkoutSet>[
          WorkoutSet(
            id: 'set-$id-1',
            index: 0,
            weightKg: weightKg,
            reps: 5,
            completed: true,
            completedAt: date,
          ),
          WorkoutSet(
            id: 'set-$id-2',
            index: 1,
            weightKg: weightKg + 5,
            reps: 5,
            completed: true,
            completedAt: date,
          ),
        ],
      ),
    ],
  );
}

PersonalRecord _record(String sessionId, double bestE1rmKg) {
  return PersonalRecord(
    exerciseId: 'barbell-bench-press',
    bestE1rmKg: bestE1rmKg,
    weightKg: 100,
    reps: 5,
    achievedAt: _now,
    sessionId: sessionId,
    previousBestKg: 0,
  );
}

class _Harness {
  _Harness(this.storage)
    : history = HistoryProvider(storage),
      progress = ProgressProvider(storage, clock: _clock),
      profile = ProfileProvider(storage, clock: _clock),
      settings = SettingsProvider(storage),
      exercises = ExerciseProvider(
        storage,
        SeedDataService(bundle: _FakeBundle()),
        clock: _clock,
      ),
      plan = PlanProvider(
        storage,
        loadExercises: () async => const [],
        clock: _clock,
      ),
      onboarding = OnboardingProvider(storage, clock: _clock);

  final StorageService storage;
  final HistoryProvider history;
  final ProgressProvider progress;
  final ProfileProvider profile;
  final SettingsProvider settings;
  final ExerciseProvider exercises;
  final PlanProvider plan;
  final OnboardingProvider onboarding;

  AppCoordinator get coordinator => AppCoordinator(
    storage: storage,
    profileProvider: profile,
    settingsProvider: settings,
    planProvider: plan,
    onboardingProvider: onboarding,
    historyProvider: history,
    progressProvider: progress,
    clock: _clock,
  );

  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      history.load(),
      progress.load(),
      profile.load(),
      settings.load(),
      exercises.load(),
    ]);
  }

  Widget wrap(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HistoryProvider>.value(value: history),
        ChangeNotifierProvider<ProgressProvider>.value(value: progress),
        ChangeNotifierProvider<ProfileProvider>.value(value: profile),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
        ChangeNotifierProvider<PlanProvider>.value(value: plan),
        ChangeNotifierProvider<OnboardingProvider>.value(value: onboarding),
        Provider<AppCoordinator>.value(value: coordinator),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: home),
    );
  }
}

Future<_Harness> _historyHarness() async {
  final storage = StorageService.inMemory();
  await storage.writeList(kWorkoutsKey, <Map<String, dynamic>>[
    _session(
      id: 'november',
      name: 'November Push',
      date: DateTime(2026, 11, 6, 18),
      weightKg: 100,
      notes: 'Felt strong on the last set.',
    ).toJson(),
    _session(
      id: 'october',
      name: 'October Pull',
      date: DateTime(2026, 10, 15, 18),
      weightKg: 90,
    ).toJson(),
  ]);
  await storage.writeObject(
    kProfileKey,
    UserProfile(
      id: 'profile-1',
      bodyWeightKg: 80,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: _now,
    ).toJson(),
  );
  final harness = _Harness(storage);
  await harness.load();
  return harness;
}

Future<_Harness> _deletionHarness() async {
  final storage = StorageService.inMemory();
  final older = _session(
    id: 'older',
    name: 'Older Push',
    date: DateTime(2026, 11, 1, 18),
    weightKg: 80,
  );
  final newer = _session(
    id: 'newer',
    name: 'Newer Push',
    date: DateTime(2026, 11, 6, 18),
    weightKg: 100,
    notes: 'Felt strong.',
  );
  await storage.writeList(kWorkoutsKey, <Map<String, dynamic>>[
    newer.toJson(),
    older.toJson(),
  ]);
  await storage.writeMap(kPrsKey, <String, Map<String, dynamic>>{
    'barbell-bench-press': _record('newer', 128.33).toJson(),
  });
  await storage.writeObject(
    kProfileKey,
    UserProfile(
      id: 'profile-1',
      bodyWeightKg: 80,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: _now,
    ).toJson(),
  );
  final harness = _Harness(storage);
  await harness.load();
  return harness;
}

void main() {
  testWidgets('history groups workouts by month', (tester) async {
    final harness = await _historyHarness();
    await tester.pumpWidget(harness.wrap(const HistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Workout history'), findsOneWidget);
    expect(find.text('2 completed workouts'), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('November Push'), findsOneWidget);
    expect(find.text('October Pull'), findsOneWidget);
  });

  testWidgets('history shows an empty state', (tester) async {
    final harness = _Harness(StorageService.inMemory());
    await harness.load();
    await tester.pumpWidget(harness.wrap(const HistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No workouts yet'), findsOneWidget);
    expect(find.text('Start your first workout'), findsOneWidget);
  });

  testWidgets('detail shows exercises, sets, notes, and date', (tester) async {
    final harness = await _historyHarness();
    await tester.pumpWidget(
      harness.wrap(const HistoryDetailScreen(sessionId: 'november')),
    );
    await tester.pumpAndSettle();

    expect(find.text('November Push'), findsOneWidget);
    expect(find.text('Nov 6, 2026'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('100 kg × 5'), findsOneWidget);
    expect(find.text('105 kg × 5'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Felt strong on the last set.'), findsOneWidget);
  });

  testWidgets('deleting a workout rebuilds PRs and the streak', (tester) async {
    final harness = await _deletionHarness();
    await tester.pumpWidget(
      harness.wrap(const HistoryDetailScreen(sessionId: 'newer')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete workout'));
    await tester.pumpAndSettle();
    expect(find.text('Delete workout?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(harness.history.workouts, hasLength(1));
    expect(harness.history.workouts.single.id, 'older');
    expect(harness.progress.totalWorkouts, 1);
    expect(harness.progress.streak, 0);
    final stored = harness.storage.readMap<PersonalRecord>(
      kPrsKey,
      PersonalRecord.fromJson,
    );
    expect(
      stored['barbell-bench-press']!.bestE1rmKg,
      closeTo(85 * (1 + 5 / 30), 0.0001),
    );
  });
}
