import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app_coordinator.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/services/strength_score_service.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
final FakeClock _clock = FakeClock(_now);

WorkoutSession _session({
  required String id,
  required int daysAgo,
  double weightKg = 100,
}) {
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
            weightKg: weightKg,
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
    sessionId: 'session-0',
    previousBestKg: 0,
  );
}

Future<StorageService> _seededStorage({double bodyWeightKg = 80}) async {
  final storage = StorageService.inMemory();
  await storage.writeList(kWorkoutsKey, <Map<String, dynamic>>[
    _session(id: 'recent', daysAgo: 0).toJson(),
    _session(id: 'yesterday', daysAgo: 1).toJson(),
    _session(id: 'two-days', daysAgo: 2).toJson(),
    _session(id: 'old', daysAgo: 8).toJson(),
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

void main() {
  test('load aggregates totals, streak, volume, and score', () async {
    final storage = await _seededStorage();
    final provider = ProgressProvider(storage, clock: _clock);

    await provider.load();

    expect(provider.totalWorkouts, 4);
    expect(provider.totalVolumeKg, 2000);
    expect(provider.streak, 3);
    expect(provider.weeklyVolume.values.fold(0.0, (a, b) => a + b), 1500);
    expect(provider.weeklyVolume, hasLength(3));
    expect(provider.strengthScore, 175);
    expect(provider.scoreReason, isNull);
    expect(provider.recent, hasLength(4));
    expect(provider.recent.first.id, 'recent');
    expect(provider.prs, hasLength(2));
  });

  test('empty storage produces an empty dashboard without a score', () async {
    final provider = ProgressProvider(StorageService.inMemory(), clock: _clock);

    await provider.load();

    expect(provider.totalWorkouts, 0);
    expect(provider.totalVolumeKg, 0);
    expect(provider.streak, 0);
    expect(provider.weeklyVolume, isEmpty);
    expect(provider.strengthScore, isNull);
    expect(provider.scoreReason, isNotNull);
    expect(provider.prs, isEmpty);
  });

  test('replaceRecords clears deleted personal records', () async {
    final storage = await _seededStorage();
    final provider = ProgressProvider(storage, clock: _clock);
    await provider.load();

    expect(
      await provider.replaceRecords(const <String, PersonalRecord>{}),
      isTrue,
    );
    await provider.load();

    expect(provider.prs, isEmpty);
    expect(provider.strengthScore, isNull);
  });

  test('streak uses the injected clock and caps at profile creation', () async {
    final storage = await _seededStorage();
    await storage.writeObject(
      kProfileKey,
      UserProfile(
        id: 'profile-1',
        bodyWeightKg: 80,
        createdAt: DateTime(2026, 11, 5),
        updatedAt: _now,
      ).toJson(),
    );
    final provider = ProgressProvider(storage, clock: _clock);

    await provider.load();

    expect(provider.streak, 2);
  });

  test(
    'regenerating the plan leaves history, PRs, and streak intact',
    () async {
      final storage = await _seededStorage();
      final planProvider = PlanProvider(
        storage,
        loadExercises: () async => const <Exercise>[
          Exercise(
            id: 'back-squat',
            name: 'Back Squat',
            primaryMuscle: 'Quads',
            equipment: 'Barbell',
            isCompound: true,
          ),
          Exercise(
            id: 'barbell-bench-press',
            name: 'Barbell Bench Press',
            primaryMuscle: 'Chest',
            equipment: 'Barbell',
            isCompound: true,
          ),
        ],
        clock: _clock,
      );
      await planProvider.replacePlan(
        TrainingPlan(
          id: 'plan-1',
          goal: Goal.buildMuscle,
          goals: const <Goal>[Goal.buildMuscle],
          experienceLevel: ExperienceLevel.regular,
          daysPerWeek: 3,
          trainingDays: const <int>[1, 3, 5],
          splitName: 'Push pull legs',
          days: const <PlanDay>[],
          generatedAt: _now,
        ),
      );
      final progress = ProgressProvider(storage, clock: _clock);
      await progress.load();
      final beforeStreak = progress.streak;
      final beforePrs = Map<String, PersonalRecord>.from(progress.prs);

      expect(
        await planProvider.updateSchedule(
          daysPerWeek: 3,
          trainingDays: const <int>[2, 4, 6],
        ),
        isTrue,
      );
      await progress.load();

      expect(progress.totalWorkouts, 4);
      expect(progress.streak, beforeStreak);
      expect(progress.prs.keys, beforePrs.keys);
      expect(progress.strengthScore, 175);
    },
  );

  test('deleting the middle workout rebuilds streak, PRs, and score', () async {
    final storage = StorageService.inMemory();
    await storage.writeList(kWorkoutsKey, <Map<String, dynamic>>[
      _twoLiftSession(
        id: 'recent',
        daysAgo: 0,
        benchWeight: 110,
        squatWeight: 130,
      ).toJson(),
      _twoLiftSession(
        id: 'middle',
        daysAgo: 1,
        benchWeight: 120,
        squatWeight: 140,
      ).toJson(),
      _twoLiftSession(
        id: 'oldest',
        daysAgo: 2,
        benchWeight: 90,
        squatWeight: 110,
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
    await storage.writeMap(kPrsKey, <String, Map<String, dynamic>>{
      'barbell-bench-press': PersonalRecord(
        exerciseId: 'barbell-bench-press',
        bestE1rmKg: 120 * (1 + 5 / 30),
        weightKg: 120,
        reps: 5,
        achievedAt: _now,
        sessionId: 'middle',
        previousBestKg: 0,
      ).toJson(),
      'back-squat': PersonalRecord(
        exerciseId: 'back-squat',
        bestE1rmKg: 140 * (1 + 5 / 30),
        weightKg: 140,
        reps: 5,
        achievedAt: _now,
        sessionId: 'middle',
        previousBestKg: 0,
      ).toJson(),
    });

    final history = HistoryProvider(storage);
    final progress = ProgressProvider(storage, clock: _clock);
    await history.load();
    await progress.load();
    expect(progress.totalWorkouts, 3);
    expect(progress.streak, 3);
    expect(progress.weeklyVolume.values.fold(0.0, (a, b) => a + b), 3500);
    expect(progress.strengthScore, 190);

    final coordinator = AppCoordinator(
      storage: storage,
      profileProvider: ProfileProvider(storage, clock: _clock),
      settingsProvider: SettingsProvider(storage),
      planProvider: PlanProvider(
        storage,
        loadExercises: () async => const <Exercise>[],
        clock: _clock,
      ),
      onboardingProvider: OnboardingProvider(storage, clock: _clock),
      historyProvider: history,
      progressProvider: progress,
      clock: _clock,
    );

    expect(await coordinator.deleteWorkout('middle'), isTrue);

    expect(history.workouts.map((workout) => workout.id), <String>[
      'recent',
      'oldest',
    ]);
    expect(progress.totalWorkouts, 2);
    expect(progress.streak, 1);
    expect(progress.weeklyVolume.values.fold(0.0, (a, b) => a + b), 2200);
    expect(progress.prs['barbell-bench-press']!.sessionId, 'recent');
    expect(progress.prs['back-squat']!.sessionId, 'recent');
    expect(progress.strengthScore, isNull);
    expect(progress.scoreReason, StrengthScoreService.missingHistoryReason);
  });
}

WorkoutSession _twoLiftSession({
  required String id,
  required int daysAgo,
  required double benchWeight,
  required double squatWeight,
}) {
  final date = DateTime(_now.year, _now.month, _now.day - daysAgo, 18);
  WorkoutSet setFor(String exerciseId, double weightKg) {
    return WorkoutSet(
      id: 'set-$id-$exerciseId',
      index: 0,
      weightKg: weightKg,
      reps: 5,
      completed: true,
      completedAt: date,
    );
  }

  return WorkoutSession(
    id: id,
    name: 'Workout $id',
    source: SessionSource.empty,
    startedAt: date.subtract(const Duration(minutes: 40)),
    completedAt: date,
    status: SessionStatus.completed,
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'bench-$id',
        exerciseId: 'barbell-bench-press',
        order: 0,
        sets: <WorkoutSet>[setFor('barbell-bench-press', benchWeight)],
      ),
      SessionExercise(
        id: 'squat-$id',
        exerciseId: 'back-squat',
        order: 1,
        sets: <WorkoutSet>[setFor('back-squat', squatWeight)],
      ),
    ],
  );
}
