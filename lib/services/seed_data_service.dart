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

  List<ActivityPost> samplePosts(DateTime now) {
    return <ActivityPost>[
      ActivityPost(
        id: 'sample-1',
        authorName: 'Mova Coach',
        isOwn: false,
        text: 'Welcome to Mova. Log your first workout and start tracking progress.',
        createdAt: now.subtract(const Duration(hours: 3)),
        kudos: 12,
        isSample: true,
      ),
      ActivityPost(
        id: 'sample-2',
        authorName: 'Alex',
        isOwn: false,
        text: 'Hit a new bench press personal record this morning. Consistency pays off.',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        kudos: 8,
        isSample: true,
      ),
      ActivityPost(
        id: 'sample-3',
        authorName: 'Sam',
        isOwn: false,
        text:
            'Leg day complete. Four sets of squats and a long walk to finish.',
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
        kudos: 5,
        isSample: true,
      ),
    ];
  }
}
