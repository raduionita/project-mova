import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/plan_day.dart';
import 'package:mova/models/plan_exercise.dart';
import 'package:mova/models/training_plan.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/providers/plan_provider.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/plan_overview_sheet.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
final FakeClock _clock = FakeClock(_now);

PlanDay _day(int weekday, String name) {
  return PlanDay(
    id: 'day-$weekday',
    weekday: weekday,
    name: name,
    muscleGroups: const <String>['Chest'],
    estimatedMinutes: 50,
    exercises: const <PlanExercise>[
      PlanExercise(
        exerciseId: 'back-squat',
        sets: 3,
        repsLow: 8,
        repsHigh: 12,
        restSeconds: 90,
        order: 0,
      ),
    ],
  );
}

TrainingPlan _plan() {
  return TrainingPlan(
    id: 'plan-1',
    goal: Goal.buildMuscle,
    goals: const <Goal>[Goal.buildMuscle],
    experienceLevel: ExperienceLevel.regular,
    daysPerWeek: 3,
    trainingDays: const <int>[1, 3, 5],
    splitName: 'Push pull legs',
    days: <PlanDay>[
      _day(1, 'Push Day'),
      _day(3, 'Pull Day'),
      _day(5, 'Leg Day'),
    ],
    generatedAt: _now,
  );
}

Future<PlanProvider> _provider(StorageService storage) async {
  final provider = PlanProvider(
    storage,
    loadExercises: () async => const <Exercise>[
      Exercise(
        id: 'back-squat',
        name: 'Back Squat',
        primaryMuscle: 'Quads',
        equipment: 'Barbell',
        isCompound: true,
      ),
      Exercise(
        id: 'barbell-bench-press',
        name: 'Barbell Bench Press',
        primaryMuscle: 'Chest',
        equipment: 'Barbell',
        isCompound: true,
      ),
    ],
    clock: _clock,
  );
  await provider.replacePlan(_plan());
  return provider;
}

class _Launcher extends StatelessWidget {
  const _Launcher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: TextButton(
              onPressed: () => PlanOverviewSheet.show(context),
              child: const Text('Open plan'),
            ),
          );
        },
      ),
    );
  }
}

Widget _wrap(PlanProvider provider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PlanProvider>.value(value: provider),
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(StorageService.inMemory()),
      ),
    ],
    child: MaterialApp(theme: AppTheme.dark, home: const _Launcher()),
  );
}

void main() {
  testWidgets('movePlanDay moves the whole split day to a rest weekday', (
    tester,
  ) async {
    final provider = await _provider(StorageService.inMemory());
    await tester.pumpWidget(_wrap(provider));
    await tester.tap(find.text('Open plan'));
    await tester.pumpAndSettle();

    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Rest'), findsNWidgets(4));

    await tester.ensureVisible(find.byKey(const Key('plan-from-1')));
    await tester.tap(find.byKey(const Key('plan-from-1')));
    await tester.ensureVisible(find.byKey(const Key('plan-to-2')));
    await tester.tap(find.byKey(const Key('plan-to-2')));
    await tester.ensureVisible(find.byKey(const Key('plan-move-submit')));
    await tester.tap(find.byKey(const Key('plan-move-submit')));
    await tester.pumpAndSettle();

    expect(provider.plan!.trainingDays, <int>[2, 3, 5]);
    final moved = provider.plan!.days.firstWhere((day) => day.weekday == 2);
    expect(moved.name, 'Push Day');
    expect(moved.exercises, hasLength(1));
    expect(find.text('Monday moved to Tuesday.'), findsOneWidget);
  });

  testWidgets('regenerate keeps history and PRs intact', (tester) async {
    final storage = StorageService.inMemory();
    await storage.writeList(kWorkoutsKey, <Map<String, dynamic>>[
      WorkoutSession(
        id: 'session-1',
        name: 'Workout',
        source: SessionSource.empty,
        startedAt: _now.subtract(const Duration(minutes: 40)),
        completedAt: _now,
        status: SessionStatus.completed,
        exercises: const [],
      ).toJson(),
    ]);
    await storage.writeMap(kPrsKey, <String, Map<String, dynamic>>{
      'back-squat': PersonalRecord(
        exerciseId: 'back-squat',
        bestE1rmKg: 160,
        weightKg: 140,
        reps: 5,
        achievedAt: _now,
        sessionId: 'session-1',
        previousBestKg: 0,
      ).toJson(),
    });
    final provider = await _provider(storage);
    await tester.pumpWidget(_wrap(provider));
    await tester.tap(find.text('Open plan'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('plan-regenerate')));
    await tester.tap(find.byKey(const Key('plan-regenerate')));
    await tester.pumpAndSettle();
    expect(find.text('Regenerate plan?'), findsOneWidget);
    expect(
      find.textContaining('workout history, personal records, and streak'),
      findsOneWidget,
    );

    await tester.tap(find.text('Regenerate'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('History and PRs are unchanged'),
      findsOneWidget,
    );
    expect(
      storage.readList<WorkoutSession>(kWorkoutsKey, WorkoutSession.fromJson),
      hasLength(1),
    );
    expect(
      storage.readMap<PersonalRecord>(kPrsKey, PersonalRecord.fromJson),
      hasLength(1),
    );
    expect(provider.plan, isNotNull);
  });
}
