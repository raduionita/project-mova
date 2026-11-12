import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/routine_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/steps_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/screens/today/today_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime.utc(2026, 11, 5, 12);

PlanDay _day({
  required int weekday,
  required String name,
  required List<String> muscles,
  required int minutes,
  int exercises = 6,
}) {
  return PlanDay(
    id: 'day-$weekday',
    weekday: weekday,
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

TrainingPlan _plan({
  DateTime? generatedAt,
  bool fallback = false,
  List<PlanDay>? days,
}) {
  final resolvedDays =
      days ??
      <PlanDay>[
        _day(
          weekday: 1,
          name: 'Push Day',
          muscles: const <String>['Chest', 'Shoulders', 'Triceps'],
          minutes: 55,
        ),
        _day(
          weekday: 3,
          name: 'Pull Day',
          muscles: const <String>['Back', 'Biceps'],
          minutes: 50,
          exercises: 5,
        ),
        _day(
          weekday: 5,
          name: 'Leg Day',
          muscles: const <String>['Quads', 'Hamstrings', 'Glutes'],
          minutes: 60,
        ),
      ];
  return TrainingPlan(
    id: 'plan-1',
    goal: Goal.buildMuscle,
    goals: const <Goal>[Goal.buildMuscle],
    experienceLevel: ExperienceLevel.gymRat,
    daysPerWeek: resolvedDays.length,
    trainingDays: resolvedDays.map((day) => day.weekday).toList(),
    splitName: fallback ? 'Starter plan' : 'Push pull legs',
    days: resolvedDays,
    generatedAt: generatedAt ?? _now,
    isFallback: fallback,
  );
}

PlanProvider _provider() {
  return PlanProvider(
    StorageService.inMemory(),
    loadExercises: () async => const [],
    clock: FakeClock(_now),
  );
}

Widget _wrap(
  PlanProvider provider, {
  Clock? clock,
  WorkoutProvider? workout,
  SettingsProvider? settings,
  ProgressProvider? progress,
}) {
  final activeClock = clock ?? FakeClock(_now);
  final storage = StorageService.inMemory();
  final workoutProvider =
      workout ?? WorkoutProvider(StorageService.inMemory(), clock: activeClock);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PlanProvider>.value(value: provider),
      ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
      if (progress != null)
        ChangeNotifierProvider<ProgressProvider>.value(value: progress),
      if (settings != null)
        ChangeNotifierProvider<SettingsProvider>.value(value: settings)
      else
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storage),
        ),
      ChangeNotifierProvider<RoutineProvider>(
        create: (_) => RoutineProvider(storage),
      ),
      ChangeNotifierProvider<StepsProvider>(
        create: (_) => StepsProvider(storage, clock: activeClock),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      routes: <String, WidgetBuilder>{
        Routes.logger: (_) => const Scaffold(body: Text('Logger route')),
        Routes.routines: (_) => const Scaffold(body: Text('Routines route')),
        Routes.meSettings: (_) => const Scaffold(body: Text('Settings route')),
      },
      home: TodayScreen(clock: activeClock),
    ),
  );
}

