import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/activity_post.dart';
import '../models/exercise.dart';
import 'storage_service.dart';

/// Loads bundled seed data and caches the exercise library for the session.
class SeedDataService {
  SeedDataService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const String exerciseAssetPath = 'assets/data/exercises.json';

  final AssetBundle _bundle;
  List<Exercise>? _cachedExercises;

  Future<void> seedIfNeeded(StorageService storage, DateTime now) async {
    await loadExercises();
  }

  Future<List<Exercise>> loadExercises() async {
    final cached = _cachedExercises;
    if (cached != null) {
      return cached;
    }
    final raw = await _bundle.loadString(exerciseAssetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <Exercise>[];
    }
    final exercises = decoded
        .whereType<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .where((exercise) => exercise.id.isNotEmpty && exercise.name.isNotEmpty)
        .toList(growable: false);
    _cachedExercises = exercises;
    return exercises;
  }

  /// One faded welcome card shown until the first own workout post exists.
  List<ActivityPost> placeholderPosts(DateTime now) {
    return <ActivityPost>[
      ActivityPost(
        id: 'placeholder-1',
        authorName: 'Mova Coach',
        isOwn: false,
        text: 'Welcome to Mova. Finish your first workout and your post will appear here.',
        createdAt: now,
        isSample: true,
      ),
    ];
  }
}
