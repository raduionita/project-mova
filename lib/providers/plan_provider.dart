import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/exercise.dart';
import '../models/experience_level.dart';
import '../models/goal.dart';
import '../models/plan_day.dart';
import '../models/training_plan.dart';
import '../services/clock.dart';
import '../services/plan_generator_service.dart';
import '../services/storage_service.dart';

/// Owns the generated training plan stored at [kPlanKey].
class PlanProvider extends ChangeNotifier {
  PlanProvider(
    this._storage, {
    required this.loadExercises,
    Clock? clock,
    this.sessionMinutes = kDefaultSessionMinutes,
  }) : _clock = clock ?? const SystemClock();

  final StorageService _storage;
  final Future<List<Exercise>> Function() loadExercises;
  final Clock _clock;
  final int sessionMinutes;

  TrainingPlan? _plan;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;

  TrainingPlan? get plan => _plan;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _plan = _storage.readObject<TrainingPlan>(
        kPlanKey,
        TrainingPlan.fromJson,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> generate({
    required List<Goal> goals,
    required ExperienceLevel experienceLevel,
    required int daysPerWeek,
    required List<int> trainingDays,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      final exercises = await loadExercises();
      final generator = PlanGeneratorService(
        exercises: exercises,
        now: _clock.now,
        sessionMinutes: sessionMinutes,
      );
      final generated = generator.generate(
        goals: goals,
        experienceLevel: experienceLevel,
        daysPerWeek: daysPerWeek,
        trainingDays: trainingDays,
      );
      return await replacePlan(generated);
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<bool> replacePlan(TrainingPlan plan) async {
    _error = null;
    final saved = await _storage.writeObject(kPlanKey, plan.toJson());
    if (!saved) {
      _error = 'Could not save plan.';
      notifyListeners();
      return false;
    }
    _plan = plan;
    notifyListeners();
    return true;
  }

  Future<bool> updateSchedule({
    required int daysPerWeek,
    required List<int> trainingDays,
  }) {
    final current = _plan;
    if (current == null) {
      _error = 'No plan to update.';
      notifyListeners();
      return Future<bool>.value(false);
    }
    return generate(
      goals: current.goals.isEmpty ? <Goal>[current.goal] : current.goals,
      experienceLevel: current.experienceLevel,
      daysPerWeek: daysPerWeek,
      trainingDays: trainingDays,
    );
  }

  Future<bool> movePlanDay({
    required int fromWeekday,
    required int toWeekday,
  }) async {
    final current = _plan;
    if (current == null) {
      _error = 'No plan to update.';
      notifyListeners();
      return false;
    }
    if (fromWeekday == toWeekday ||
        fromWeekday < 1 ||
        fromWeekday > 7 ||
        toWeekday < 1 ||
        toWeekday > 7) {
      return false;
    }
    final fromIndex = current.days.indexWhere(
      (day) => day.weekday == fromWeekday,
    );
    if (fromIndex == -1) {
      _error = 'Weekday is not a training day.';
      notifyListeners();
      return false;
    }

    final days = <PlanDay>[...current.days];
    final toIndex = days.indexWhere((day) => day.weekday == toWeekday);
    if (toIndex == -1) {
      days[fromIndex] = days[fromIndex].copyWith(weekday: toWeekday);
    } else {
      days[fromIndex] = days[fromIndex].copyWith(weekday: toWeekday);
      days[toIndex] = days[toIndex].copyWith(weekday: fromWeekday);
    }
    days.sort((a, b) => a.weekday.compareTo(b.weekday));
    final trainingDays = days.map((day) => day.weekday).toList(growable: false)
      ..sort();

    return replacePlan(
      current.copyWith(days: days, trainingDays: trainingDays),
    );
  }
}
