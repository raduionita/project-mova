import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app_coordinator.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/screens/onboarding/plan_preview_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_button.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime.utc(2026, 11, 5, 12);

OnboardingDraft _draft() {
  return OnboardingDraft(
    currentStep: OnboardingStep.plan,
    gender: null,
    birthDate: DateTime.utc(2001, 11, 5),
    bodyWeightKg: 78,
    heightCm: 175,
    goals: const <Goal>[Goal.buildMuscle],
    experienceLevel: ExperienceLevel.gymRat,
    daysPerWeek: 3,
    notificationsAsked: true,
    updatedAt: _now,
  );
}

PlanDay _day({
  required int order,
  required String name,
  required List<String> muscles,
  required int minutes,
  int exercises = 6,
}) {
  return PlanDay(
    id: 'day-${order + 1}',
    order: order,
    slotKey: 'slot-$order',
    name: name,
    muscleGroups: muscles,
    estimatedMinutes: minutes,
    exercises: List<PlanExercise>.generate(
      exercises,
      (index) => PlanExercise(
        exerciseId: 'exercise-$index',
        sets: 3,
        repsLow: 8,
        repsHigh: 12,
        restSeconds: 90,
        order: index,
      ),
    ),
  );
}

TrainingPlan _plan({bool fallback = false}) {
  return TrainingPlan(
    id: 'plan-1',
    goal: Goal.buildMuscle,
    goals: const <Goal>[Goal.buildMuscle],
    experienceLevel: ExperienceLevel.gymRat,
    daysPerWeek: 3,
    splitName: fallback ? 'Starter plan' : 'Push pull legs',
    days: <PlanDay>[
      _day(
        order: 0,
        name: 'Push Day',
        muscles: const <String>['Chest', 'Shoulders', 'Triceps'],
        minutes: 55,
      ),
      _day(
        order: 1,
        name: 'Pull Day',
        muscles: const <String>['Back', 'Biceps'],
        minutes: 50,
        exercises: 5,
      ),
      _day(
        order: 2,
        name: 'Leg Day',
        muscles: const <String>['Quads', 'Hamstrings', 'Glutes'],
        minutes: 60,
      ),
    ],
    generatedAt: _now,
    isFallback: fallback,
  );
}

class _Setup {
  _Setup({
    required this.storage,
    required this.onboarding,
    required this.profile,
    required this.settings,
    required this.plan,
    required this.coordinator,
  });

  final StorageService storage;
  final OnboardingProvider onboarding;
  final ProfileProvider profile;
  final SettingsProvider settings;
  final PlanProvider plan;
  final AppCoordinator coordinator;
}

Future<_Setup> _setup() async {
  final storage = StorageService.inMemory();
  await storage.writeObject(kOnboardingKey, _draft().toJson());

  final onboarding = OnboardingProvider(storage, clock: FakeClock(_now));
  await onboarding.load();
  final profile = ProfileProvider(storage, clock: FakeClock(_now));
  final settings = SettingsProvider(storage);
  final plan = PlanProvider(
    storage,
    loadExercises: () async => const <Exercise>[],
    clock: FakeClock(_now),
  );
  final history = HistoryProvider(storage);
  final progress = ProgressProvider(storage);
  final coordinator = AppCoordinator(
    storage: storage,
    profileProvider: profile,
    settingsProvider: settings,
    planProvider: plan,
    onboardingProvider: onboarding,
    historyProvider: history,
    progressProvider: progress,
    clock: FakeClock(_now),
    idService: IdService(generator: () => 'profile-1'),
  );

  return _Setup(
    storage: storage,
    onboarding: onboarding,
    profile: profile,
    settings: settings,
    plan: plan,
    coordinator: coordinator,
  );
}

/// Serves a preloaded library so the real generation path never loads assets
/// inside a `testWidgets` body.
class _StaticSeedDataService extends SeedDataService {
  _StaticSeedDataService(this._exercises);

  final List<Exercise> _exercises;

  @override
  Future<List<Exercise>> loadExercises() async => _exercises;
}

