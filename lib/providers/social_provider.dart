import 'package:flutter/foundation.dart';

import '../common/constants.dart';
import '../models/activity_post.dart';
import '../services/clock.dart';
import '../services/seed_data_service.dart';
import '../services/storage_service.dart';

/// Owns feed posts stored at [kSocialKey].
class SocialProvider extends ChangeNotifier {
  SocialProvider(this._storage, this._seedDataService, {Clock? clock})
    : _clock = clock ?? const SystemClock();

  final StorageService _storage;
  final SeedDataService _seedDataService;
  final Clock _clock;

  List<ActivityPost> _posts = const <ActivityPost>[];
  bool _isLoading = false;
  String? _error;

  List<ActivityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final payload = _storage.readObject<Map<String, dynamic>>(
        kSocialKey,
        (json) => json,
      );
      if (payload == null) {
        _posts = _seedDataService.samplePosts(_clock.now());
        await _write(_posts);
      } else {
        final rawPosts = payload['posts'];
        _posts = rawPosts is List
            ? rawPosts
                  .whereType<Map>()
                  .map(
                    (item) => ActivityPost.fromJson(
                      item.map((key, value) => MapEntry(key.toString(), value)),
                    ),
                  )
                  .toList(growable: false)
            : const <ActivityPost>[];
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPost(ActivityPost post) {
    final next = <ActivityPost>[..._posts];
    final index = next.indexWhere((item) => item.id == post.id);
    if (index == -1) {
      next.insert(0, post);
    } else {
      next[index] = post;
    }
    return _write(next);
  }

  Future<bool> removePostForSession(String sessionId) {
    final next = _posts
        .where((post) => post.sessionId != sessionId)
        .toList(growable: false);
    return _write(next);
  }

  Future<bool> toggleKudos(String postId) {
    var found = false;
    final next = <ActivityPost>[];
    for (final post in _posts) {
      if (post.id == postId) {
        found = true;
        next.add(
          post.copyWith(
            kudos: post.kudosGiven
                ? (post.kudos - 1).clamp(0, 1 << 31).toInt()
                : post.kudos + 1,
            kudosGiven: !post.kudosGiven,
          ),
        );
      } else {
        next.add(post);
      }
    }
    if (!found) {
      _error = 'Post not found.';
      notifyListeners();
      return Future<bool>.value(false);
    }
    return _write(next);
  }

  Future<bool> dismissSamples() {
    final next = _posts.where((post) => !post.isSample).toList(growable: false);
    return _write(next);
  }

  Future<bool> _write(List<ActivityPost> posts) async {
    _error = null;
    final saved = await _storage.writeObject(kSocialKey, <String, dynamic>{
      'schemaVersion': kSchemaVersion,
      'seeded': true,
      'posts': posts.map((post) => post.toJson()).toList(growable: false),
    });
    if (!saved) {
      _error = 'Could not save feed.';
      notifyListeners();
      return false;
    }
    _posts = List<ActivityPost>.unmodifiable(posts);
    notifyListeners();
    return true;
  }
}
