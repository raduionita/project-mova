import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/gender.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/screens/logger/logger_screen.dart';
import 'package:mova/screens/onboarding/goals_screen.dart';
import 'package:mova/screens/onboarding/welcome_screen.dart';
import 'package:mova/screens/today/today_screen.dart';
import 'package:mova/screens/train/exercise_detail_screen.dart';
import 'package:mova/screens/summary/summary_screen.dart';
import 'package:mova/screens/train/train_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

late List<Exercise> _library;

UserProfile _completeProfile() {
  return UserProfile(
    id: 'profile-1',
    gender: Gender.male,
    birthDate: DateTime.utc(2001, 11, 5),
    goals: const <Goal>[Goal.buildMuscle],
    experienceLevel: ExperienceLevel.beginner,
    createdAt: _fixedNow,
    updatedAt: _fixedNow,
  );
}

UserProfile _incompleteProfile() {
  return UserProfile(
    id: 'profile-2',
    createdAt: _fixedNow,
    updatedAt: _fixedNow,
  );
}

OnboardingDraft _draft() {
  return OnboardingDraft(
    currentStep: OnboardingStep.goals,
    updatedAt: _fixedNow,
  );
}

WorkoutSession _session(SessionStatus status) {
  return WorkoutSession(
    id: 'session-1',
    name: 'Push Day',
    source: SessionSource.plan,
    startedAt: _fixedNow,
    status: status,
    exercises: const [],
  );
}

WorkoutSession _loggedSession() {
  return WorkoutSession(
    id: 'session-2',
    name: 'Push Day',
    source: SessionSource.plan,
    startedAt: _fixedNow.subtract(const Duration(minutes: 30)),
    status: SessionStatus.active,
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'exercise-1',
        exerciseId: 'barbell-bench-press',
        order: 0,
        sets: <WorkoutSet>[
          WorkoutSet(
            id: 'set-1',
            index: 0,
            weightKg: 100,
            reps: 5,
            completed: true,
            completedAt: _fixedNow,
          ),
        ],
      ),
    ],
  );
}

Future<StorageService> _pumpApp(
  WidgetTester tester, {
  UserProfile? profile,
  OnboardingDraft? draft,
  WorkoutSession? session,
}) async {
  final storage = StorageService.inMemory();
  if (profile != null) {
    await storage.writeObject(kProfileKey, profile.toJson());
  }
  if (draft != null) {
    await storage.writeObject(kOnboardingKey, draft.toJson());
  }
  if (session != null) {
    await storage.writeObject(kActiveSessionKey, session.toJson());
  }

  await tester.pumpWidget(
    MovaApp(
      storage: storage,
      clock: FakeClock(_fixedNow),
      seedDataService: _StaticSeedDataService(_library),
    ),
  );
  await tester.pumpAndSettle();
  return storage;
}

void main() {
  setUpAll(() async {
    _library = await SeedDataService().loadExercises();
  });

  testWidgets('no profile and no draft opens welcome', (tester) async {
    await _pumpApp(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('a saved draft resumes at its step', (tester) async {
    await _pumpApp(tester, draft: _draft());

    expect(find.byType(GoalsScreen), findsOneWidget);
  });

  testWidgets('a complete profile opens Today', (tester) async {
    await _pumpApp(tester, profile: _completeProfile());

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('No plan yet'), findsOneWidget);
  });

  testWidgets('an incomplete profile with a draft resumes onboarding', (
    tester,
  ) async {
    await _pumpApp(tester, profile: _incompleteProfile(), draft: _draft());

    expect(find.byType(GoalsScreen), findsOneWidget);
  });

  testWidgets('an active session opens the logger route', (tester) async {
    await _pumpApp(
      tester,
      profile: _completeProfile(),
      session: _session(SessionStatus.active),
    );

    expect(find.byType(LoggerScreen), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('No exercises yet'), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('a paused session opens Today', (tester) async {
    await _pumpApp(
      tester,
      profile: _completeProfile(),
      session: _session(SessionStatus.paused),
    );

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byType(LoggerScreen), findsNothing);
  });

  testWidgets('the summary route takes the completed session and hides tabs', (
    tester,
  ) async {
    await _pumpApp(tester, profile: _completeProfile());

    final context = tester.element(find.byType(TodayScreen));
    Navigator.of(context).pushNamed(
      Routes.summary,
      arguments: SummaryArgs(session: _session(SessionStatus.completed)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('Save workout'), findsOneWidget);
    expect(find.text('Today'), findsNothing);

    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('finishing a workout opens the summary with its records', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      profile: _completeProfile(),
      session: _loggedSession(),
    );

    expect(find.byType(LoggerScreen), findsOneWidget);
    await tester.ensureVisible(find.text('Finish workout'));
    await tester.tap(find.text('Finish workout'));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('NEW PR'), findsOneWidget);
  });

  testWidgets('the shell opens the Train library and exercise details', (
    tester,
  ) async {
    await _pumpApp(tester, profile: _completeProfile());

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();

    expect(find.byType(TrainScreen), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    expect(find.text('Lie on a flat bench with feet planted.'), findsOneWidget);
    expect(find.text('Previous best'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
  });
}

/// Serves a preloaded library so app startup tests never load assets inside a
/// `testWidgets` body.
class _StaticSeedDataService extends SeedDataService {
  _StaticSeedDataService(this._exercises);

  final List<Exercise> _exercises;

  @override
  Future<List<Exercise>> loadExercises() async => _exercises;
}
