import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/weight_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/body_weight_sheet.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);
final FakeClock _clock = FakeClock(_now);

Future<StorageService> _storage({double bodyWeightKg = 80}) async {
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
  return storage;
}

Future<Widget> _wrap(
  StorageService storage, {
  required WeightProvider weights,
  required ProfileProvider profile,
}) async {
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
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => BodyWeightSheet.show(context),
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open sheet'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('calculates and saves a body weight expression', (tester) async {
    final storage = await _storage(bodyWeightKg: 0);
    final weights = WeightProvider(storage, clock: _clock);
    final profile = ProfileProvider(storage, clock: _clock);
    await tester.pumpWidget(
      await _wrap(storage, weights: weights, profile: profile),
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const ValueKey<String>('calc-key-8')));
    await tester.tap(find.byKey(const ValueKey<String>('calc-key-0')));
    await tester.tap(find.byKey(const ValueKey<String>('calc-key-+')));
    await tester.tap(find.byKey(const ValueKey<String>('calc-key-2')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('body-weight-calc-result')),
      findsOneWidget,
    );
    expect(find.text('= 82 kg'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('body-weight-save')));
    await tester.tap(find.byKey(const Key('body-weight-save')));
    await tester.pumpAndSettle();

    expect(weights.latest?.weightKg, 82);
    expect(profile.profile?.bodyWeightKg, 82);
    expect(find.byKey(const Key('body-weight-field')), findsNothing);
  });

  testWidgets('rejects an expression that does not evaluate', (tester) async {
    final storage = await _storage();
    final weights = WeightProvider(storage, clock: _clock);
    final profile = ProfileProvider(storage, clock: _clock);
    await tester.pumpWidget(
      await _wrap(storage, weights: weights, profile: profile),
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const ValueKey<String>('calc-key-9')));
    await tester.tap(find.byKey(const ValueKey<String>('calc-key-+')));
    await tester.tap(find.byKey(const ValueKey<String>('calc-key-equals')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid number.'), findsOneWidget);
    expect(weights.latest, isNull);
  });

  testWidgets('ignores a second decimal point in one number', (tester) async {
    final storage = await _storage(bodyWeightKg: 0);
    final weights = WeightProvider(storage, clock: _clock);
    final profile = ProfileProvider(storage, clock: _clock);
    await tester.pumpWidget(
      await _wrap(storage, weights: weights, profile: profile),
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const ValueKey<String>('calc-key-7')));
    await tester.tap(find.byKey(const ValueKey<String>('calc-key-.')));
    await tester.tap(find.byKey(const ValueKey<String>('calc-key-5')));
    await tester.tap(find.byKey(const ValueKey<String>('calc-key-.')));
    await tester.pumpAndSettle();

    expect(find.text('7.5'), findsOneWidget);
  });
}
