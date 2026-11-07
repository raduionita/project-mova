import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/equipment_group.dart';
import '../models/user_profile.dart';
import '../services/clock.dart';
import '../services/storage_service.dart';

/// Owns the local guest profile stored at [kProfileKey].
class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._storage, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  final StorageService _storage;
  final Clock _clock;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = _storage.readObject<UserProfile>(
        kProfileKey,
        UserProfile.fromJson,
      );
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile(UserProfile profile) async {
    _error = null;
    final saved = await _storage.writeObject(kProfileKey, profile.toJson());
    if (!saved) {
      _error = 'Could not save profile.';
      notifyListeners();
      return false;
    }
    _profile = profile;
    notifyListeners();
    return true;
  }

  Future<bool> updateBodyWeight(double bodyWeightKg) async {
    final current = _profile;
    if (current == null) {
      _error = 'No profile to update.';
      notifyListeners();
      return false;
    }
    return saveProfile(
      current.copyWith(bodyWeightKg: bodyWeightKg, updatedAt: _clock.now()),
    );
  }

  Future<bool> updateEquipment(List<EquipmentGroup> equipment) async {
    final current = _profile;
    if (current == null) {
      _error = 'No profile to update.';
      notifyListeners();
      return false;
    }
    if (equipment.isEmpty) {
      _error = 'Choose at least one equipment option.';
      notifyListeners();
      return false;
    }
    return saveProfile(
      current.copyWith(
        availableEquipment: List<EquipmentGroup>.unmodifiable(equipment),
        updatedAt: _clock.now(),
      ),
    );
  }
}
