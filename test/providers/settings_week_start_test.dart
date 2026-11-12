import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/constants.dart';
import 'package:mova/models/app_settings.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/services/storage_service.dart';

void main() {
  test('week start defaults to automatic', () async {
    final provider = SettingsProvider(StorageService.inMemory());
    await provider.load();

    expect(provider.settings.weekStart, isNull);
    expect(provider.settings.schemaVersion, 2);
  });

  test('an explicit week start persists across reloads', () async {
    final storage = StorageService.inMemory();
    final provider = SettingsProvider(storage);
    await provider.load();

    expect(await provider.setWeekStart(DateTime.sunday), isTrue);

    final reloaded = SettingsProvider(storage);
    await reloaded.load();
    expect(reloaded.settings.weekStart, DateTime.sunday);
  });

  test('week start can return to automatic', () async {
    final storage = StorageService.inMemory();
    final provider = SettingsProvider(storage);
    await provider.load();
    await provider.setWeekStart(DateTime.saturday);

    expect(await provider.setWeekStart(null), isTrue);
    expect(provider.settings.weekStart, isNull);

    final stored = storage.readObject(kSettingsKey, (json) => json);
    expect(stored?['weekStart'], isNull);
    expect(stored?['schemaVersion'], 2);
  });

  test('out-of-range week starts are rejected', () async {
    final provider = SettingsProvider(StorageService.inMemory());
    await provider.load();

    expect(await provider.setWeekStart(0), isFalse);
    expect(await provider.setWeekStart(8), isFalse);
    expect(provider.settings.weekStart, isNull);
    expect(provider.error, isNotNull);
  });

  test('v1 settings load with automatic week start', () async {
    final storage = StorageService.inMemory();
    await storage.writeObject(kSettingsKey, <String, dynamic>{
      'schemaVersion': 1,
      'remindersEnabled': false,
      'reminderWeekdays': <int>[2],
      'reminderHour': 7,
    });

    final provider = SettingsProvider(storage);
    await provider.load();

    expect(provider.settings.weekStart, isNull);
    expect(provider.settings.reminderHour, 7);
    expect(provider.settings.reminderWeekdays, <int>[2]);
    expect(provider.settings.schemaVersion, 2);
    expect(
      AppSettings.fromJson(<String, dynamic>{'schemaVersion': 1}).weekStart,
      isNull,
    );
  });
}
