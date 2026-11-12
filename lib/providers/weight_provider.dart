import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../common/date_keys.dart';
import '../models/weight_entry.dart';
import '../services/clock.dart';
import '../services/storage_service.dart';

/// Owns the local body-weight log stored at [kWeightsKey].
///
/// There is one entry per local calendar day. Saving again on the same day
/// replaces the earlier value so quick updates never create duplicates.
class WeightProvider extends ChangeNotifier {
  WeightProvider(this._storage, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  final StorageService _storage;
  final Clock _clock;

  List<WeightEntry> _entries = const <WeightEntry>[];
  bool _isLoading = false;
  String? _error;

  /// Entries newest first.
  List<WeightEntry> get entries => _entries;
  WeightEntry? get latest => _entries.isEmpty ? null : _entries.first;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final stored = _storage.readList<WeightEntry>(
        kWeightsKey,
        WeightEntry.fromJson,
      );
      _entries = _sorted(_latestByDay(stored).values);
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Saves today's weight, replacing an earlier entry for the same day.
  Future<bool> logWeight(double weightKg, {DateTime? date}) async {
    if (weightKg < kMinWeightKg || weightKg > kMaxWeightKg) {
      _error =
          'Enter a weight from ${kMinWeightKg.toInt()} to '
          '${kMaxWeightKg.toInt()} kg.';
      notifyListeners();
      return false;
    }
    final now = date ?? _clock.now();
    final entry = WeightEntry(
      dateKey: DateKeys.dayKey(now),
      weightKg: weightKg,
      updatedAt: _clock.now(),
    );
    final next = <String, WeightEntry>{
      for (final item in _entries) item.dateKey: item,
    }..[entry.dateKey] = entry;
    final saved = await _storage.writeList(
      kWeightsKey,
      _sorted(next.values).reversed
          .map((item) => item.toJson())
          .toList(growable: false),
    );
    if (!saved) {
      _error = 'Could not save your weight.';
      notifyListeners();
      return false;
    }
    _entries = _sorted(next.values);
    _error = null;
    notifyListeners();
    return true;
  }

  /// Adds a starting entry from the profile when the log is still empty.
  Future<bool> seedInitial(double weightKg, {DateTime? date}) {
    if (_entries.isNotEmpty || weightKg <= 0) {
      return Future<bool>.value(true);
    }
    return logWeight(weightKg, date: date);
  }

  /// Clears in-memory state after local data is reset.
  void reset() {
    _entries = const <WeightEntry>[];
    _error = null;
    notifyListeners();
  }

  List<WeightEntry> _sorted(Iterable<WeightEntry> entries) {
    final next =
        entries
            .where((entry) => entry.dateKey.isNotEmpty && entry.weightKg > 0)
            .toList(growable: false)
          ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return List<WeightEntry>.unmodifiable(next);
  }

  Map<String, WeightEntry> _latestByDay(List<WeightEntry> entries) {
    final latest = <String, WeightEntry>{};
    for (final entry in entries) {
      if (entry.dateKey.isEmpty || entry.weightKg <= 0) {
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
