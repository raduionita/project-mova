import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/activity_post.dart';
import 'package:mova/models/personal_record.dart';
import 'package:mova/models/session_exercise.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/models/workout_session.dart';
import 'package:mova/models/workout_set.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/providers/history_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/social_provider.dart';
import 'package:mova/screens/social/social_feed_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/share_card_service.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
final FakeClock _clock = FakeClock(_now);

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

const String _onePixelPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

class _FakeShareCardService extends ShareCardService {
  int renderCalls = 0;

  @override
  Future<Uint8List?> render(
    WorkoutSession session, {
    PersonalRecord? record,
    String Function(String exerciseId)? exerciseName,
    WeightUnit weightUnit = WeightUnit.kg,
  }) async {
    renderCalls++;
    return base64Decode(_onePixelPng);
  }

  @override
  Future<ShareResult> share(
    Uint8List bytes, {
    ui.Rect? origin,
    String fileName = 'mova-card.png',
  }) async {
    return const ShareResult(shared: true);
  }
}

WorkoutSession _session(String id) {
  return WorkoutSession(
    id: id,
    name: 'Push Day',
    source: SessionSource.plan,
    startedAt: _now.subtract(const Duration(minutes: 40)),
    completedAt: _now,
    status: SessionStatus.completed,
    exercises: <SessionExercise>[
      SessionExercise(
        id: 'exercise-$id',
        exerciseId: 'barbell-bench-press',
        order: 0,
        sets: <WorkoutSet>[
          WorkoutSet(
            id: 'set-$id',
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

ActivityPost _ownPost({String sessionId = 'session-1'}) {
  return ActivityPost(
    id: 'own-1',
    authorName: 'Athlete',
    isOwn: true,
    sessionId: sessionId,
    text: 'Completed Push Day. 1 set, 500 kg volume.',
    createdAt: _now,
  );
}

class _Harness {
  _Harness(this.storage)
    : social = SocialProvider(storage, SeedDataService(), clock: _clock),
      settings = SettingsProvider(storage),
      history = HistoryProvider(storage),
      progress = ProgressProvider(storage, clock: _clock),
      exercises = ExerciseProvider(
        storage,
        SeedDataService(bundle: _FakeBundle()),
        clock: _clock,
      );

  final StorageService storage;
  final SocialProvider social;
  final SettingsProvider settings;
  final HistoryProvider history;
  final ProgressProvider progress;
  final ExerciseProvider exercises;

  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      settings.load(),
      history.load(),
      progress.load(),
      exercises.load(),
    ]);
    social.setPlaceholderDismissed(settings.settings.sampleFeedDismissed);
    await social.load();
  }

  Widget wrap(Widget home, {ShareCardService? shareCardService}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SocialProvider>.value(value: social),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<HistoryProvider>.value(value: history),
        ChangeNotifierProvider<ProgressProvider>.value(value: progress),
        ChangeNotifierProvider<ExerciseProvider>.value(value: exercises),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: home),
    );
  }
}

Future<_Harness> _pumpFeed(
  WidgetTester tester, {
  bool postWorkoutsToFeed = true,
  bool withOwnPost = false,
  bool seedHistory = false,
  ShareCardService? shareCardService,
}) async {
  final storage = StorageService.inMemory();
  if (seedHistory) {
    await storage.writeList(kWorkoutsKey, <Map<String, dynamic>>[
      _session('session-1').toJson(),
    ]);
  }
  final harness = _Harness(storage);
  await harness.load();
  await harness.settings.setPostWorkoutsToFeed(postWorkoutsToFeed);
  if (withOwnPost) {
    await harness.social.addPost(_ownPost());
  }
  await tester.pumpWidget(
    harness.wrap(
      SocialFeedScreen(
        clock: _clock,
        shareCardService: shareCardService ?? const ShareCardService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders one faded placeholder post', (tester) async {
    await _pumpFeed(tester);

    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Mova Coach'), findsOneWidget);
    expect(find.text('Placeholder'), findsOneWidget);
    expect(find.byKey(const Key('feed-placeholder')), findsOneWidget);
    expect(find.text('Hide placeholder'), findsOneWidget);
    expect(find.text('Sample'), findsNothing);
    expect(find.text('Posts and kudos stay on this device.'), findsOneWidget);
    expect(
      find.text(
        'Welcome to Mova. Finish your first workout and your post will '
        'appear here.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('hides the placeholder and persists the dismissal', (
    tester,
  ) async {
    final harness = await _pumpFeed(tester);

    await tester.tap(find.byKey(const Key('hide-samples')));
    await tester.pumpAndSettle();

    expect(find.text('Placeholder'), findsNothing);
    expect(find.text('Your feed is quiet'), findsOneWidget);
    expect(harness.settings.settings.sampleFeedDismissed, isTrue);
    expect(harness.social.posts, isEmpty);
  });

  testWidgets('kudos toggles and persists', (tester) async {
    final harness = await _pumpFeed(tester, withOwnPost: true);

    expect(find.byKey(const Key('kudos-own-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('kudos-own-1')));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(harness.social.posts.first.kudosGiven, isTrue);
  });

  testWidgets('an own post shows the You tag and workout actions', (
    tester,
  ) async {
    await _pumpFeed(tester, withOwnPost: true);

    expect(find.text('You'), findsOneWidget);
    expect(find.text('View workout'), findsOneWidget);
    expect(
      find.text('Completed Push Day. 1 set, 500 kg volume.'),
      findsOneWidget,
    );
  });

  testWidgets('own posts disappear when workout sharing is off', (
    tester,
  ) async {
    await _pumpFeed(tester, postWorkoutsToFeed: false, withOwnPost: true);

    expect(find.text('You'), findsNothing);
    expect(find.text('View workout'), findsNothing);
    expect(find.text('Mova Coach'), findsNothing);
    expect(find.text('Your feed is quiet'), findsOneWidget);
  });

  testWidgets('the empty feed offers a start action', (tester) async {
    final storage = StorageService.inMemory();
    final harness = _Harness(storage);
    await harness.load();
    await harness.settings.dismissSampleFeed();
    await harness.social.dismissPlaceholder();
    await tester.pumpWidget(harness.wrap(SocialFeedScreen(clock: _clock)));
    await tester.pumpAndSettle();

    expect(find.text('Your feed is quiet'), findsOneWidget);
    expect(find.text('Start a workout'), findsOneWidget);
  });

  testWidgets('the own post share action opens the card sheet', (tester) async {
    final service = _FakeShareCardService();
    await _pumpFeed(
      tester,
      withOwnPost: true,
      seedHistory: true,
      shareCardService: service,
    );

    await tester.tap(find.byKey(const Key('share-post-own-1')));
    await tester.pumpAndSettle();

    expect(service.renderCalls, 1);
    expect(find.text('Share card'), findsOneWidget);
  });
}
