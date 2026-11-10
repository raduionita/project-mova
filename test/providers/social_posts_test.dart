import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app_coordinator.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/social_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
final FakeClock _clock = FakeClock(_now);

WorkoutSession _session(String id) {
  return WorkoutSession(
    id: id,
    name: 'Push Day',
    source: SessionSource.plan,
    startedAt: _now.subtract(const Duration(minutes: 40)),
    completedAt: _now,
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
            completedAt: _now,
          ),
        ],
      ),
    ],
  );
}

class _Harness {
  _Harness(this.storage)
    : history = HistoryProvider(storage),
      progress = ProgressProvider(storage, clock: _clock),
      profile = ProfileProvider(storage, clock: _clock),
      settings = SettingsProvider(storage),
      plan = PlanProvider(
        storage,
        loadExercises: () async => const [],
        clock: _clock,
      ),
      onboarding = OnboardingProvider(storage, clock: _clock),
      social = SocialProvider(storage, SeedDataService(), clock: _clock);

  final StorageService storage;
  final HistoryProvider history;
  final ProgressProvider progress;
  final ProfileProvider profile;
  final SettingsProvider settings;
  final PlanProvider plan;
  final OnboardingProvider onboarding;
  final SocialProvider social;

  AppCoordinator get coordinator => AppCoordinator(
    storage: storage,
    profileProvider: profile,
    settingsProvider: settings,
    planProvider: plan,
    onboardingProvider: onboarding,
    historyProvider: history,
    progressProvider: progress,
    socialProvider: social,
    clock: _clock,
    idService: IdService(generator: _sharedIds),
  );

  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      history.load(),
      progress.load(),
      profile.load(),
      settings.load(),
      social.load(),
    ]);
  }
}

var _idCounter = 0;
String _sharedIds() => 'post-${++_idCounter}';

void main() {
  test('finishing a workout creates one own post when sharing is on', () async {
    final harness = _Harness(StorageService.inMemory());
    await harness.load();
    await harness.profile.saveProfile(
      UserProfile(
        id: 'profile-1',
        experienceLevel: ExperienceLevel.regular,
        createdAt: _now,
        updatedAt: _now,
      ),
    );

    final saved = await harness.coordinator.completeWorkout(_session('s1'));

    expect(saved, isTrue);
    expect(harness.social.posts.where((post) => post.isOwn), hasLength(1));
    final post = harness.social.posts.firstWhere((post) => post.isOwn);
    expect(post.isOwn, isTrue);
    expect(post.isSample, isFalse);
    expect(post.sessionId, 's1');
    expect(post.authorName, 'Regular');
    expect(post.text, contains('Push Day'));
  });

  test('no own post is created when sharing is off', () async {
    final harness = _Harness(StorageService.inMemory());
    await harness.load();
    await harness.settings.setPostWorkoutsToFeed(false);

    final saved = await harness.coordinator.completeWorkout(_session('s1'));

    expect(saved, isTrue);
    expect(harness.social.posts.where((post) => post.isOwn), isEmpty);
  });

  test(
    'completing the same session twice does not duplicate its post',
    () async {
      final harness = _Harness(StorageService.inMemory());
      await harness.load();

      await harness.coordinator.completeWorkout(_session('s1'));
      await harness.coordinator.completeWorkout(_session('s1'));

      expect(harness.social.posts.where((post) => post.isOwn), hasLength(1));
    },
  );

  test('deleting a workout removes its own post', () async {
    final harness = _Harness(StorageService.inMemory());
    await harness.load();
    await harness.coordinator.completeWorkout(_session('s1'));
    await harness.coordinator.completeWorkout(_session('s2'));
    expect(harness.social.posts.where((post) => post.isOwn), hasLength(2));

    final deleted = await harness.coordinator.deleteWorkout('s1');

    expect(deleted, isTrue);
    expect(harness.social.hasPostForSession('s1'), isFalse);
    expect(harness.social.hasPostForSession('s2'), isTrue);
  });
}
