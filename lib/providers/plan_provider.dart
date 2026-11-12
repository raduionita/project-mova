import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/equipment_group.dart';
import '../models/exercise.dart';
import '../models/experience_level.dart';
import '../models/goal.dart';
import '../models/plan_day.dart';
import '../models/split_style.dart';
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
  String? _lastWarning;

  TrainingPlan? get plan => _plan;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  String? get lastWarning => _lastWarning;

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
    List<int>? trainingDays,
    SplitStyle splitStyle = SplitStyle.auto,
    List<EquipmentGroup>? availableEquipment,
  }) async {
    _isGenerating = true;
    _error = null;
    _lastWarning = null;
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
        splitStyle: splitStyle,
        availableEquipment: availableEquipment ?? _plan?.availableEquipment,
      );
      _lastWarning = generator.lastWarning;
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
    List<int>? trainingDays,
    SplitStyle? splitStyle,
    List<EquipmentGroup>? availableEquipment,
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
      splitStyle: splitStyle ?? current.splitStyle,
      availableEquipment: availableEquipment ?? current.availableEquipment,
    );
  }

  /// Moves a rotation session from one position to another.
  Future<bool> reorderPlanDay({
    required int fromIndex,
    required int toIndex,
  }) async {
    final current = _plan;
    if (current == null) {
      _error = 'No plan to update.';
      notifyListeners();
      return false;
    }
    if (fromIndex < 0 ||
        toIndex < 0 ||
        fromIndex >= current.days.length ||
        toIndex >= current.days.length ||
        fromIndex == toIndex) {
      return false;
    }
    final days = <PlanDay>[...current.days];
    final moved = days.removeAt(fromIndex);
    days.insert(toIndex, moved);
    final reordered = <PlanDay>[
      for (var index = 0; index < days.length; index++)
        days[index].copyWith(order: index),
    ];
    return replacePlan(current.copyWith(days: reordered));
  }
}
