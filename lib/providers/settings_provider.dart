import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/app_settings.dart';
import '../models/unit_preferences.dart';
import '../services/storage_service.dart';

/// Owns the app settings payload stored at [kSettingsKey].
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage) {
    _settings = const AppSettings();
  }

  final StorageService _storage;

  late AppSettings _settings;
  bool _isLoading = false;
  String? _error;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final stored = _storage.readObject<AppSettings>(
        kSettingsKey,
        AppSettings.fromJson,
      );
      if (stored != null) {
        _settings = stored;
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setUnitPreferences(UnitPreferences preferences) {
    return _save(_settings.copyWith(unitPreferences: preferences));
  }

  Future<bool> setReminders({
    required bool enabled,
    required List<int> weekdays,
    required int hour,
    required int minute,
  }) {
    return _save(
      _settings.copyWith(
        remindersEnabled: enabled,
        reminderWeekdays: weekdays,
        reminderHour: hour,
        reminderMinute: minute,
      ),
    );
  }

  Future<bool> setHealthProvider(HealthProvider provider) {
    return _save(_settings.copyWith(healthProvider: provider));
  }

  Future<bool> setPostWorkoutsToFeed(bool enabled) {
    return _save(_settings.copyWith(postWorkoutsToFeed: enabled));
  }

  Future<bool> dismissSampleFeed() {
    return _save(_settings.copyWith(sampleFeedDismissed: true));
  }

  Future<bool> _save(AppSettings next) async {
    _error = null;
    final saved = await _storage.writeObject(kSettingsKey, next.toJson());
    if (!saved) {
      _error = 'Could not save settings.';
      notifyListeners();
      return false;
    }
    _settings = next;
    notifyListeners();
    return true;
  }
}
