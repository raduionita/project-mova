import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/app_settings.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/routine_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/screens/calendar/calendar_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/calendar_day_cell.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 12, 12);
final FakeClock _clock = FakeClock(_now);

TrainingPlan _plan() {
  return TrainingPlan(
    id: 'plan-1',
    goal: Goal.buildMuscle,
    experienceLevel: ExperienceLevel.beginner,
    daysPerWeek: 3,
    splitName: 'Push Pull Legs',
    days: const <PlanDay>[
      PlanDay(
        id: 'day-push',
        order: 0,
        slotKey: 'push',
        name: 'Push',
        muscleGroups: <String>['Chest', 'Shoulders'],
        estimatedMinutes: 45,
        exercises: <PlanExercise>[],
      ),
      PlanDay(
        id: 'day-pull',
        order: 1,
        slotKey: 'pull',
        name: 'Pull',
        muscleGroups: <String>['Back', 'Biceps'],
        estimatedMinutes: 45,
        exercises: <PlanExercise>[],
      ),
      PlanDay(
        id: 'day-legs',
        order: 2,
        slotKey: 'legs',
        name: 'Legs',
        muscleGroups: <String>['Quads', 'Hamstrings'],
        estimatedMinutes: 50,
        exercises: <PlanExercise>[],
      ),
    ],
    generatedAt: DateTime(2026, 11, 1),
  );
}

WorkoutSession _session({
  required String id,
  required String title,
  required String sourceLabel,
  required SessionSource source,
  required DateTime startedAt,
  String? slotKey,
  bool withSet = true,
}) {
  return WorkoutSession(
    id: id,
    name: title,
    displayTitle: title,
    sourceLabel: sourceLabel,
    source: source,
    slotKey: slotKey,
    muscleGroups: const <String>['Chest'],
    startedAt: startedAt,
    completedAt: startedAt.add(const Duration(minutes: 45)),
    status: SessionStatus.completed,
    exercises: withSet
        ? <SessionExercise>[
            SessionExercise(
              id: 'exercise-$id',
              exerciseId: 'barbell-bench-press',
              order: 0,
              primaryMuscle: 'Chest',
              sets: <WorkoutSet>[
                WorkoutSet(
                  id: 'set-$id',
                  index: 0,
                  weightKg: 100,
                  reps: 5,
                  completed: true,
                ),
              ],
            ),
          ]
        : const <SessionExercise>[],
  );
}

List<WorkoutSession> _history() {
  return <WorkoutSession>[
    _session(
      id: 'plan-1',
      title: 'Push',
      sourceLabel: 'Plan',
      source: SessionSource.plan,
      startedAt: DateTime(2026, 11, 5, 18),
      slotKey: 'push',
    ),
    _session(
      id: 'routine-1',
      title: 'Upper',
      sourceLabel: 'Routine',
      source: SessionSource.routine,
      startedAt: DateTime(2026, 11, 6, 10),
    ),
    _session(
      id: 'walk-1',
      title: 'Walk',
      sourceLabel: 'Walk',
      source: SessionSource.walk,
      startedAt: DateTime(2026, 11, 6, 12),
      withSet: false,
    ),
    _session(
      id: 'today-1',
      title: 'Push',
      sourceLabel: 'Plan',
      source: SessionSource.plan,
      startedAt: DateTime(2026, 11, 12, 8),
      slotKey: 'push',
    ),
  ];
}

class _Setup {
  const _Setup({
    required this.settings,
    required this.history,
    required this.plan,
    required this.routines,
    required this.workout,
  });

  final SettingsProvider settings;
  final HistoryProvider history;
  final PlanProvider plan;
  final RoutineProvider routines;
  final WorkoutProvider workout;
}

Future<_Setup> _setup({
  bool withPlan = true,
  List<WorkoutSession>? sessions,
  int? weekStart = DateTime.monday,
}) async {
  final storage = StorageService.inMemory();
  if (weekStart != null) {
    await storage.writeObject(
      kSettingsKey,
      AppSettings(weekStart: weekStart).toJson(),
    );
  }
  await storage.writeList(
    kWorkoutsKey,
    (sessions ?? _history())
        .map((session) => session.toJson())
        .toList(growable: false),
  );
  if (withPlan) {
    await storage.writeObject(kPlanKey, _plan().toJson());
  }

  final settings = SettingsProvider(storage);
  final history = HistoryProvider(storage);
  final plan = PlanProvider(
    storage,
    loadExercises: () async => const <Exercise>[],
    clock: _clock,
  );
  final routines = RoutineProvider(storage);
  final workout = WorkoutProvider(storage, clock: _clock);
  await settings.load();
  await history.load();
  await plan.load();
  await routines.load();
  return _Setup(
    settings: settings,
    history: history,
    plan: plan,
    routines: routines,
    workout: workout,
  );
}

Widget _wrap(_Setup setup, {NavigatorObserver? observer}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: setup.settings),
      ChangeNotifierProvider<HistoryProvider>.value(value: setup.history),
      ChangeNotifierProvider<PlanProvider>.value(value: setup.plan),
      ChangeNotifierProvider<RoutineProvider>.value(value: setup.routines),
      ChangeNotifierProvider<WorkoutProvider>.value(value: setup.workout),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      navigatorObservers: observer == null
          ? const <NavigatorObserver>[]
          : <NavigatorObserver>[observer],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(
          body: Center(child: Text('route:${settings.name}')),
        ),
      ),
      home: CalendarScreen(clock: _clock),
    ),
  );
}

