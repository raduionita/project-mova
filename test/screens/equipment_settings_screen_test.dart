import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app_coordinator.dart';
import 'package:mova/models/equipment_group.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/onboarding_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/screens/me/equipment_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/id_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime.utc(2026, 11, 7, 12);

TrainingPlan _plan({List<EquipmentGroup>? equipment}) {
  return TrainingPlan(
    id: 'plan-1',
    goal: Goal.buildMuscle,
    goals: const <Goal>[Goal.buildMuscle],
    experienceLevel: ExperienceLevel.regular,
    daysPerWeek: 1,
    trainingDays: const <int>[1],
    splitName: 'Full body',
    days: <PlanDay>[
      PlanDay(
        id: 'day-1',
        weekday: 1,
        name: 'Full Body',
        muscleGroups: const <String>['Chest'],
        estimatedMinutes: 40,
        exercises: const <PlanExercise>[
          PlanExercise(
            exerciseId: 'dumbbell-press',
            sets: 3,
            repsLow: 8,
            repsHigh: 12,
            restSeconds: 90,
            order: 0,
          ),
        ],
      ),
    ],
    generatedAt: _now,
    availableEquipment: equipment ?? EquipmentGroup.values,
  );
}

class _Harness {
  _Harness() {
    storage = StorageService.inMemory();
    profile = ProfileProvider(storage, clock: FakeClock(_now));
    settings = SettingsProvider(storage);
    plan = PlanProvider(
      storage,
      loadExercises: () async => const <Exercise>[
        Exercise(
          id: 'dumbbell-press',
          name: 'Dumbbell Press',
          primaryMuscle: 'Chest',
          equipment: 'Dumbbell',
          isCompound: true,
        ),
      ],
      clock: FakeClock(_now),
    );
    onboarding = OnboardingProvider(storage, clock: FakeClock(_now));
    history = HistoryProvider(storage);
    progress = ProgressProvider(storage);
    coordinator = AppCoordinator(
      storage: storage,
      profileProvider: profile,
      settingsProvider: settings,
      planProvider: plan,
      onboardingProvider: onboarding,
      historyProvider: history,
      progressProvider: progress,
      clock: FakeClock(_now),
      idService: IdService(),
    );
  }

  late final StorageService storage;
  late final ProfileProvider profile;
  late final SettingsProvider settings;
  late final PlanProvider plan;
  late final OnboardingProvider onboarding;
  late final HistoryProvider history;
  late final ProgressProvider progress;
  late final AppCoordinator coordinator;

  Future<void> load() async {
    await profile.saveProfile(
      UserProfile(id: 'profile-1', createdAt: _now, updatedAt: _now),
    );
    await plan.replacePlan(_plan());
  }

  Widget build() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileProvider>.value(value: profile),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<PlanProvider>.value(value: plan),
      ],
      child: Provider<AppCoordinator>.value(
        value: coordinator,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const EquipmentSettingsScreen(),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('renders the current equipment count', (tester) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = _Harness();
    await harness.load();

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();

    expect(find.text('Equipment'), findsOneWidget);
    expect(find.text('7 selected'), findsOneWidget);
  });

  testWidgets('save only keeps the current plan', (tester) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = _Harness();
    await harness.load();
    final planBefore = harness.plan.plan;

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();
    await tester.tap(find.text(EquipmentGroup.bodyweight.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Update this week\'s plan?'), findsOneWidget);
    await tester.tap(find.text('Save only'));
    await tester.pumpAndSettle();

    expect(
      harness.profile.profile?.availableEquipment.length,
      EquipmentGroup.values.length - 1,
    );
    expect(harness.plan.plan, same(planBefore));
  });

  testWidgets('save and regenerate rebuilds the plan with the selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = _Harness();
    await harness.load();

    await tester.pumpWidget(harness.build());
    await tester.pumpAndSettle();
    await tester.tap(find.text(EquipmentGroup.bodyweight.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save and regenerate'));
    await tester.pumpAndSettle();

    expect(
      harness.profile.profile?.availableEquipment,
      isNot(contains(EquipmentGroup.bodyweight)),
    );
    expect(harness.plan.plan, isNotNull);
    expect(
      harness.plan.plan!.availableEquipment,
      isNot(contains(EquipmentGroup.bodyweight)),
    );
  });
}
