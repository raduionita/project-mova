import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_coordinator.dart';
import 'models/user_profile.dart';
import 'models/workout_session.dart';
import 'navigation/app_navigation.dart';
import 'navigation/app_shell.dart';
import 'navigation/onboarding_flow.dart';
import 'navigation/routes.dart';
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
import 'providers/weight_provider.dart';
import 'providers/workout_provider.dart';
import 'screens/onboarding/birth_date_screen.dart';
import 'screens/onboarding/equipment_screen.dart';
import 'screens/onboarding/experience_screen.dart';
import 'screens/onboarding/gender_screen.dart';
import 'screens/onboarding/goals_screen.dart';
import 'screens/onboarding/height_screen.dart';
import 'screens/onboarding/notifications_screen.dart';
import 'screens/onboarding/plan_preview_screen.dart';
import 'screens/onboarding/schedule_screen.dart';
import 'screens/onboarding/unit_selection_screen.dart';
import 'screens/onboarding/weight_screen.dart';
import 'screens/logger/logger_screen.dart';
import 'screens/me/equipment_screen.dart';
import 'screens/me/legal_document_screen.dart';
import 'screens/me/licenses_screen.dart';
import 'screens/me/me_screen.dart';
import 'screens/me/profile_edit_screen.dart';
import 'screens/me/settings_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/progress/history_detail_screen.dart';
import 'screens/progress/history_screen.dart';
import 'screens/progress/progress_screen.dart';
import 'screens/progress/weight_log_screen.dart';
import 'screens/shared/splash_screen.dart';
import 'screens/social/social_feed_screen.dart';
import 'screens/summary/summary_screen.dart';
import 'screens/today/today_screen.dart';
import 'screens/train/exercise_detail_screen.dart';
import 'screens/train/routine_builder_screen.dart';
import 'screens/train/routine_detail_screen.dart';
import 'screens/train/routine_list_screen.dart';
import 'screens/train/train_screen.dart';
import 'services/clock.dart';
import 'services/id_service.dart';
import 'services/seed_data_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

/// Root widget. Builds the provider tree and starts at the splash gate.
class MovaApp extends StatelessWidget {
  const MovaApp({
    super.key,
    required this.storage,
    this.clock,
    this.idService,
    this.seedDataService,
  });

  final StorageService storage;
  final Clock? clock;
  final IdService? idService;
  final SeedDataService? seedDataService;

  @override
  Widget build(BuildContext context) {
    final resolvedClock = clock ?? const SystemClock();
    final resolvedIds = idService ?? IdService();
    final seedData = seedDataService ?? SeedDataService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storage),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(storage, clock: resolvedClock),
        ),
        ChangeNotifierProvider<ExerciseProvider>(
          create: (_) =>
              ExerciseProvider(storage, seedData, clock: resolvedClock),
        ),
        ChangeNotifierProvider<RoutineProvider>(
          create: (_) => RoutineProvider(storage),
        ),
        ChangeNotifierProvider<PlanProvider>(
          create: (_) => PlanProvider(
            storage,
            loadExercises: seedData.loadExercises,
            clock: resolvedClock,
          ),
        ),
        ChangeNotifierProvider<OnboardingProvider>(
          create: (_) => OnboardingProvider(storage, clock: resolvedClock),
        ),
        ChangeNotifierProvider<WorkoutProvider>(
          create: (_) => WorkoutProvider(
            storage,
            clock: resolvedClock,
            idService: resolvedIds,
          ),
        ),
        ChangeNotifierProvider<HistoryProvider>(
          create: (_) => HistoryProvider(storage),
        ),
        ChangeNotifierProvider<ProgressProvider>(
          create: (_) => ProgressProvider(storage, clock: resolvedClock),
        ),
        ChangeNotifierProvider<StepsProvider>(
          create: (_) => StepsProvider(storage, clock: resolvedClock),
        ),
        ChangeNotifierProvider<WeightProvider>(
          create: (_) => WeightProvider(storage, clock: resolvedClock),
        ),
        ChangeNotifierProvider<SocialProvider>(
          create: (_) =>
              SocialProvider(storage, seedData, clock: resolvedClock),
        ),
        Provider<AppCoordinator>(
          create: (context) => AppCoordinator(
            storage: storage,
            profileProvider: context.read<ProfileProvider>(),
            settingsProvider: context.read<SettingsProvider>(),
            planProvider: context.read<PlanProvider>(),
            onboardingProvider: context.read<OnboardingProvider>(),
            historyProvider: context.read<HistoryProvider>(),
            progressProvider: context.read<ProgressProvider>(),
            workoutProvider: context.read<WorkoutProvider>(),
            socialProvider: context.read<SocialProvider>(),
            exerciseProvider: context.read<ExerciseProvider>(),
            routineProvider: context.read<RoutineProvider>(),
            stepsProvider: context.read<StepsProvider>(),
            weightProvider: context.read<WeightProvider>(),
            clock: resolvedClock,
            idService: resolvedIds,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Mova',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _StartupGate(),
        onGenerateRoute: _generateRoute,
      ),
    );
  }
}

