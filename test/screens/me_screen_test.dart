import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/models/user_profile.dart';
import 'package:mova/providers/profile_provider.dart';
import 'package:mova/providers/progress_provider.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/screens/me/me_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_icon.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 10, 12);
final FakeClock _clock = FakeClock(_now);

Future<StorageService> _storageWith(ExperienceLevel? level) async {
  final storage = StorageService.inMemory();
  await storage.writeObject(
    kProfileKey,
    UserProfile(
      id: 'profile-1',
      displayName: 'Andrei',
      experienceLevel: level,
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
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProfileProvider>.value(value: profile),
      ChangeNotifierProvider<ProgressProvider>.value(value: progress),
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
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
}
