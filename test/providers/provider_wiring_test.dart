import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app.dart';
import 'package:mova/app_coordinator.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/gender.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/routine_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/social_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

IdGenerator _sequentialIds() {
  var counter = 0;
  return () => 'id-${++counter}';
}

Future<BuildContext> _pumpApp(
  WidgetTester tester,
  StorageService storage,
) async {
  await tester.pumpWidget(
    MovaApp(
      storage: storage,
      clock: FakeClock(_fixedNow),
      idService: IdService(generator: _sequentialIds()),
    ),
  );
  await tester.pumpAndSettle();
  return tester.element(find.byType(Scaffold).first);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('provider tree exposes every provider and the coordinator', (
    tester,
  ) async {
    final context = await _pumpApp(tester, StorageService.inMemory());

    expect(context.read<SettingsProvider>(), isA<SettingsProvider>());
    expect(context.read<ProfileProvider>(), isA<ProfileProvider>());
    expect(context.read<ExerciseProvider>(), isA<ExerciseProvider>());
    expect(context.read<RoutineProvider>(), isA<RoutineProvider>());
    expect(context.read<PlanProvider>(), isA<PlanProvider>());
    expect(context.read<OnboardingProvider>(), isA<OnboardingProvider>());
    expect(context.read<WorkoutProvider>(), isA<WorkoutProvider>());
    expect(context.read<HistoryProvider>(), isA<HistoryProvider>());
    expect(context.read<ProgressProvider>(), isA<ProgressProvider>());
    expect(context.read<SocialProvider>(), isA<SocialProvider>());
    expect(context.read<AppCoordinator>(), isA<AppCoordinator>());
  });

  testWidgets('coordinator completes onboarding and clears the draft', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final context = await _pumpApp(tester, storage);
    final coordinator = context.read<AppCoordinator>();
    final draft = OnboardingDraft(
      currentStep: OnboardingStep.plan,
      unitPreferences: const UnitPreferences(weightUnit: WeightUnit.lb),
      gender: Gender.male,
      birthDate: DateTime.utc(1994, 4, 12),
      bodyWeightKg: 78.5,
      heightCm: 180,
      goals: const <Goal>[Goal.buildMuscle],
      experienceLevel: ExperienceLevel.regular,
      daysPerWeek: 3,
      notificationsAsked: true,
      updatedAt: _fixedNow,
    );

    expect(await coordinator.completeOnboarding(draft), isTrue);

    final profile = storage.readObject<UserProfile>(
      kProfileKey,
      UserProfile.fromJson,
    );
    expect(profile?.bodyWeightKg, 78.5);
    expect(profile?.goals, <Goal>[Goal.buildMuscle]);

    final plan = storage.readObject<TrainingPlan>(
      kPlanKey,
      TrainingPlan.fromJson,
    );
    expect(plan, isNotNull);
    expect(plan?.days, hasLength(3));
    expect(storage.contains(kOnboardingKey), isFalse);
  });

  testWidgets('workout flows into history and deletion recomputes', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final context = await _pumpApp(tester, storage);
    final workout = context.read<WorkoutProvider>();
    final history = context.read<HistoryProvider>();
    final coordinator = context.read<AppCoordinator>();

    expect(await workout.startEmpty(), isTrue);
    expect(await workout.addExercise('bench-press'), isTrue);
    final exercise = workout.activeSession!.exercises.single;
    final setId = exercise.sets.first.id;

    expect(
      await workout.updateSet(
        exerciseId: 'bench-press',
        setId: setId,
        weightKg: 80,
        reps: 5,
        isWarmup: false,
      ),
      isTrue,
    );
    expect(
      await workout.completeSet(exerciseId: 'bench-press', setId: setId),
      isTrue,
    );

    final finished = await workout.finish();
    expect(finished, isNotNull);
    expect(finished?.status, SessionStatus.completed);
    expect(workout.activeSession, isNull);

    expect(await coordinator.completeWorkout(finished!), isTrue);
    await history.load();
    expect(history.workouts, hasLength(1));

    expect(await coordinator.deleteWorkout(finished.id), isTrue);
    await history.load();
    expect(history.workouts, isEmpty);
  });

  testWidgets('finishWorkout saves the session and PRs and clears active', (
    tester,
  ) async {
    final storage = StorageService.inMemory();
    final context = await _pumpApp(tester, storage);
    final workout = context.read<WorkoutProvider>();
    final history = context.read<HistoryProvider>();
    final progress = context.read<ProgressProvider>();
    final coordinator = context.read<AppCoordinator>();

    expect(await workout.startEmpty(), isTrue);
    expect(await workout.addExercise('barbell-bench-press'), isTrue);
    final exercise = workout.activeSession!.exercises.single;
    final setId = exercise.sets.first.id;
    expect(
      await workout.updateSet(
        exerciseId: 'barbell-bench-press',
        setId: setId,
        weightKg: 100,
        reps: 5,
        isWarmup: false,
      ),
      isTrue,
    );
    expect(
      await workout.completeSet(
        exerciseId: 'barbell-bench-press',
        setId: setId,
      ),
      isTrue,
    );

    final result = await coordinator.finishWorkout();

    expect(result, isNotNull);
    expect(result!.session.status, SessionStatus.completed);
    expect(result.records, hasLength(1));
    expect(result.records.single.exerciseId, 'barbell-bench-press');
    expect(result.records.single.previousBestKg, 0);
    expect(workout.activeSession, isNull);

    await history.load();
    expect(history.workouts, hasLength(1));
    expect(history.workouts.single.id, result.session.id);

    await progress.load();
    expect(progress.prs['barbell-bench-press'], isNotNull);
    expect(
      progress.prs['barbell-bench-press']!.bestE1rmKg,
      result.records.single.bestE1rmKg,
    );
  });
}
