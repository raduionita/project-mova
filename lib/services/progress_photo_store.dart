import '../common/constants.dart';
import '../models/progress_photo.dart';
import 'storage_service.dart';

/// Local persistence for progress photo thumbnails.
///
/// Photos are stored as compressed base64 thumbnails so the same path works on
/// Android, iOS, and web without a filesystem.
class ProgressPhotoStore {
  const ProgressPhotoStore(this._storage);

  static const int maxPhotos = 12;
  static const int maxBytes = 2 * 1024 * 1024;

  final StorageService _storage;

  List<ProgressPhoto> load() {
    return _storage.readList<ProgressPhoto>(kPhotosKey, ProgressPhoto.fromJson)
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
  }

  Future<bool> save(List<ProgressPhoto> photos) {
    return _storage.writeList(
      kPhotosKey,
      photos.map((photo) => photo.toJson()).toList(growable: false),
    );
  }
}
