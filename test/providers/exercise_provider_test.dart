import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/providers/exercise_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/seed_data_service.dart';
import 'package:mova/services/storage_service.dart';

final DateTime _now = DateTime.utc(2026, 11, 6, 12);

const List<Exercise> _library = <Exercise>[
  Exercise(
    id: 'bench',
    name: 'Barbell Bench Press',
    primaryMuscle: 'Chest',
    secondaryMuscles: <String>['Triceps'],
    equipment: 'Barbell',
  ),
  Exercise(
    id: 'fly',
    name: 'Dumbbell Fly',
    primaryMuscle: 'Chest',
    equipment: 'Dumbbell',
  ),
  Exercise(
    id: 'row',
    name: 'Barbell Row',
    primaryMuscle: 'Back',
    equipment: 'Barbell',
  ),
  Exercise(
    id: 'pulldown',
    name: 'Lat Pulldown',
    primaryMuscle: 'Back',
    equipment: 'Cable',
  ),
];

class _StaticSeedDataService extends SeedDataService {
  @override
  Future<List<Exercise>> loadExercises() async => _library;
}

ExerciseProvider _provider() {
  return ExerciseProvider(
    StorageService.inMemory(),
    _StaticSeedDataService(),
    clock: FakeClock(_now),
  );
}

void main() {
  test(
    'search matches name, muscle, equipment, and secondary muscle',
    () async {
      final provider = _provider();
      await provider.load();

      provider.search('bench');
      expect(provider.filtered.map((e) => e.id), <String>['bench']);

      provider.search('back');
      expect(provider.filtered.map((e) => e.id), <String>['row', 'pulldown']);

      provider.search('barbell');
      expect(provider.filtered.map((e) => e.id), <String>['bench', 'row']);

      provider.search('triceps');
      expect(provider.filtered.map((e) => e.id), <String>['bench']);
    },
  );

  test('muscle filter and search combine', () async {
    final provider = _provider();
    await provider.load();

    provider.setMuscleFilter('Chest');
    expect(provider.filtered.map((e) => e.id), <String>['bench', 'fly']);

    provider.search('barbell');
    expect(provider.filtered.map((e) => e.id), <String>['bench']);

    provider.search('row');
    expect(provider.filtered, isEmpty);

    provider.setMuscleFilter('Back');
    expect(provider.filtered.map((e) => e.id), <String>['row']);
  });

  test('clearFilters resets the query and the muscle filter', () async {
    final provider = _provider();
    await provider.load();

    provider.search('bench');
    provider.setMuscleFilter('Chest');
    provider.clearFilters();

    expect(provider.query, isEmpty);
    expect(provider.muscleFilter, isNull);
    expect(provider.filtered.length, _library.length);

    provider.setMuscleFilter('Back');
    provider.clearSearch();
    expect(provider.muscleFilter, 'Back');
    expect(provider.filtered.map((e) => e.id), <String>['row', 'pulldown']);
  });
}
