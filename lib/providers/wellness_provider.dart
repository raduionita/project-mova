import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../common/date_keys.dart';
import '../models/wellness_entry.dart';
import '../services/clock.dart';
import '../services/storage_service.dart';

/// Owns local nutrition, sleep, resting heart rate, and measurement entries.
class WellnessProvider extends ChangeNotifier {
  WellnessProvider(
    this._storage, {
    Clock? clock,
  }) : _clock = clock ?? const SystemClock();

  final StorageService _storage;
  final Clock _clock;

  List<WellnessEntry> _entries = const <WellnessEntry>[];
  bool _isLoading = false;
  String? _error;

  List<WellnessEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DateTime get _today {
    final now = _clock.now();
    return DateTime(now.year, now.month, now.day);
  }

  WellnessEntry? get todayEntry {
    final key = DateKeys.dayKey(_today);
    for (final entry in _entries) {
      if (entry.dateKey == key) {
        return entry;
      }
    }
    return null;
  }

  WellnessEntry? get latestMeasurement {
    for (final entry in _entries) {
      if (entry.hasMeasurement) {
        return entry;
      }
    }
    return null;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final stored = _storage.readList<WellnessEntry>(
        kWellnessKey,
        WellnessEntry.fromJson,
      );
      _entries = <WellnessEntry>[...stored]
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveNutrition({int? calories, int? proteinGrams}) {
    return _upsertToday(
      (current) => (current ?? WellnessEntry(date: _today)).copyWith(
        calories: calories ?? current?.calories,
        proteinGrams: proteinGrams ?? current?.proteinGrams,
      ),
    );
  }

  Future<bool> saveSleepMinutes(int minutes) {
    return _upsertToday(
      (current) => (current ?? WellnessEntry(date: _today)).copyWith(
        sleepMinutes: minutes,
      ),
    );
  }

  Future<bool> saveRestingHeartRate(int bpm) {
    return _upsertToday(
      (current) => (current ?? WellnessEntry(date: _today)).copyWith(
        restingHeartRate: bpm,
      ),
    );
  }

  Future<bool> saveWaistCm(double value) {
    return _upsertToday(
      (current) => (current ?? WellnessEntry(date: _today)).copyWith(
        waistCm: value,
      ),
    );
  }

  Future<bool> _upsertToday(
    WellnessEntry Function(WellnessEntry?) update,
  ) async {
    final current = todayEntry;
    final next = update(current);
    final entries = <WellnessEntry>[
      for (final entry in _entries)
        if (entry.dateKey != next.dateKey) entry,
      next,
    ]..sort((a, b) => b.date.compareTo(a.date));
    final saved = await _storage.writeList(
      kWellnessKey,
      entries.map((entry) => entry.toJson()).toList(growable: false),
    );
    if (!saved) {
      _error = 'Could not save wellness data.';
      notifyListeners();
      return false;
    }
    _entries = List<WellnessEntry>.unmodifiable(entries);
    _error = null;
    notifyListeners();
    return true;
  }
}
