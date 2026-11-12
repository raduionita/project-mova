import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/activity_post.dart';
import 'package:mova/models/app_settings.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/gender.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/routine.dart';
import 'package:mova/models/routine_exercise.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/step_entry.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';

void main() {
  group('UnitPreferences', () {
    test('round-trips all unit choices', () {
      const preferences = UnitPreferences(
        weightUnit: WeightUnit.lb,
        distanceUnit: DistanceUnit.mi,
        heightUnit: HeightUnit.inches,
      );
      final decoded = UnitPreferences.fromJson(preferences.toJson());
      expect(decoded.toJson(), preferences.toJson());
    });

    test('unknown units fall back to metric defaults', () {
      final decoded = UnitPreferences.fromJson(<String, dynamic>{
        'weightUnit': 'stone',
        'distanceUnit': 'furlong',
        'heightUnit': 'hand',
      });
      expect(decoded.weightUnit, WeightUnit.kg);
      expect(decoded.distanceUnit, DistanceUnit.km);
      expect(decoded.heightUnit, HeightUnit.cm);
    });
  });

  group('UserProfile', () {
    final profile = UserProfile(
      id: 'profile-1',
      displayName: 'Radu',
      gender: Gender.male,
      birthDate: DateTime.utc(1994, 4, 12),
      heightCm: 180,
      goals: const <Goal>[Goal.buildMuscle, Goal.getStronger],
      experienceLevel: ExperienceLevel.regular,
      bodyWeightKg: 78.5,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    test('round-trips and computes primary goal', () {
      final decoded = UserProfile.fromJson(profile.toJson());
      expect(decoded.toJson(), profile.toJson());
      expect(decoded.primaryGoal, Goal.buildMuscle);
      expect(decoded.isComplete, isTrue);
    });

    test('missing fields use safe defaults', () {
      final decoded = UserProfile.fromJson(const <String, dynamic>{});
      expect(decoded.id, isEmpty);
      expect(decoded.displayName, isEmpty);
      expect(decoded.goals, isEmpty);
      expect(decoded.primaryGoal, isNull);
      expect(decoded.isComplete, isFalse);
    });

    test('unknown enum values become null', () {
      final decoded = UserProfile.fromJson(<String, dynamic>{
        'gender': 'unknown',
        'experienceLevel': 'unknown',
      });
      expect(decoded.gender, isNull);
      expect(decoded.experienceLevel, isNull);
    });
  });

  test('AppSettings round-trips', () {
    const settings = AppSettings(
      unitPreferences: UnitPreferences(weightUnit: WeightUnit.lb),
      remindersEnabled: true,
      reminderWeekdays: <int>[2, 4],
      reminderHour: 7,
      reminderMinute: 30,
      healthProvider: HealthProvider.appleHealth,
      postWorkoutsToFeed: false,
      sampleFeedDismissed: true,
      restTimerEnabled: false,
    );
    final decoded = AppSettings.fromJson(settings.toJson());
    expect(decoded.toJson(), settings.toJson());
  });

  test('AppSettings defaults the rest timer on for legacy JSON', () {
    final decoded = AppSettings.fromJson(const <String, Object?>{});
    expect(decoded.restTimerEnabled, isTrue);
  });

  test('OnboardingDraft round-trips', () {
    final draft = OnboardingDraft(
      currentStep: OnboardingStep.goals,
      unitPreferences: const UnitPreferences(distanceUnit: DistanceUnit.mi),
      gender: Gender.female,
      birthDate: DateTime.utc(1990, 8, 20),
      bodyWeightKg: 62.5,
      heightCm: 168,
      goals: const <Goal>[Goal.loseWeight],
      experienceLevel: ExperienceLevel.beginner,
      daysPerWeek: 3,
      trainingDays: const <int>[1, 3, 5],
      notificationsAsked: true,
      reminderHour: 7,
      reminderMinute: 45,
      updatedAt: DateTime.utc(2026, 2, 3),
    );
    final decoded = OnboardingDraft.fromJson(draft.toJson());
    expect(decoded.toJson(), draft.toJson());
    expect(decoded.reminderHour, 7);
    expect(decoded.reminderMinute, 45);
  });

  test(
    'OnboardingDraft defaults experience to regular and reminder to 18:00',
    () {
      final draft = OnboardingDraft(updatedAt: DateTime.utc(2026, 2, 3));

      expect(draft.experienceLevel, ExperienceLevel.regular);
      expect(draft.reminderHour, 18);
      expect(draft.reminderMinute, 0);
    },
  );

  test('OnboardingDraft fills a missing experience level with regular', () {
    final decoded = OnboardingDraft.fromJson(<String, dynamic>{
      'updatedAt': DateTime.utc(2026, 2, 3).toIso8601String(),
    });

    expect(decoded.experienceLevel, ExperienceLevel.regular);
  });

  test('Exercise round-trips', () {
    const exercise = Exercise(
      id: 'bench-press',
      name: 'Bench Press',
      primaryMuscle: 'Chest',
      secondaryMuscles: <String>['Triceps', 'Shoulders'],
      equipment: 'Barbell',
      instructions: <String>['Lie down', 'Press'],
      isCompound: true,
    );
    final decoded = Exercise.fromJson(exercise.toJson());
    expect(decoded.toJson(), exercise.toJson());
  });

  test('TrainingPlan with nested days round-trips', () {
    final plan = TrainingPlan(
      id: 'plan-1',
      goal: Goal.buildMuscle,
      goals: const <Goal>[Goal.buildMuscle, Goal.getStronger],
      experienceLevel: ExperienceLevel.gymRat,
      daysPerWeek: 1,
      trainingDays: const <int>[1],
      splitName: 'Upper',
      days: <PlanDay>[
        PlanDay(
          id: 'day-1',
          weekday: 1,
          name: 'Upper',
          muscleGroups: const <String>['Chest', 'Back'],
          estimatedMinutes: 45,
          exercises: const <PlanExercise>[
            PlanExercise(
              exerciseId: 'bench-press',
              sets: 3,
              repsLow: 8,
              repsHigh: 12,
              restSeconds: 90,
              order: 0,
            ),
          ],
        ),
      ],
      generatedAt: DateTime.utc(2026, 3, 1),
    );
    final decoded = TrainingPlan.fromJson(plan.toJson());
    expect(decoded.toJson(), plan.toJson());
    expect(decoded.days.single.exercises.single.exerciseId, 'bench-press');
  });

  test('TrainingPlan unknown goal falls back to stayHealthy', () {
    final decoded = TrainingPlan.fromJson(<String, dynamic>{
      'goal': 'unknown',
      'experienceLevel': 'unknown',
    });
    expect(decoded.goal, Goal.stayHealthy);
    expect(decoded.experienceLevel, ExperienceLevel.beginner);
  });

  test('Routine with nested exercises round-trips', () {
    final routine = Routine(
      id: 'routine-1',
      name: 'Push day',
      exercises: const <RoutineExercise>[
        RoutineExercise(
          exerciseId: 'bench-press',
          sets: 4,
          repsLow: 6,
          repsHigh: 10,
          restSeconds: 120,
          order: 0,
        ),
      ],
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 2),
    );
    final decoded = Routine.fromJson(routine.toJson());
    expect(decoded.toJson(), routine.toJson());
  });

  test('WorkoutSession with nested exercises and sets round-trips', () {
    final session = WorkoutSession(
      id: 'session-1',
      name: 'Push day',
      source: SessionSource.routine,
      routineId: 'routine-1',
      startedAt: DateTime.utc(2026, 5, 1, 18),
      status: SessionStatus.completed,
      completedAt: DateTime.utc(2026, 5, 1, 19),
      exercises: <SessionExercise>[
        SessionExercise(
          id: 'session-exercise-1',
          exerciseId: 'bench-press',
          order: 0,
          sets: <WorkoutSet>[
            WorkoutSet(
              id: 'set-1',
              index: 0,
              weightKg: 80,
              reps: 8,
              completed: true,
              completedAt: DateTime.utc(2026, 5, 1, 18, 10),
            ),
          ],
        ),
      ],
    );
    final decoded = WorkoutSession.fromJson(session.toJson());
    expect(decoded.toJson(), session.toJson());
  });

  test('WorkoutSession unknown enums fall back safely', () {
    final decoded = WorkoutSession.fromJson(<String, dynamic>{
      'source': 'unknown',
      'status': 'unknown',
    });
    expect(decoded.source, SessionSource.empty);
    expect(decoded.status, SessionStatus.active);
  });

  test('PersonalRecord round-trips', () {
    final record = PersonalRecord(
      exerciseId: 'bench-press',
      bestE1rmKg: 100.5,
      weightKg: 90,
      reps: 5,
      achievedAt: DateTime.utc(2026, 6, 1),
      sessionId: 'session-1',
      previousBestKg: 97.5,
    );
    final decoded = PersonalRecord.fromJson(record.toJson());
    expect(decoded.toJson(), record.toJson());
  });

  test('ActivityPost round-trips', () {
    final post = ActivityPost(
      id: 'post-1',
      authorName: 'Mova',
      isOwn: false,
      sessionId: 'session-1',
      text: 'Sample workout',
      createdAt: DateTime.utc(2026, 7, 1),
      kudos: 4,
      kudosGiven: true,
      isSample: true,
    );
    final decoded = ActivityPost.fromJson(post.toJson());
    expect(decoded.toJson(), post.toJson());
  });

  test('StepEntry round-trips and unknown source falls back to manual', () {
    final entry = StepEntry(
      dateKey: '2026-08-01',
      steps: 8200,
      source: StepSource.health,
      updatedAt: DateTime.utc(2026, 8, 1),
    );
    final decoded = StepEntry.fromJson(entry.toJson());
    expect(decoded.toJson(), entry.toJson());

    final unknown = StepEntry.fromJson(<String, dynamic>{'source': 'watch'});
    expect(unknown.source, StepSource.manual);
  });
}
