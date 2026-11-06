import 'common/formatters.dart';
import 'models/activity_post.dart';
import 'models/onboarding_draft.dart';
import 'models/personal_record.dart';
import 'models/user_profile.dart';
import 'models/workout_session.dart';
import 'providers/exercise_provider.dart';
import 'providers/history_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/social_provider.dart';
import 'providers/steps_provider.dart';
import 'providers/workout_provider.dart';
import 'services/clock.dart';
import 'services/id_service.dart';
import 'services/pr_service.dart';
import 'services/storage_service.dart';
import 'services/workout_calculator.dart';

/// Coordinates transactions that span more than one provider.
class AppCoordinator {
  AppCoordinator({
    required this.storage,
    required this.profileProvider,
    required this.settingsProvider,
    required this.planProvider,
    required this.onboardingProvider,
    required this.historyProvider,
    required this.progressProvider,
    this.workoutProvider,
    this.socialProvider,
    this.exerciseProvider,
    this.routineProvider,
    this.stepsProvider,
    this.prService = const PrService(),
    Clock? clock,
    IdService? idService,
  }) : _clock = clock ?? const SystemClock(),
       _idService = idService ?? IdService();

  final StorageService storage;
  final ProfileProvider profileProvider;
  final SettingsProvider settingsProvider;
  final PlanProvider planProvider;
  final OnboardingProvider onboardingProvider;
  final HistoryProvider historyProvider;
  final ProgressProvider progressProvider;
  final WorkoutProvider? workoutProvider;
  final SocialProvider? socialProvider;
  final ExerciseProvider? exerciseProvider;
  final RoutineProvider? routineProvider;
  final StepsProvider? stepsProvider;
  final PrService prService;
  final Clock _clock;
  final IdService _idService;

  /// Writes profile, settings, and plan before clearing the draft.
  Future<bool> completeOnboarding(OnboardingDraft draft) async {
    final experienceLevel = draft.experienceLevel;
    final daysPerWeek = draft.daysPerWeek;
    if (experienceLevel == null || daysPerWeek == null || draft.goals.isEmpty) {
      return false;
    }

    final now = _clock.now();
    final profile = UserProfile(
      id: _idService.next(),
      displayName: 'Athlete',
      gender: draft.gender,
      birthDate: draft.birthDate,
      heightCm: draft.heightCm,
      goals: draft.goals,
      experienceLevel: experienceLevel,
      bodyWeightKg: draft.bodyWeightKg,
      createdAt: now,
      updatedAt: now,
    );

    if (!await profileProvider.saveProfile(profile)) {
      return false;
    }
    if (!await settingsProvider.setUnitPreferences(draft.unitPreferences)) {
      return false;
    }
    if (!await planProvider.generate(
      goals: draft.goals,
      experienceLevel: experienceLevel,
      daysPerWeek: daysPerWeek,
      trainingDays: draft.trainingDays,
    )) {
      return false;
    }
    await onboardingProvider.reset();
    return true;
  }

  /// Adds a finished session to history and refreshes derived progress.
  Future<bool> completeWorkout(WorkoutSession session) async {
    final completed = session.status == SessionStatus.completed
        ? session
        : session.copyWith(
            status: SessionStatus.completed,
            completedAt: _clock.now(),
            pausedAt: null,
          );
    await progressProvider.recompute();
    final records = prService.detect(
      session: completed,
      existing: progressProvider.prs,
    );
    if (!await historyProvider.addCompleted(completed)) {
      return false;
    }
    if (records.isNotEmpty && !await progressProvider.saveRecords(records)) {
      return false;
    }
    await progressProvider.recompute();
    await _publishWorkoutPost(completed);
    return true;
  }

  /// Finishes the active workout as one transaction: persist history and any
  /// new personal records first, then clear the active session.
  Future<WorkoutCompletionResult?> finishWorkout() async {
    final workout = workoutProvider;
    final active = workout?.activeSession;
    if (workout == null || active == null) {
      return null;
    }
    await progressProvider.recompute();
    final completed = active.copyWith(
      status: SessionStatus.completed,
      completedAt: _clock.now(),
      pausedAt: null,
    );
    final records = prService.detect(
      session: completed,
      existing: progressProvider.prs,
    );
    if (!await historyProvider.addCompleted(completed)) {
      return null;
    }
    if (records.isNotEmpty && !await progressProvider.saveRecords(records)) {
      return null;
    }
    if (!await workout.clearActive()) {
      return null;
    }
    await progressProvider.recompute();
    await _publishWorkoutPost(completed);
    return WorkoutCompletionResult(session: completed, records: records);
  }

  /// Deletes a workout and rebuilds every derived metric from what remains.
  Future<bool> deleteWorkout(String sessionId) async {
    if (!await historyProvider.delete(sessionId)) {
      return false;
    }
    final records = prService.recompute(historyProvider.workouts);
    if (!await progressProvider.replaceRecords(records)) {
      return false;
    }
    await progressProvider.recompute();
    await socialProvider?.removePostForSession(sessionId);
    return true;
  }

  /// Clears every local key and reloads providers from their empty state.
  ///
  /// Social reseeds its sample posts and the exercise library reloads from the
  /// bundled assets, so the app returns to a first-run state without a restart.
  Future<bool> resetLocalData() async {
    await settingsProvider.notificationService.cancelAll();
    await storage.clearAll();
    await Future.wait<void>(<Future<void>>[
      profileProvider.load(),
      onboardingProvider.load(),
      settingsProvider.load(),
      planProvider.load(),
      historyProvider.load(),
      progressProvider.load(),
      stepsProvider?.load() ?? Future<void>.value(),
      socialProvider?.load() ?? Future<void>.value(),
      exerciseProvider?.load() ?? Future<void>.value(),
      routineProvider?.load() ?? Future<void>.value(),
      workoutProvider?.loadActive() ?? Future<void>.value(),
    ]);
    return true;
  }

  /// Publishes one own post per completed session when feed sharing is on.
  Future<void> _publishWorkoutPost(WorkoutSession session) async {
    final social = socialProvider;
    if (social == null || !settingsProvider.settings.postWorkoutsToFeed) {
      return;
    }
    if (social.hasPostForSession(session.id)) {
      return;
    }
    final sets = WorkoutCalculator.completedSetCount(session.exercises);
    final volume = WorkoutCalculator.volumeKg(session.exercises);
    final name = session.name.trim().isEmpty ? 'Workout' : session.name.trim();
    final author = profileProvider.profile?.displayName.trim();
    await social.addPost(
      ActivityPost(
        id: _idService.next(),
        authorName: author == null || author.isEmpty ? 'Athlete' : author,
        isOwn: true,
        sessionId: session.id,
        text:
            'Completed $name. '
            '${sets == 1 ? '1 set' : '$sets sets'}, '
            '${formatVolume(volume, unit: settingsProvider.settings.unitPreferences.weightUnit)} volume.',
        createdAt: _clock.now(),
      ),
    );
  }
}

/// Result of finishing a workout, ready for the summary route.
class WorkoutCompletionResult {
  const WorkoutCompletionResult({required this.session, required this.records});

  final WorkoutSession session;
  final List<PersonalRecord> records;
}
