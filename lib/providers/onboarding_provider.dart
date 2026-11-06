import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/experience_level.dart';
import '../models/gender.dart';
import '../models/goal.dart';
import '../models/onboarding_draft.dart';
import '../models/unit_preferences.dart';
import '../services/clock.dart';
import '../services/storage_service.dart';

/// Owns the persisted onboarding draft at [kOnboardingKey].
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider(this._storage, {Clock? clock})
    : _clock = clock ?? const SystemClock() {
    _draft = OnboardingDraft(updatedAt: _clock.now());
  }

  final StorageService _storage;
  final Clock _clock;

  late OnboardingDraft _draft;
  bool _isLoading = false;
  bool _hasDraft = false;
  String? _error;

  OnboardingDraft get draft => _draft;

  /// True when storage holds progress past the welcome screen.
  bool get hasDraft => _hasDraft;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final stored = _storage.readObject<OnboardingDraft>(
        kOnboardingKey,
        OnboardingDraft.fromJson,
      );
      _draft = stored ?? OnboardingDraft(updatedAt: _clock.now());
      _hasDraft =
          stored != null && stored.currentStep != OnboardingStep.welcome;
    } catch (error) {
      _error = error.toString();
      _hasDraft = false;
      _draft = OnboardingDraft(updatedAt: _clock.now());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setUnits(UnitPreferences preferences) {
    return _update(_draft.copyWith(unitPreferences: preferences));
  }

  Future<bool> setGender(Gender gender) {
    return _update(_draft.copyWith(gender: gender));
  }

  Future<bool> setBirthDate(DateTime birthDate) {
    return _update(_draft.copyWith(birthDate: birthDate));
  }

  Future<bool> setBodyWeightKg(double bodyWeightKg) {
    return _update(_draft.copyWith(bodyWeightKg: bodyWeightKg));
  }

  Future<bool> setHeightCm(double heightCm) {
    return _update(_draft.copyWith(heightCm: heightCm));
  }

  Future<bool> setGoals(List<Goal> goals) {
    return _update(_draft.copyWith(goals: goals));
  }

  Future<bool> setExperienceLevel(ExperienceLevel level) {
    return _update(_draft.copyWith(experienceLevel: level));
  }

  Future<bool> setSchedule({
    required int daysPerWeek,
    required List<int> trainingDays,
  }) {
    return _update(
      _draft.copyWith(daysPerWeek: daysPerWeek, trainingDays: trainingDays),
    );
  }

  Future<bool> markNotificationsAsked(bool asked) {
    return _update(_draft.copyWith(notificationsAsked: asked));
  }

  bool canContinue(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
      case OnboardingStep.units:
      case OnboardingStep.weight:
      case OnboardingStep.height:
      case OnboardingStep.notifications:
      case OnboardingStep.plan:
        return true;
      case OnboardingStep.gender:
        return _draft.gender != null;
      case OnboardingStep.birthDate:
        return _draft.birthDate != null;
      case OnboardingStep.goals:
        return _draft.goals.isNotEmpty;
      case OnboardingStep.experience:
        return _draft.experienceLevel != null;
      case OnboardingStep.schedule:
        final daysPerWeek = _draft.daysPerWeek;
        return daysPerWeek != null &&
            daysPerWeek >= kMinTrainingDays &&
            daysPerWeek <= kMaxTrainingDays &&
            _draft.trainingDays.length == daysPerWeek;
    }
  }

  Future<bool> next() async {
    if (!canContinue(_draft.currentStep)) {
      return false;
    }
    final index = _draft.currentStep.index;
    if (index >= OnboardingStep.values.length - 1) {
      return false;
    }
    return _update(
      _draft.copyWith(currentStep: OnboardingStep.values[index + 1]),
    );
  }

  Future<bool> back() async {
    final index = _draft.currentStep.index;
    if (index == 0) {
      return false;
    }
    return _update(
      _draft.copyWith(currentStep: OnboardingStep.values[index - 1]),
    );
  }

  Future<bool> saveDraft() {
    return _update(_draft.copyWith(updatedAt: _clock.now()));
  }

  Future<void> reset() async {
    await _storage.remove(kOnboardingKey);
    _draft = OnboardingDraft(updatedAt: _clock.now());
    _hasDraft = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> _update(OnboardingDraft next) async {
    _error = null;
    final stamped = next.copyWith(updatedAt: _clock.now());
    final saved = await _storage.writeObject(kOnboardingKey, stamped.toJson());
    if (!saved) {
      _error = 'Could not save onboarding draft.';
      notifyListeners();
      return false;
    }
    _draft = stamped;
    _hasDraft = stamped.currentStep != OnboardingStep.welcome;
    notifyListeners();
    return true;
  }
}
