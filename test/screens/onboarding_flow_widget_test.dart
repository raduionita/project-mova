import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app.dart';
import 'package:mova/app_coordinator.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/gender.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/steps_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/screens/onboarding/birth_date_screen.dart';
import 'package:mova/screens/onboarding/equipment_screen.dart';
import 'package:mova/screens/onboarding/experience_screen.dart';
import 'package:mova/screens/onboarding/gender_screen.dart';
import 'package:mova/screens/onboarding/goals_screen.dart';
import 'package:mova/screens/onboarding/height_screen.dart';
import 'package:mova/screens/onboarding/notifications_screen.dart';
import 'package:mova/screens/onboarding/plan_preview_screen.dart';
import 'package:mova/screens/onboarding/schedule_screen.dart';
import 'package:mova/screens/onboarding/unit_selection_screen.dart';
import 'package:mova/screens/onboarding/weight_screen.dart';
import 'package:mova/screens/onboarding/welcome_screen.dart';
import 'package:mova/screens/today/today_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _fixedNow = DateTime.utc(2026, 11, 5, 12);

TrainingPlan _fixturePlan() {
  return TrainingPlan(
    id: 'plan-flow',
    goal: Goal.buildMuscle,
    goals: const <Goal>[Goal.buildMuscle],
    experienceLevel: ExperienceLevel.regular,
    daysPerWeek: 3,
    splitName: 'Push Pull Legs',
    days: <PlanDay>[
      const PlanDay(
        id: 'day-push',
        order: 0,
        slotKey: 'push',
        name: 'Push Day',
        muscleGroups: <String>['Chest', 'Shoulders', 'Triceps'],
        estimatedMinutes: 55,
        exercises: <PlanExercise>[],
      ),
      const PlanDay(
        id: 'day-pull',
        order: 1,
        slotKey: 'pull',
        name: 'Pull Day',
        muscleGroups: <String>['Back', 'Biceps'],
        estimatedMinutes: 50,
        exercises: <PlanExercise>[],
      ),
      const PlanDay(
        id: 'day-legs',
        order: 2,
        slotKey: 'legs',
        name: 'Leg Day',
        muscleGroups: <String>['Quads', 'Hamstrings', 'Glutes'],
        estimatedMinutes: 60,
        exercises: <PlanExercise>[],
      ),
    ],
    generatedAt: _fixedNow,
  );
}

class _FlowHarness {
  _FlowHarness(this.storage)
    : onboarding = OnboardingProvider(storage, clock: FakeClock(_fixedNow)),
      settings = SettingsProvider(storage),
      profile = ProfileProvider(storage, clock: FakeClock(_fixedNow)),
      plan = PlanProvider(
        storage,
        loadExercises: () async => const <Exercise>[],
        clock: FakeClock(_fixedNow),
      ),
      history = HistoryProvider(storage),
      progress = ProgressProvider(storage),
      workout = WorkoutProvider(storage, clock: FakeClock(_fixedNow)),
      steps = StepsProvider(storage, clock: FakeClock(_fixedNow));

  final StorageService storage;
  final OnboardingProvider onboarding;
  final SettingsProvider settings;
  final ProfileProvider profile;
  final PlanProvider plan;
  final HistoryProvider history;
  final ProgressProvider progress;
  final WorkoutProvider workout;
  final StepsProvider steps;

  late final AppCoordinator coordinator = AppCoordinator(
    storage: storage,
    profileProvider: profile,
    settingsProvider: settings,
    planProvider: plan,
    onboardingProvider: onboarding,
    historyProvider: history,
    progressProvider: progress,
    clock: FakeClock(_fixedNow),
    idService: IdService(),
  );

  Future<void> load() async {
    await onboarding.load();
    await settings.load();
    await profile.load();
    await plan.load();
    await history.load();
    await progress.load();
    await steps.load();
  }

  Widget build() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OnboardingProvider>.value(value: onboarding),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ProfileProvider>.value(value: profile),
        ChangeNotifierProvider<PlanProvider>.value(value: plan),
        ChangeNotifierProvider<HistoryProvider>.value(value: history),
        ChangeNotifierProvider<ProgressProvider>.value(value: progress),
        ChangeNotifierProvider<WorkoutProvider>.value(value: workout),
        ChangeNotifierProvider<StepsProvider>.value(value: steps),
      ],
      child: Provider<AppCoordinator>.value(
        value: coordinator,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const WelcomeScreen(),
          onGenerateRoute: _generateRoute,
        ),
      ),
    );
  }
}

Route<dynamic> _generateRoute(RouteSettings settings) {
  final Widget screen;
  switch (settings.name) {
    case Routes.welcome:
      screen = const WelcomeScreen();
    case Routes.onboardingUnits:
      screen = const UnitSelectionScreen();
    case Routes.onboardingGender:
      screen = const GenderScreen();
    case Routes.onboardingBirthDate:
      screen = BirthDateScreen(clock: FakeClock(_fixedNow));
    case Routes.onboardingWeight:
      screen = const WeightScreen();
    case Routes.onboardingHeight:
      screen = const HeightScreen();
    case Routes.onboardingGoals:
      screen = const GoalsScreen();
    case Routes.onboardingExperience:
      screen = const ExperienceScreen();
    case Routes.onboardingSchedule:
      screen = const ScheduleScreen();
    case Routes.onboardingEquipment:
      screen = const OnboardingEquipmentScreen();
    case Routes.onboardingNotifications:
      screen = const NotificationsScreen();
    case Routes.onboardingPlan:
      screen = PlanPreviewScreen(
        previewBuilder: (_) => _fixturePlan(),
        clock: FakeClock(_fixedNow),
      );
    case Routes.today:
      screen = TodayScreen(clock: FakeClock(_fixedNow));
    default:
      screen = const WelcomeScreen();
  }
  return MaterialPageRoute<void>(builder: (_) => screen, settings: settings);
}