void main() {
  testWidgets('planned state shows the workout for today', (tester) async {
    final provider = _provider();
    await provider.replacePlan(
      _plan(
        days: <PlanDay>[
          _day(
            weekday: 4,
            name: 'Push Day',
            muscles: const <String>['Chest', 'Shoulders', 'Triceps'],
            minutes: 55,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('Thursday'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Next up'), findsOneWidget);
    expect(find.text('Start your rotation with Day 1.'), findsOneWidget);
    expect(find.text('Chest · Shoulders · Triceps'), findsOneWidget);
    expect(find.text('6 exercises · ~55 min'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('training days'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
  });

  testWidgets('unlogged days still suggest the next rotation session', (
    tester,
  ) async {
    final provider = _provider();
    await provider.replacePlan(_plan());

    await tester.pumpWidget(_wrap(provider));

    expect(find.byKey(const Key('today-next-up')), findsOneWidget);
    expect(find.text('Next up'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Rest day'), findsNothing);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('no-plan state starts tracking without a rotation', (
    tester,
  ) async {
    final provider = _provider();

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('Thursday'), findsOneWidget);
    expect(find.textContaining('No rotation needed'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('Choose saved workout'), findsOneWidget);
    expect(find.text('Streak badges'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
  });

  testWidgets('storage warnings are dismissible', (tester) async {
    final provider = _provider();
    await provider.replacePlan(_plan());
    final storage = StorageService.inMemory();
    storage.warning = 'Some saved data could not be read and was reset.';
    final settings = SettingsProvider(storage);

    await tester.pumpWidget(_wrap(provider, settings: settings));

    expect(find.byKey(const Key('today-storage-warning')), findsOneWidget);
    expect(
      find.text('Some saved data could not be read and was reset.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('today-storage-warning-dismiss')));
    await tester.pump();

    expect(find.byKey(const Key('today-storage-warning')), findsNothing);
  });

  testWidgets('shows the current streak in the header', (tester) async {
    final provider = _provider();
    await provider.replacePlan(
      _plan(
        days: <PlanDay>[
          _day(
            weekday: 4,
            name: 'Push Day',
            muscles: const <String>['Chest'],
            minutes: 55,
          ),
        ],
      ),
    );
    final storage = StorageService.inMemory();
    await storage.writeList(kWorkoutsKey, <Map<String, dynamic>>[
      WorkoutSession(
        id: 'recent',
        name: 'Push Day',
        source: SessionSource.plan,
        startedAt: DateTime(2026, 11, 5, 17, 20),
        completedAt: DateTime(2026, 11, 5, 18),
        status: SessionStatus.completed,
        exercises: const <SessionExercise>[],
      ).toJson(),
    ]);
    final progress = ProgressProvider(storage, clock: FakeClock(_now));
    await progress.load();

    await tester.pumpWidget(_wrap(provider, progress: progress));

    expect(find.byKey(const Key('today-streak')), findsOneWidget);
    expect(find.text('1 day streak'), findsOneWidget);
  });

  testWidgets('header shows the weekday without a week counter', (
    tester,
  ) async {
    final provider = _provider();
    await provider.replacePlan(
      _plan(
        generatedAt: DateTime.utc(2026, 10, 22, 12),
        days: <PlanDay>[
          _day(
            weekday: 4,
            name: 'Push Day',
            muscles: const <String>['Chest'],
            minutes: 55,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('Thursday'), findsOneWidget);
    expect(find.textContaining('Week 3'), findsNothing);
  });

  testWidgets('fallback plans are labelled Starter', (tester) async {
    final provider = _provider();
    await provider.replacePlan(_plan(fallback: true));

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('Starter'), findsOneWidget);
    expect(find.text('plan'), findsOneWidget);
  });

  testWidgets('start workout creates a plan session and opens the logger', (
    tester,
  ) async {
    final provider = _provider();
    await provider.replacePlan(
      _plan(
        days: <PlanDay>[
          _day(
            weekday: 4,
            name: 'Push Day',
            muscles: const <String>['Chest'],
            minutes: 55,
          ),
        ],
      ),
    );
    final workout = WorkoutProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
    );

    await tester.pumpWidget(_wrap(provider, workout: workout));
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    expect(workout.activeSession?.name, 'Push Day');
    expect(workout.activeSession?.source, SessionSource.plan);
    expect(workout.activeSession?.status, SessionStatus.active);
    expect(find.text('Logger route'), findsOneWidget);
  });

  testWidgets('no-plan start workout starts an empty session', (tester) async {
    final provider = _provider();
    final workout = WorkoutProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
    );

    await tester.pumpWidget(_wrap(provider, workout: workout));
    await tester.tap(find.byKey(const Key('today-start-workout')));
    await tester.pumpAndSettle();

    expect(workout.activeSession?.name, 'Empty workout');
    expect(workout.activeSession?.source, SessionSource.empty);
    expect(find.text('Logger route'), findsOneWidget);
  });

  testWidgets('rest day quick actions start a walk', (tester) async {
    final provider = _provider();
    await provider.replacePlan(_plan());
    final workout = WorkoutProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
    );

    await tester.pumpWidget(_wrap(provider, workout: workout));
    await tester.tap(find.byKey(const Key('today-start-walk')));
    await tester.pumpAndSettle();

    expect(workout.activeSession?.name, 'Walk');
    expect(workout.activeSession?.source, SessionSource.walk);
    expect(find.text('Logger route'), findsOneWidget);
  });

  testWidgets('no-plan state offers positive tracking actions', (
    tester,
  ) async {
    final provider = _provider();

    await tester.pumpWidget(_wrap(provider));

    expect(find.textContaining('No rotation needed'), findsOneWidget);
    expect(find.text('Track your training'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('Choose saved workout'), findsOneWidget);
    expect(find.text('Streak badges'), findsOneWidget);
  });

  testWidgets('paused session shows resume and reopens the logger', (
    tester,
  ) async {
    final provider = _provider();
    await provider.replacePlan(
      _plan(
        days: <PlanDay>[
          _day(
            weekday: 4,
            name: 'Push Day',
            muscles: const <String>['Chest'],
            minutes: 55,
          ),
        ],
      ),
    );
    final workout = WorkoutProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
    );
    await workout.startFromPlanDay(
      _day(
        weekday: 4,
        name: 'Push Day',
        muscles: const <String>['Chest'],
        minutes: 55,
      ),
    );
    await workout.pause();

    await tester.pumpWidget(_wrap(provider, workout: workout));

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);

    await tester.tap(find.text('Resume workout'));
    await tester.pumpAndSettle();

    expect(workout.activeSession?.status, SessionStatus.active);
    expect(find.text('Logger route'), findsOneWidget);
  });

  testWidgets('steps card and reminder bell open their routes', (tester) async {
    final provider = _provider();
    await provider.replacePlan(
      _plan(
        days: <PlanDay>[
          _day(
            weekday: 4,
            name: 'Push Day',
            muscles: const <String>['Chest'],
            minutes: 55,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No steps yet'), findsOneWidget);
    expect(find.byKey(const Key('today-add-steps')), findsOneWidget);
    expect(find.byKey(const Key('today-reminders')), findsOneWidget);

    await tester.tap(find.byKey(const Key('today-reminders')));
    await tester.pumpAndSettle();

    expect(find.text('Settings route'), findsOneWidget);
  });

  testWidgets('rolls over to the next day at midnight', (tester) async {
    final provider = _provider();
    final clock = FakeClock(DateTime.utc(2026, 11, 5, 23, 59, 30));
    await provider.replacePlan(
      _plan(
        days: <PlanDay>[
          _day(
            weekday: 4,
            name: 'Push Day',
            muscles: const <String>['Chest'],
            minutes: 55,
          ),
          _day(
            weekday: 5,
            name: 'Leg Day',
            muscles: const <String>['Quads'],
            minutes: 60,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_wrap(provider, clock: clock));
    expect(find.text('Thursday'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);

    clock.advance(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));

    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Leg Day'), findsNothing);
  });

  testWidgets('stored plan changes rebuild the screen', (tester) async {
    final provider = _provider();
    await provider.replacePlan(
      _plan(
        days: <PlanDay>[
          _day(
            weekday: 4,
            name: 'Push Day',
            muscles: const <String>['Chest'],
            minutes: 55,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_wrap(provider));
    expect(find.text('Push Day'), findsOneWidget);

    await provider.replacePlan(_plan());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('today-next-up')), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Rest day'), findsNothing);
  });

  testWidgets('a moved plan day appears on Today', (tester) async {
    final provider = _provider();
    await provider.replacePlan(
      _plan(
        days: <PlanDay>[
          _day(
            weekday: 4,
            name: 'Push Day',
            muscles: const <String>['Chest'],
            minutes: 55,
          ),
        ],
      ),
    );
    await tester.pumpWidget(_wrap(provider));

    expect(find.text('Thursday'), findsOneWidget);
    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Next up'), findsOneWidget);
  });

  testWidgets('choose another session lists options and starts empty', (
    tester,
  ) async {
    final provider = _provider();
    final workout = WorkoutProvider(
      StorageService.inMemory(),
      clock: FakeClock(_now),
    );
    await provider.replacePlan(_plan());
    await tester.pumpWidget(_wrap(provider, workout: workout));

    final choose = find.byKey(const Key('today-choose-session'));
    await tester.ensureVisible(choose);
    await tester.tap(choose);
    await tester.pumpAndSettle();

    expect(find.text('Choose another session'), findsNWidgets(2));
    expect(find.byKey(const Key('choose-session-sheet')), findsOneWidget);
    expect(find.byKey(const Key('choose-session-day-0')), findsOneWidget);
    expect(find.byKey(const Key('choose-session-day-2')), findsOneWidget);
    expect(find.byKey(const Key('choose-session-empty')), findsOneWidget);
    expect(find.byKey(const Key('choose-session-walk')), findsOneWidget);

    await tester.tap(find.byKey(const Key('choose-session-empty')));
    await tester.pumpAndSettle();

    expect(workout.activeSession?.displayTitle, 'Empty workout');
    expect(find.byKey(const Key('choose-session-sheet')), findsNothing);
    expect(find.text('Logger route'), findsOneWidget);
  });
}
