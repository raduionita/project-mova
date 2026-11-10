import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';

const Set<String> _requiredMuscles = <String>{
  'Chest',
  'Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Quads',
  'Hamstrings',
  'Glutes',
  'Calves',
  'Core',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed library has at least 60 exercises', () async {
    final service = SeedDataService();
    final exercises = await service.loadExercises();

    expect(exercises.length, greaterThanOrEqualTo(60));
  });

  test('exercise ids are unique and required fields are filled', () async {
    final service = SeedDataService();
    final exercises = await service.loadExercises();

    final ids = exercises.map((exercise) => exercise.id).toList();
    expect(ids.toSet().length, ids.length);

    for (final exercise in exercises) {
      expect(exercise.name, isNotEmpty, reason: exercise.id);
      expect(exercise.primaryMuscle, isNotEmpty, reason: exercise.id);
      expect(exercise.equipment, isNotEmpty, reason: exercise.id);
      expect(exercise.instructions, isNotEmpty, reason: exercise.id);
      expect(
        exercise.instructions.every((step) => step.trim().isNotEmpty),
        isTrue,
        reason: exercise.id,
      );
    }
  });

  test('library covers every major muscle group', () async {
    final service = SeedDataService();
    final exercises = await service.loadExercises();
    final muscles = exercises.map((exercise) => exercise.primaryMuscle).toSet();

    for (final muscle in _requiredMuscles) {
      expect(muscles, contains(muscle));
    }
  });

  test('seedIfNeeded loads the library through storage', () async {
    final service = SeedDataService();
    final storage = StorageService.inMemory();

    await service.seedIfNeeded(storage, DateTime.utc(2026, 1, 1));

    expect(await service.loadExercises(), isNotEmpty);
  });

  test('welcome placeholder is a single faded, dashed card', () {
    final now = DateTime.utc(2026, 1, 1, 12);
    final posts = SeedDataService().placeholderPosts(now);

    expect(posts, hasLength(1));
    expect(posts.single.id, 'placeholder-1');
    expect(posts.single.isSample, isTrue);
    expect(posts.single.isOwn, isFalse);
    expect(posts.single.kudos, 0);
    expect(posts.single.createdAt, now);
    expect(posts.single.text, contains('Finish your first workout'));
  });
}