Future<void> _tapContinue(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcome through plan preview completes onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = StorageService.inMemory();
    final harness = _FlowHarness(storage);
    await harness.load();

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();
    expect(find.text('Train with a plan'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your units'), findsOneWidget);
    await _tapContinue(tester);

    expect(find.text('How do you identify?'), findsOneWidget);
    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();
    await _tapContinue(tester);

    expect(find.text('When were you born?'), findsOneWidget);
    await _tapContinue(tester);

    expect(find.text('Your weight'), findsOneWidget);
    await _tapContinue(tester);

    expect(find.text('Your height'), findsOneWidget);
    await _tapContinue(tester);

    expect(find.text('What are you training for?'), findsOneWidget);
    await tester.tap(find.text('Build muscle'));
    await tester.pumpAndSettle();
    await _tapContinue(tester);

    expect(find.text('How much experience?'), findsOneWidget);
    await tester.tap(find.text('Regular'));
    await tester.pumpAndSettle();
    await _tapContinue(tester);

    expect(find.text('How often do you train?'), findsOneWidget);
    await _tapContinue(tester);

    expect(find.text('Your equipment'), findsOneWidget);
    await _tapContinue(tester);

    expect(find.text('Stay on schedule'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Your plan'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    await tester.tap(find.text('Start using Mova'));
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byKey(const Key('today-next-up')), findsOneWidget);
    expect(storage.contains(kOnboardingKey), isFalse);
    expect(storage.contains(kProfileKey), isTrue);
    expect(storage.contains(kSettingsKey), isTrue);
    expect(storage.contains(kPlanKey), isTrue);

    final profile = ProfileProvider(storage, clock: FakeClock(_fixedNow));
    await profile.load();
    expect(profile.profile?.displayName, isEmpty);
    expect(profile.profile?.bodyWeightKg, 78);
    expect(profile.profile?.heightCm, 175);
    expect(profile.profile?.goals, const <Goal>[Goal.buildMuscle]);
    expect(profile.profile?.experienceLevel, ExperienceLevel.regular);

    final settings = SettingsProvider(storage);
    await settings.load();
    expect(settings.settings.unitPreferences.weightUnit, WeightUnit.kg);
    expect(settings.settings.unitPreferences.distanceUnit, DistanceUnit.km);
    expect(settings.settings.unitPreferences.heightUnit, HeightUnit.cm);

    final plan = PlanProvider(storage, loadExercises: () async => const []);
    await plan.load();
    expect(plan.plan?.trainingDays, isEmpty);
    expect(plan.plan?.days.map((day) => day.weekday), everyElement(0));
    expect(plan.plan?.days, hasLength(3));
    expect(
      plan.plan?.days.every((day) => day.slotKey.isNotEmpty),
      isTrue,
    );
    expect(plan.plan?.daysPerWeek, 3);
  });

  testWidgets('a saved draft resumes at its step on launch', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeObject(
      kOnboardingKey,
      OnboardingDraft(
        currentStep: OnboardingStep.weight,
        gender: Gender.male,
        birthDate: DateTime(2001, 11, 5),
        updatedAt: _fixedNow,
      ).toJson(),
    );

    await tester.pumpWidget(
      MovaApp(storage: storage, clock: FakeClock(_fixedNow)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your weight'), findsOneWidget);
    expect(find.text('Choose your units'), findsNothing);
  });

  testWidgets('back and forward keep every step reachable', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = _FlowHarness(StorageService.inMemory());
    await harness.load();

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await _tapContinue(tester);
    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();
    await _tapContinue(tester);
    await _tapContinue(tester);
    await _tapContinue(tester);
    await _tapContinue(tester);
    expect(find.text('What are you training for?'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Your height'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Your weight'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('When were you born?'), findsOneWidget);
    expect(harness.onboarding.draft.currentStep, OnboardingStep.birthDate);

    await _tapContinue(tester);
    expect(find.text('Your weight'), findsOneWidget);
    await _tapContinue(tester);
    expect(find.text('Your height'), findsOneWidget);
    await _tapContinue(tester);
    expect(find.text('What are you training for?'), findsOneWidget);

    await tester.tap(find.text('Build muscle'));
    await tester.pumpAndSettle();
    await _tapContinue(tester);
    expect(find.text('How much experience?'), findsOneWidget);

    await tester.tap(find.text('Regular'));
    await tester.pumpAndSettle();
    await _tapContinue(tester);
    expect(find.text('How often do you train?'), findsOneWidget);

    await _tapContinue(tester);
    expect(find.text('Your equipment'), findsOneWidget);
    await _tapContinue(tester);
    expect(find.text('Stay on schedule'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Your plan'), findsOneWidget);
    expect(harness.onboarding.draft.currentStep, OnboardingStep.plan);
  });

  testWidgets('editing the schedule from plan returns to the preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final harness = _FlowHarness(StorageService.inMemory());
    await harness.load();

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(Routes.onboardingPlan);
    await tester.pumpAndSettle();
    expect(find.text('Your plan'), findsOneWidget);

    await tester.tap(find.text('Edit schedule'));
    await tester.pumpAndSettle();
    expect(find.text('How often do you train?'), findsOneWidget);
    expect(harness.onboarding.editingPlan, isTrue);

    await _tapContinue(tester);
    expect(find.text('Your plan'), findsOneWidget);
    expect(harness.onboarding.editingPlan, isFalse);
    expect(harness.onboarding.draft.currentStep, OnboardingStep.plan);
  });
}
