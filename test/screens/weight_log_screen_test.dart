import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/models/weight_entry.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/weight_provider.dart';
import 'package:mova/screens/progress/weight_log_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
final FakeClock _clock = FakeClock(_now);

Future<StorageService> _storage({
  List<WeightEntry> entries = const [],
  double bodyWeightKg = 80,
}) async {
  final storage = StorageService.inMemory();
  await storage.writeObject(
    kProfileKey,
    UserProfile(
      id: 'profile-1',
      bodyWeightKg: bodyWeightKg,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: _now,
    ).toJson(),
  );
  if (entries.isNotEmpty) {
    await storage.writeList(
      kWeightsKey,
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );
  }
  return storage;
}

Future<Widget> _wrap(StorageService storage) async {
  final weights = WeightProvider(storage, clock: _clock);
  final profile = ProfileProvider(storage, clock: _clock);
  final settings = SettingsProvider(storage);
  final progress = ProgressProvider(storage, clock: _clock);
  await Future.wait<void>(<Future<void>>[
    weights.load(),
    profile.load(),
    settings.load(),
    progress.load(),
  ]);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WeightProvider>.value(value: weights),
      ChangeNotifierProvider<ProfileProvider>.value(value: profile),
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<ProgressProvider>.value(value: progress),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: WeightLogScreen(clock: _clock),
    ),
  );
}

void main() {
  testWidgets('shows the current weight, trend, and history', (tester) async {
    final storage = await _storage(
      entries: <WeightEntry>[
        WeightEntry(
          dateKey: '2026-11-04',
          weightKg: 81,
          updatedAt: DateTime(2026, 11, 4),
        ),
        WeightEntry(
          dateKey: '2026-11-06',
          weightKg: 79.5,
          updatedAt: DateTime(2026, 11, 6),
        ),
      ],
    );
    await tester.pumpWidget(await _wrap(storage));
    await tester.pumpAndSettle();

    expect(find.text('Body weight'), findsOneWidget);
    expect(find.text('79.5 kg'), findsWidgets);
    expect(find.byKey(const Key('weight-log-chart')), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.byKey(const Key('weight-entry-2026-11-04')), findsOneWidget);
    expect(find.byKey(const Key('weight-log-delta')), findsOneWidget);
    expect(find.text('-1.5 kg'), findsOneWidget);
  });

  testWidgets('quick add logs today and updates the profile', (tester) async {
    final storage = await _storage(bodyWeightKg: 0);
    await tester.pumpWidget(await _wrap(storage));
    await tester.pumpAndSettle();

    expect(find.text('No weight entries'), findsOneWidget);
    await tester.tap(find.text('Add weight').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('body-weight-field')), '82');
    await tester.tap(find.text('Save body weight'));
    await tester.pumpAndSettle();

    final profile = storage.readObject<UserProfile>(
      kProfileKey,
      UserProfile.fromJson,
    );
    final entries = storage.readList<WeightEntry>(
      kWeightsKey,
      WeightEntry.fromJson,
    );
    expect(profile?.bodyWeightKg, 82);
    expect(entries.single.weightKg, 82);
    expect(find.text('82 kg'), findsWidgets);
    expect(find.byKey(const Key('weight-entry-2026-11-06')), findsOneWidget);
  });
}
