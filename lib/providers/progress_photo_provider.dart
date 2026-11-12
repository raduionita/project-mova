import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/progress_photo.dart';
import '../services/clock.dart';
import '../services/id_service.dart';
import '../services/progress_photo_store.dart';
import '../services/storage_service.dart';

/// Owns progress photo thumbnails stored on this device.
class ProgressPhotoProvider extends ChangeNotifier {
  ProgressPhotoProvider(
    StorageService storage, {
    Clock? clock,
    IdService? ids,
  }) : _store = ProgressPhotoStore(storage),
       _clock = clock ?? const SystemClock(),
       _ids = ids ?? IdService();

  final ProgressPhotoStore _store;
  final Clock _clock;
  final IdService _ids;

  List<ProgressPhoto> _photos = const <ProgressPhoto>[];
  bool _isLoading = false;
  String? _error;

  List<ProgressPhoto> get photos => _photos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isFull => _photos.length >= ProgressPhotoStore.maxPhotos;
  int get remaining =>
      (ProgressPhotoStore.maxPhotos - _photos.length).clamp(0, 999);

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _photos = List<ProgressPhoto>.unmodifiable(_store.load());
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> add(Uint8List bytes, {DateTime? takenAt}) async {
    if (isFull) {
      _error = 'You can keep up to ${ProgressPhotoStore.maxPhotos} photos.';
      notifyListeners();
      return false;
    }
    if (bytes.isEmpty || bytes.length > ProgressPhotoStore.maxBytes) {
      _error = 'That photo is too large. Try a smaller image.';
      notifyListeners();
      return false;
    }
    final photo = ProgressPhoto(
      id: _ids.next(),
      takenAt: takenAt ?? _clock.now(),
      dataBase64: base64Encode(bytes),
    );
    final next = <ProgressPhoto>[photo, ..._photos];
    final saved = await _store.save(next);
    if (!saved) {
      _error = 'Could not save the photo on this device.';
      notifyListeners();
      return false;
    }
    _photos = List<ProgressPhoto>.unmodifiable(next);
    _error = null;
    notifyListeners();
    return true;
  }

  Future<bool> remove(String id) async {
    final next = _photos.where((photo) => photo.id != id).toList(growable: false);
    if (next.length == _photos.length) {
      return true;
    }
    final saved = await _store.save(next);
    if (!saved) {
      _error = 'Could not remove the photo.';
      notifyListeners();
      return false;
    }
    _photos = List<ProgressPhoto>.unmodifiable(next);
    _error = null;
    notifyListeners();
    return true;
  }
}
