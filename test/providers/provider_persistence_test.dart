import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/activity_post.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/gender.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/routine_exercise.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/routine_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/social_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

UserProfile _profile() {
  return UserProfile(
    id: 'profile-1',
    displayName: 'Radu',
    gender: Gender.male,
    birthDate: DateTime.utc(1994, 4, 12),
    heightCm: 180,
    goals: const <Goal>[Goal.buildMuscle],
    experienceLevel: ExperienceLevel.regular,
    bodyWeightKg: 78.5,
    createdAt: _fixedNow,
    updatedAt: _fixedNow,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings persist unit preferences', () async {
    final storage = StorageService.inMemory();
    final provider = SettingsProvider(storage);
    await provider.load();

    expect(
      await provider.setUnitPreferences(
        const UnitPreferences(
          weightUnit: WeightUnit.lb,
          distanceUnit: DistanceUnit.mi,
          heightUnit: HeightUnit.inches,
        ),
      ),
      isTrue,
    );

    final reloaded = SettingsProvider(storage);
    await reloaded.load();
    expect(reloaded.settings.unitPreferences.weightUnit, WeightUnit.lb);
    expect(reloaded.settings.unitPreferences.distanceUnit, DistanceUnit.mi);
    expect(reloaded.settings.unitPreferences.heightUnit, HeightUnit.inches);
  });

  test('profile persists and updates body weight', () async {
    final storage = StorageService.inMemory();
    final provider = ProfileProvider(storage, clock: FakeClock(_fixedNow));
    await provider.load();

    expect(await provider.saveProfile(_profile()), isTrue);
    expect(await provider.updateBodyWeight(80.5), isTrue);

    final reloaded = ProfileProvider(storage);
    await reloaded.load();
    expect(reloaded.profile?.bodyWeightKg, 80.5);
    expect(reloaded.profile?.displayName, 'Radu');
  });

  test('onboarding draft persists values and steps', () async {
    final storage = StorageService.inMemory();
    final provider = OnboardingProvider(storage, clock: FakeClock(_fixedNow));
    await provider.load();

    expect(provider.draft.currentStep, OnboardingStep.welcome);
    expect(await provider.next(), isTrue);
    expect(provider.draft.currentStep, OnboardingStep.units);

    expect(
      await provider.setUnits(const UnitPreferences(weightUnit: WeightUnit.lb)),
      isTrue,
    );
    expect(await provider.back(), isTrue);
    expect(await provider.next(), isTrue);
    expect(await provider.next(), isTrue);
    expect(provider.draft.currentStep, OnboardingStep.gender);

    expect(await provider.setGender(Gender.female), isTrue);
    expect(provider.canContinue(OnboardingStep.gender), isTrue);
    expect(await provider.next(), isTrue);
    expect(provider.draft.currentStep, OnboardingStep.birthDate);
    expect(await provider.next(), isFalse);

    final reloaded = OnboardingProvider(storage);
    await reloaded.load();
    expect(reloaded.draft.currentStep, OnboardingStep.birthDate);
    expect(reloaded.draft.gender, Gender.female);
    expect(reloaded.draft.unitPreferences.weightUnit, WeightUnit.lb);
  });

  test('routines persist saves, deletes, and reorders', () async {
    final storage = StorageService.inMemory();
    final provider = RoutineProvider(storage);
    await provider.load();

    final routine = Routine(
      id: 'routine-1',
      name: 'Push day',
      exercises: const <RoutineExercise>[
        RoutineExercise(
          exerciseId: 'bench-press',
          sets: 3,
          repsLow: 8,
          repsHigh: 12,
          restSeconds: 90,
          order: 0,
        ),
        RoutineExercise(
          exerciseId: 'overhead-press',
          sets: 3,
          repsLow: 8,
          repsHigh: 12,
          restSeconds: 90,
          order: 1,
        ),
      ],
      createdAt: _fixedNow,
      updatedAt: _fixedNow,
    );

    expect(await provider.save(routine), isTrue);
    expect(
      await provider.reorder(routineId: 'routine-1', oldIndex: 0, newIndex: 1),
      isTrue,
    );
    expect(
      provider.routines.single.exercises.first.exerciseId,
      'overhead-press',
    );
    expect(provider.routines.single.exercises.last.order, 1);

    final reloaded = RoutineProvider(storage);
    await reloaded.load();
    expect(reloaded.routines, hasLength(1));

    expect(await reloaded.delete('routine-1'), isTrue);
    expect(reloaded.routines, isEmpty);
  });

  test('social feed seeds and dismisses the placeholder', () async {
    final storage = StorageService.inMemory();
    final provider = SocialProvider(
      storage,
      SeedDataService(),
      clock: FakeClock(_fixedNow),
    );
    await provider.load();

    expect(provider.posts, hasLength(1));
    expect(provider.posts.single.id, 'placeholder-1');
    expect(provider.posts.single.isSample, isTrue);

    expect(await provider.dismissPlaceholder(), isTrue);
    expect(provider.posts, isEmpty);

    final cleared = SocialProvider(storage, SeedDataService());
    await cleared.load();
    expect(cleared.posts, isEmpty);
  });

  test('custom post survives reload', () async {
    final storage = StorageService.inMemory();
    final provider = SocialProvider(storage, SeedDataService());
    await provider.load();

    final post = ActivityPost(
      id: 'post-1',
      authorName: 'Mova',
      isOwn: true,
      text: 'First workout',
      createdAt: _fixedNow,
    );
    expect(await provider.addPost(post), isTrue);

    final reloaded = SocialProvider(storage, SeedDataService());
    await reloaded.load();
    expect(reloaded.posts.first.id, 'post-1');
  });

  test('settings errors keep the last good state', () async {
    final storage = StorageService.inMemory();
    final provider = SettingsProvider(storage);
    await provider.load();

    expect(
      await provider.setUnitPreferences(
        const UnitPreferences(weightUnit: WeightUnit.lb),
      ),
      isTrue,
    );
    expect(provider.settings.unitPreferences.weightUnit, WeightUnit.lb);
    expect(storage.contains(kSettingsKey), isTrue);
  });

  test('plan provider generates, saves, and reorders sessions', () async {
    final storage = StorageService.inMemory();
    final seed = SeedDataService();
    final provider = PlanProvider(
      storage,
      loadExercises: seed.loadExercises,
      clock: FakeClock(_fixedNow),
    );
    await provider.load();

    expect(
      await provider.generate(
        goals: const <Goal>[Goal.buildMuscle],
        experienceLevel: ExperienceLevel.regular,
        daysPerWeek: 3,
        trainingDays: const <int>[1, 3, 5],
      ),
      isTrue,
    );
    expect(provider.plan, isNotNull);
    expect(provider.plan?.daysPerWeek, 3);

    final names = provider.plan!.days.map((day) => day.name).toList();
    expect(await provider.reorderPlanDay(fromIndex: 0, toIndex: 1), isTrue);
    expect(provider.plan?.days[0].name, names[1]);
    expect(provider.plan?.days[1].name, names[0]);
    expect(provider.plan?.days[0].order, 0);
    expect(provider.plan?.days[1].order, 1);

    final reloaded = PlanProvider(storage, loadExercises: seed.loadExercises);
    await reloaded.load();
    expect(reloaded.plan?.days[0].name, names[1]);
  });

  test('exercise library loads and searches', () async {
    final provider = ExerciseProvider(
      StorageService.inMemory(),
      SeedDataService(),
      clock: FakeClock(_fixedNow),
    );
    await provider.load();

    expect(provider.exercises.length, greaterThanOrEqualTo(60));
    provider.search('bench');
    expect(provider.filtered, isNotEmpty);
    expect(
      provider.filtered.every(
        (exercise) => exercise.name.toLowerCase().contains('bench'),
      ),
      isTrue,
    );

    provider.search('Chest');
    expect(provider.filtered.any((e) => e.primaryMuscle == 'Chest'), isTrue);
    provider.clearSearch();
    expect(provider.filtered.length, provider.exercises.length);
  });
}