Widget _wrap(_Setup setup, Widget child, {ExerciseProvider? exercises}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<OnboardingProvider>.value(value: setup.onboarding),
      if (exercises != null)
        ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
      Provider<AppCoordinator>.value(value: setup.coordinator),
    ],
    child: MaterialApp(theme: AppTheme.dark, home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> library;

  setUpAll(() async {
    library = await SeedDataService().loadExercises();
  });

  testWidgets('generates a plan from the library without a build error', (
    tester,
  ) async {
    final setup = await _setup();
    final exercises = ExerciseProvider(
      StorageService.inMemory(),
      _StaticSeedDataService(library),
    );

    await tester.pumpWidget(
      _wrap(setup, const PlanPreviewScreen(), exercises: exercises),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Could not build your plan.'), findsNothing);
    expect(find.text('Start using Mova'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
  });

  testWidgets('renders the week, day details, and both actions', (
    tester,
  ) async {
    final setup = await _setup();
    await tester.pumpWidget(
      _wrap(setup, PlanPreviewScreen(previewBuilder: (_) => _plan())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your plan'), findsOneWidget);
    expect(find.text('Build muscle · 3 days · Gym rat'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Pull Day'), findsOneWidget);
    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.text('DAY 1'), findsOneWidget);
    expect(find.text('DAY 2'), findsOneWidget);
    expect(find.text('DAY 3'), findsOneWidget);
    expect(
      find.text('Chest · Shoulders · Triceps · 6 exercises · ~55 min'),
      findsOneWidget,
    );
    expect(find.text('Start using Mova'), findsOneWidget);
    expect(find.text('Edit schedule'), findsOneWidget);
    expect(find.text('Starter plan'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('fallback plans are labelled Starter plan', (tester) async {
    final setup = await _setup();
    await tester.pumpWidget(
      _wrap(
        setup,
        PlanPreviewScreen(previewBuilder: (_) => _plan(fallback: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Starter plan'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
  });

  testWidgets('edit schedule returns without changing the draft', (
    tester,
  ) async {
    final setup = await _setup();
    final routes = <String>[];
    await tester.pumpWidget(
      _wrap(
        setup,
        PlanPreviewScreen(previewBuilder: (_) => _plan(), onRoute: routes.add),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit schedule'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingSchedule]);
    expect(setup.onboarding.draft.daysPerWeek, 3);
  });

  testWidgets('back returns to notifications', (tester) async {
    final setup = await _setup();
    final routes = <String>[];
    await tester.pumpWidget(
      _wrap(
        setup,
        PlanPreviewScreen(previewBuilder: (_) => _plan(), onRoute: routes.add),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.onboardingNotifications]);
  });

  testWidgets(
    'confirm saves profile, settings, and plan then routes to Today',
    (tester) async {
      final setup = await _setup();
      final routes = <String>[];
      await tester.pumpWidget(
        _wrap(
          setup,
          PlanPreviewScreen(
            previewBuilder: (_) => _plan(),
            onRoute: routes.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start using Mova'));
      await tester.pumpAndSettle();

      expect(routes, <String>[Routes.today]);
      expect(setup.profile.profile, isNotNull);
      expect(setup.profile.profile?.heightCm, 175);
      expect(setup.profile.profile?.goals, <Goal>[Goal.buildMuscle]);
      expect(setup.plan.plan, isNotNull);
      expect(setup.plan.plan?.trainingDays, isEmpty);
      expect(setup.settings.settings.unitPreferences.weightUnit, WeightUnit.kg);
      expect(setup.onboarding.draft.currentStep, OnboardingStep.welcome);
      expect(setup.storage.contains(kOnboardingKey), isFalse);
    },
  );

  testWidgets('tracking mode skips the rotation and begins Mova', (
    tester,
  ) async {
    final setup = await _setup();
    await setup.onboarding.setPlanEnabled(false);
    final routes = <String>[];
    await tester.pumpWidget(
      _wrap(
        setup,
        PlanPreviewScreen(
          previewBuilder: (_) => throw StateError('plan should not generate'),
          onRoute: routes.add,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Mova'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-tracking-summary')), findsOneWidget);
    expect(find.text('Begin your Mova'), findsOneWidget);
    expect(find.text('Start using Mova'), findsNothing);
    expect(find.text('DAY 1'), findsNothing);

    await tester.tap(find.text('Begin your Mova'));
    await tester.pumpAndSettle();

    expect(routes, <String>[Routes.today]);
    expect(setup.profile.profile, isNotNull);
    expect(setup.plan.plan, isNull);
    expect(setup.onboarding.draft.currentStep, OnboardingStep.welcome);
  });

  testWidgets('a generation failure shows a retry card', (tester) async {
    final setup = await _setup();
    await tester.pumpWidget(
      _wrap(
        setup,
        PlanPreviewScreen(
          previewBuilder: (_) => throw StateError('no exercises'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not build your plan.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Start using Mova'), findsOneWidget);

    final button = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Start using Mova'),
    );
    expect(button.onPressed, isNull);
  });
}
