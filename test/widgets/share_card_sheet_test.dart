import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/share_card_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/share_card_sheet.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime.utc(2026, 11, 6, 12);

const String _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

const String _exerciseJson = '''
[
  {
    "id": "barbell-bench-press",
    "name": "Barbell Bench Press",
    "primaryMuscle": "Chest",
    "secondaryMuscles": ["Triceps"],
    "equipment": "Barbell",
    "instructions": ["Press the bar."],
    "isCompound": true
  }
]
''';

class _FakeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData(0);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return _exerciseJson;
  }
}

class _FakeShareCardService extends ShareCardService {
  _FakeShareCardService({
    this.result = const ShareResult(shared: true),
    this.renderNull = false,
  });

  final ShareResult result;
  final bool renderNull;
  int renderCalls = 0;
  int shareCalls = 0;

  @override
  Future<Uint8List?> render(
    WorkoutSession session, {
    PersonalRecord? record,
    String Function(String exerciseId)? exerciseName,
    WeightUnit weightUnit = WeightUnit.kg,
  }) async {
    renderCalls++;
    if (renderNull) {
      return null;
    }
    return base64Decode(_onePixelPng);
  }

  @override
  Future<ShareResult> share(
    Uint8List bytes, {
    ui.Rect? origin,
    String fileName = 'mova-card.png',
  }) async {
    shareCalls++;
    return result;
  }
}

WorkoutSession _session() {
  return WorkoutSession(
    id: 'session-1',
    name: 'Push Day',
    source: SessionSource.plan,
    startedAt: _now.subtract(const Duration(minutes: 40)),
    completedAt: _now,
    status: SessionStatus.completed,
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
            completedAt: _now,
          ),
        ],
      ),
    ],
  );
}

Future<void> _pumpSheet(
  WidgetTester tester,
  _FakeShareCardService service,
) async {
  final storage = StorageService.inMemory();
  final library = ExerciseProvider(
    storage,
    SeedDataService(bundle: _FakeBundle()),
    clock: null,
  );
  await library.load();
  final settings = SettingsProvider(storage);
  await settings.load();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ExerciseProvider>.value(value: library),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => ShareCardSheet.show(
                    context,
                    session: _session(),
                    service: service,
                  ),
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders a preview and shares the card', (tester) async {
    final service = _FakeShareCardService();
    await _pumpSheet(tester, service);

    expect(find.text('Share card'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(service.renderCalls, 1);

    await tester.tap(find.text('Share'));
    await _settle(tester);

    expect(service.shareCalls, 1);
    expect(find.text('Share card'), findsNothing);
  });

  testWidgets('a cancel result keeps the sheet open without an error', (
    tester,
  ) async {
    final service = _FakeShareCardService(
      result: const ShareResult(shared: false),
    );
    await _pumpSheet(tester, service);

    await tester.tap(find.text('Share'));
    await _settle(tester);

    expect(service.shareCalls, 1);
    expect(find.text('Share card'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a share error shows a snackbar and keeps the sheet open', (
    tester,
  ) async {
    final service = _FakeShareCardService(
      result: const ShareResult(shared: false, error: 'Denied'),
    );
    await _pumpSheet(tester, service);

    await tester.tap(find.text('Share'));
    await _settle(tester);

    expect(find.textContaining('Could not share the card'), findsOneWidget);
    expect(find.text('Share card'), findsOneWidget);
  });

  testWidgets('a missing render shows the retry path', (tester) async {
    final service = _FakeShareCardService(renderNull: true);
    await _pumpSheet(tester, service);

    expect(find.text('Could not render the share card.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await _settle(tester);

    expect(service.renderCalls, 2);
  });
}
