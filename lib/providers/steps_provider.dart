import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../common/date_keys.dart';
import '../models/step_entry.dart';
import '../services/clock.dart';
import '../services/health_service.dart';
import '../services/storage_service.dart';

/// Owns daily step entries stored at [kStepsKey].
///
/// Health reads and manual entries share one record per local calendar day.
/// A health source wins when it returns a value; manual entry is always
/// available as the fallback.
class StepsProvider extends ChangeNotifier {
  StepsProvider(this._storage, {Clock? clock, HealthService? healthService})
    : _clock = clock ?? const SystemClock(),
      _health = healthService ?? HealthService();

  final StorageService _storage;
  final Clock _clock;
  final HealthService _health;

  final Map<String, StepEntry> _entries = <String, StepEntry>{};
  bool _isLoading = false;
  String? _error;

  Map<String, StepEntry> get entries =>
      Map<String, StepEntry>.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get error => _error;

  StepEntry? get todayEntry => entryFor(_clock.now());

  int get todaySteps => todayEntry?.steps ?? 0;

  StepEntry? entryFor(DateTime date) => _entries[DateKeys.dayKey(date)];

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final stored = _storage.readList<StepEntry>(
        kStepsKey,
        StepEntry.fromJson,
      );
      _entries
        ..clear()
        ..addAll(_latestByDay(stored));
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves a manual step count for today. The source is always Manual.
  Future<bool> saveManualSteps(int steps) async {
    if (steps < 0) {
      _error = 'Steps cannot be negative.';
      notifyListeners();
      return false;
    }
    return _write(
      StepEntry(
        dateKey: DateKeys.dayKey(_clock.now()),
        steps: steps,
        source: StepSource.manual,
        updatedAt: _clock.now(),
      ),
    );
  }

  /// Reads today's step total from the connected health provider.
  ///
  /// Returns false when the integration is off, unavailable, denied, or
  /// returns no data. The existing stored value is left untouched in every
  /// failure case.
  Future<bool> syncHealth({required bool enabled}) async {
    if (!enabled) {
      return false;
    }
    if (!await _health.isAvailable()) {
      return false;
    }
    if (!await _health.hasPermission()) {
      return false;
    }
    final now = _clock.now();
    final start = DateTime(now.year, now.month, now.day);
    final steps = await _health.readSteps(start, now);
    if (steps == null) {
      return false;
    }
    final existing = todayEntry;
    if (existing != null &&
        existing.steps == steps &&
        existing.source == StepSource.health) {
      return true;
    }
    return _write(
      StepEntry(
        dateKey: DateKeys.dayKey(now),
        steps: steps,
        source: StepSource.health,
        updatedAt: now,
      ),
    );
  }

  /// Clears in-memory state after local data is reset.
  void reset() {
    _entries.clear();
    _error = null;
    notifyListeners();
  }

  Future<bool> _write(StepEntry entry) async {
    final next = Map<String, StepEntry>.from(_entries)..[entry.dateKey] = entry;
    final ordered = next.values.toList(growable: false)
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final saved = await _storage.writeList(
      kStepsKey,
      ordered.map((item) => item.toJson()).toList(growable: false),
    );
    if (!saved) {
      _error = 'Could not save steps.';
      notifyListeners();
      return false;
    }
    _entries
      ..clear()
      ..addAll(next);
    _error = null;
    notifyListeners();
    return true;
  }

  Map<String, StepEntry> _latestByDay(List<StepEntry> entries) {
    final latest = <String, StepEntry>{};
    for (final entry in entries) {
      if (entry.dateKey.isEmpty) {
        continue;
      }
      final current = latest[entry.dateKey];
      if (current == null || entry.updatedAt.isAfter(current.updatedAt)) {
        latest[entry.dateKey] = entry;
      }
    }
    return latest;
  }
}
