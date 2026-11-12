import 'dart:async';

import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/app_settings.dart';
import '../models/unit_preferences.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// Owns the app settings payload stored at [kSettingsKey].
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(
    this._storage, {
    this.notificationService = const NotificationService(),
  }) {
    _settings = const AppSettings();
  }

  final StorageService _storage;
  final NotificationService notificationService;

  late AppSettings _settings;
  bool _isLoading = false;
  String? _error;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Non-persisted warning raised by [StorageService] during startup reads.
  String? get storageWarning => _storage.warning;

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
        if (stored.remindersEnabled) {
          unawaited(notificationService.reschedule(stored));
        }
      } else {
        // A cleared or missing payload returns every preference to defaults.
        _settings = const AppSettings();
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
  }) async {
    final saved = await _save(
      _settings.copyWith(
        remindersEnabled: enabled,
        reminderWeekdays: weekdays,
        reminderHour: hour,
        reminderMinute: minute,
      ),
    );
    if (!saved) {
      return false;
    }
    if (enabled) {
      await notificationService.reschedule(_settings);
    } else {
      await notificationService.cancelAll();
    }
    return true;
  }

  Future<bool> setHealthProvider(HealthProvider provider) {
    return _save(_settings.copyWith(healthProvider: provider));
  }

  Future<bool> setPostWorkoutsToFeed(bool enabled) {
    return _save(_settings.copyWith(postWorkoutsToFeed: enabled));
  }

  Future<bool> setRestTimerEnabled(bool enabled) {
    return _save(_settings.copyWith(restTimerEnabled: enabled));
  }

  Future<bool> setWeekStart(int? weekStart) {
    if (weekStart != null && (weekStart < 1 || weekStart > 7)) {
      _error = 'Week start must be between Monday and Sunday.';
      notifyListeners();
      return Future<bool>.value(false);
    }
    return _save(_settings.copyWith(weekStart: weekStart));
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