/// Loads local state, then replaces the splash with the startup destination.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.wait<void>(<Future<void>>[
      context.read<ProfileProvider>().load(),
      context.read<OnboardingProvider>().load(),
      context.read<PlanProvider>().load(),
      context.read<WorkoutProvider>().loadActive(),
      context.read<HistoryProvider>().load(),
      context.read<ProgressProvider>().load(),
      context.read<StepsProvider>().load(),
      context.read<WeightProvider>().load(),
      context.read<SettingsProvider>().load(),
    ]);
    if (!mounted) {
      return;
    }
    final social = context.read<SocialProvider>();
    social.setPlaceholderDismissed(
      context.read<SettingsProvider>().settings.sampleFeedDismissed,
    );
    await social.load();
    if (!mounted) {
      return;
    }
    final destination = _startupDestination(
      profile: context.read<ProfileProvider>().profile,
      onboarding: context.read<OnboardingProvider>(),
      session: context.read<WorkoutProvider>().activeSession,
    );
    Navigator.of(context).pushReplacementNamed(destination);
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}

String _startupDestination({
  required UserProfile? profile,
  required OnboardingProvider onboarding,
  required WorkoutSession? session,
}) {
  if (session != null && session.status == SessionStatus.active) {
    return Routes.logger;
  }
  if (session != null && session.status == SessionStatus.paused) {
    return Routes.today;
  }
  if (profile == null || !profile.isComplete) {
    return onboarding.hasDraft
        ? OnboardingFlow.resumeRoute(onboarding.draft)
        : Routes.welcome;
  }
  return Routes.today;
}

Route<dynamic> _generateRoute(RouteSettings settings) {
  return MaterialPageRoute<dynamic>(
    settings: settings,
    builder: (context) {
      final route = settings.name;
      final screen = _screenForRoute(route, settings.arguments);
      if (!AppNavigation.showsBottomBar(route)) {
        return screen;
      }
      return AppShell(
        currentRoute: route!,
        onTabSelected: (tab) => _openTab(context, tab),
        child: screen,
      );
    },
  );
}

/// Replaces the current tab route with the destination tab.
void _openTab(BuildContext context, AppTab tab) {
  final item = AppNavigation.allTabs.firstWhere((entry) => entry.tab == tab);
  Navigator.of(context).pushReplacementNamed(item.route);
}

Widget _screenForRoute(String? route, [Object? arguments]) {
  final exerciseId = Routes.exerciseIdFromRoute(route);
  if (exerciseId != null) {
    return ExerciseDetailScreen(exerciseId: exerciseId);
  }
  final routineEditId = Routes.routineEditIdFromRoute(route);
  if (routineEditId != null) {
    return RoutineBuilderScreen(routineId: routineEditId);
  }
  final routineId = Routes.routineIdFromRoute(route);
  if (routineId != null) {
    return RoutineDetailScreen(routineId: routineId);
  }
  final historyId = Routes.progressHistoryIdFromRoute(route);
  if (historyId != null) {
    return HistoryDetailScreen(sessionId: historyId);
  }
  final legalDoc = Routes.legalDocFromRoute(route);
  if (legalDoc != null) {
    return LegalDocumentScreen(documentId: legalDoc);
  }
  switch (route) {
    case Routes.welcome:
      return const WelcomeScreen();
    case Routes.onboardingUnits:
      return const UnitSelectionScreen();
    case Routes.onboardingGender:
      return const GenderScreen();
    case Routes.onboardingBirthDate:
      return const BirthDateScreen();
    case Routes.onboardingWeight:
      return const WeightScreen();
    case Routes.onboardingHeight:
      return const HeightScreen();
    case Routes.onboardingGoals:
      return const GoalsScreen();
    case Routes.onboardingExperience:
      return const ExperienceScreen();
    case Routes.onboardingSchedule:
      return const ScheduleScreen();
    case Routes.onboardingEquipment:
      return const OnboardingEquipmentScreen();
    case Routes.onboardingNotifications:
      return const NotificationsScreen();
    case Routes.onboardingPlan:
      return const PlanPreviewScreen();
    case Routes.today:
      return const TodayScreen();
    case Routes.train:
      return const TrainScreen();
    case Routes.routines:
      return const RoutineListScreen();
    case Routes.routineNew:
      return const RoutineBuilderScreen();
    case Routes.progress:
      return const ProgressScreen();
    case Routes.progressHistory:
      return const HistoryScreen();
    case Routes.progressWeight:
      return const WeightLogScreen();
    case Routes.social:
      return const SocialFeedScreen();
    case Routes.me:
      return const MeScreen();
    case Routes.meEdit:
      return const ProfileEditScreen();
    case Routes.meSettings:
      return const SettingsScreen();
    case Routes.meEquipment:
      return const EquipmentSettingsScreen();
    case Routes.meLicenses:
      return const LicensesScreen();
    case Routes.logger:
      return const LoggerScreen();
    case Routes.summary:
      if (arguments is SummaryArgs) {
        return SummaryScreen(
          session: arguments.session,
          records: arguments.records,
        );
      }
      if (arguments is WorkoutSession) {
        return SummaryScreen(session: arguments);
      }
      return const WelcomeScreen();
    default:
      return const WelcomeScreen();
  }
}