CalendarDayCell _cellFor(WidgetTester tester, DateTime date) {
  return tester.widget<CalendarDayCell>(
    find.byWidgetPredicate(
      (widget) =>
          widget is CalendarDayCell &&
          widget.date.year == date.year &&
          widget.date.month == date.month &&
          widget.date.day == date.day,
    ),
  );
}

Future<void> _openDay(WidgetTester tester, DateTime date) async {
  final key =
      'calendar-day-${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

class _RecordingObserver extends NavigatorObserver {
  final List<String?> names = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    names.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the month grid and week starts on Monday', (
    tester,
  ) async {
    final setup = await _setup();
    await tester.pumpWidget(_wrap(setup));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-screen')), findsOneWidget);
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.byType(CalendarDayCell), findsNWidgets(30));

    final labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('calendar-weekdays')),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toList(growable: false);
    expect(labels, <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']);
  });

  testWidgets('a Sunday week start reorders the weekday row', (tester) async {
    final setup = await _setup(weekStart: DateTime.sunday);
    await tester.pumpWidget(_wrap(setup));
    await tester.pumpAndSettle();

    final labels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const Key('calendar-weekdays')),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .toList(growable: false);
    expect(labels, <String>['S', 'M', 'T', 'W', 'T', 'F', 'S']);
  });

  testWidgets('marks logged, today, and suggested days', (tester) async {
    final setup = await _setup();
    await tester.pumpWidget(_wrap(setup));
    await tester.pumpAndSettle();

    expect(_cellFor(tester, DateTime(2026, 11, 6)).sessions, hasLength(2));
    expect(_cellFor(tester, DateTime(2026, 11, 12)).isToday, isTrue);
    expect(find.byKey(const Key('calendar-today-check')), findsOneWidget);

    final firstSuggestion = _cellFor(tester, DateTime(2026, 11, 14));
    expect(firstSuggestion.isSuggested, isTrue);
    expect(firstSuggestion.suggestedName, 'Pull');
    expect(_cellFor(tester, DateTime(2026, 11, 16)).suggestedName, 'Legs');
    expect(_cellFor(tester, DateTime(2026, 11, 18)).suggestedName, 'Push');
    expect(_cellFor(tester, DateTime(2026, 11, 20)).isSuggested, isFalse);
  });

  testWidgets('legend explains the dashed suggestion marker', (tester) async {
    final setup = await _setup();
    await tester.pumpWidget(_wrap(setup));
    await tester.pumpAndSettle();

    final legend = find.byKey(const Key('calendar-legend-suggested'));
    expect(legend, findsOneWidget);
    expect(
      find.descendant(of: legend, matching: find.text('Suggested')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: legend, matching: find.byType(CustomPaint)),
      findsWidgets,
    );
  });

  testWidgets('past logged day lists each session', (tester) async {
    final setup = await _setup();
    await tester.pumpWidget(_wrap(setup));
    await tester.pumpAndSettle();

    await _openDay(tester, DateTime(2026, 11, 6));

    expect(find.byKey(const Key('calendar-day-sheet')), findsOneWidget);
    expect(find.text('2 workouts logged'), findsOneWidget);
    expect(find.text('Upper'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('calendar-day-sheet')),
        matching: find.text('Walk'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('500 kg'), findsOneWidget);
    expect(
      find.byKey(const Key('calendar-day-start-workout')),
      findsNothing,
    );
  });

  testWidgets('past empty day reads as rest with no workout logged', (
    tester,
  ) async {
    final setup = await _setup();
    await tester.pumpWidget(_wrap(setup));
    await tester.pumpAndSettle();

    await _openDay(tester, DateTime(2026, 11, 9));

    expect(find.text('Rest day'), findsOneWidget);
    expect(find.textContaining('No workout logged'), findsOneWidget);
    expect(
      find.byKey(const Key('calendar-day-start-workout')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('calendar-day-start-suggestion')),
      findsNothing,
    );
  });

  testWidgets('today lists workouts and still offers Start workout', (
    tester,
  ) async {
    final setup = await _setup();
    await tester.pumpWidget(_wrap(setup));
    await tester.pumpAndSettle();

    await _openDay(tester, DateTime(2026, 11, 12));

    expect(find.text('1 workout logged'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget);
    expect(
      find.byKey(const Key('calendar-day-start-workout')),
      findsOneWidget,
    );
  });

  testWidgets('suggested day offers view and start', (tester) async {
    final setup = await _setup();
    await tester.pumpWidget(_wrap(setup));
    await tester.pumpAndSettle();

    await _openDay(tester, DateTime(2026, 11, 14));

    expect(find.text('Suggested week'), findsNothing);
    expect(find.text('Suggested session'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('calendar-day-sheet')),
        matching: find.text('Suggested'),
      ),
      findsOneWidget,
    );
    expect(find.text('Pull'), findsOneWidget);
    expect(
      find.byKey(const Key('calendar-day-view-suggestion')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('calendar-day-start-suggestion')),
      findsOneWidget,
    );
  });

  testWidgets('month navigation moves and returns to today', (tester) async {
    final setup = await _setup();
    await tester.pumpWidget(_wrap(setup));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calendar-next-month')));
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);
    expect(find.byType(CalendarDayCell), findsNWidgets(31));

    await tester.tap(find.byKey(const Key('calendar-today')));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-prev-month')));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.byType(CalendarDayCell), findsNWidgets(31));
  });

  testWidgets('header actions open plan and exercises', (tester) async {
    final setup = await _setup();
    final observer = _RecordingObserver();
    await tester.pumpWidget(_wrap(setup, observer: observer));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calendar-plan')));
    await tester.pumpAndSettle();
    expect(observer.names, contains('/plan'));

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('calendar-exercises')));
    await tester.pumpAndSettle();
    expect(observer.names, contains('/exercises'));
  });
}
