import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/weight_provider.dart';
import 'package:mova/screens/me/me_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 10, 12);
final FakeClock _clock = FakeClock(_now);

Future<StorageService> _storageWith(
  ExperienceLevel? level, {
  String displayName = 'Andrei',
  double bodyWeightKg = 0,
}) async {
  final storage = StorageService.inMemory();
  await storage.writeObject(
    kProfileKey,
    UserProfile(
      id: 'profile-1',
      displayName: displayName,
      experienceLevel: level,
      bodyWeightKg: bodyWeightKg,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: _now,
    ).toJson(),
  );
  return storage;
}

Future<Widget> _wrap(StorageService storage) async {
  final profile = ProfileProvider(storage, clock: _clock);
  await profile.load();
  final progress = ProgressProvider(storage, clock: _clock);
  await progress.load();
  final settings = SettingsProvider(storage);
  await settings.load();
  final weights = WeightProvider(storage, clock: _clock);
  await weights.load();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProfileProvider>.value(value: profile),
      ChangeNotifierProvider<ProgressProvider>.value(value: progress),
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<WeightProvider>.value(value: weights),
    ],
    child: MaterialApp(theme: AppTheme.dark, home: const MeScreen()),
  );
}

AppIcon _avatarIcon(WidgetTester tester) {
  return tester.widget<AppIcon>(find.byKey(const Key('me-avatar-icon')));
}

void main() {
  testWidgets('avatar shows the icon picked on the experience step', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _wrap(await _storageWith(ExperienceLevel.gymRat)),
    );
    await tester.pump();

    expect(_avatarIcon(tester).asset, AppIcons.flame);
    expect(_avatarIcon(tester).size, 32);
  });

  testWidgets('avatar falls back to the person icon without a level', (
    tester,
  ) async {
    await tester.pumpWidget(await _wrap(await _storageWith(null)));
    await tester.pump();

    expect(_avatarIcon(tester).asset, AppIcons.navMe);
  });

  testWidgets('an empty name shows the experience level', (tester) async {
    await tester.pumpWidget(
      await _wrap(await _storageWith(ExperienceLevel.regular, displayName: '')),
    );
    await tester.pump();

    expect(find.text('Regular'), findsWidgets);
    expect(find.text('Andrei'), findsNothing);
  });

  testWidgets('a saved name is shown as-is', (tester) async {
    await tester.pumpWidget(
      await _wrap(
        await _storageWith(ExperienceLevel.veteran, displayName: 'Andrei'),
      ),
    );
    await tester.pump();

    expect(find.text('Andrei'), findsOneWidget);
  });

  testWidgets('body weight row shortcuts to the weight log', (tester) async {
    await tester.pumpWidget(
      await _wrap(
        await _storageWith(ExperienceLevel.regular, bodyWeightKg: 78.5),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('me-weight-row')), findsOneWidget);
    expect(find.text('78.5 kg'), findsOneWidget);
  });
}
