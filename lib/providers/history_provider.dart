import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/workout_session.dart';
import '../services/storage_service.dart';

/// Owns completed workout history stored at [kWorkoutsKey].
class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._storage);

  final StorageService _storage;

  List<WorkoutSession> _workouts = const <WorkoutSession>[];
  bool _isLoading = false;
  String? _error;

  List<WorkoutSession> get workouts => _workouts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _workouts = _sorted(
        _storage.readList<WorkoutSession>(
          kWorkoutsKey,
          WorkoutSession.fromJson,
        ),
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCompleted(WorkoutSession session) async {
    final next = <WorkoutSession>[..._workouts];
    final index = next.indexWhere((item) => item.id == session.id);
    if (index == -1) {
      next.add(session);
    } else {
      next[index] = session;
    }
    return _write(_sorted(next));
  }

  Future<bool> delete(String sessionId) {
    final next = _workouts
        .where((session) => session.id != sessionId)
        .toList(growable: false);
    return _write(next);
  }

  WorkoutSession? byId(String sessionId) {
    for (final session in _workouts) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  Future<bool> _write(List<WorkoutSession> next) async {
    _error = null;
    final saved = await _storage.writeList(
      kWorkoutsKey,
      next.map((session) => session.toJson()).toList(growable: false),
    );
    if (!saved) {
      _error = 'Could not save workout history.';
      notifyListeners();
      return false;
    }
    _workouts = List<WorkoutSession>.unmodifiable(next);
    notifyListeners();
    return true;
  }

  List<WorkoutSession> _sorted(List<WorkoutSession> sessions) {
    final next = <WorkoutSession>[...sessions];
    next.sort((a, b) {
      final aDate = a.completedAt ?? a.startedAt;
      final bDate = b.completedAt ?? b.startedAt;
      return bDate.compareTo(aDate);
    });
    return next;
  }
}
