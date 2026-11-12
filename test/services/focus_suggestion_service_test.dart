import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/equipment_group.dart';
import 'package:mova/models/exercise.dart';
import 'package:mova/models/focus_area.dart';
import 'package:mova/services/focus_suggestion_service.dart';

const List<Exercise> _exercises = <Exercise>[
  Exercise(
    id: 'bench',
    name: 'Bench Press',
    primaryMuscle: 'Chest',
    secondaryMuscles: <String>['Triceps', 'Shoulders'],
    equipment: 'Barbell',
    isCompound: true,
  ),
  Exercise(
    id: 'fly',
    name: 'Cable Fly',
    primaryMuscle: 'Chest',
    secondaryMuscles: <String>['Shoulders'],
    equipment: 'Cable',
  ),
  Exercise(
    id: 'row',
    name: 'Barbell Row',
    primaryMuscle: 'Back',
    secondaryMuscles: <String>['Biceps'],
    equipment: 'Barbell',
    isCompound: true,
  ),
  Exercise(
    id: 'squat',
    name: 'Back Squat',
    primaryMuscle: 'Quads',
    secondaryMuscles: <String>['Glutes'],
    equipment: 'Barbell',
    isCompound: true,
  ),
  Exercise(
    id: 'pushup',
    name: 'Push Up',
    primaryMuscle: 'Chest',
    secondaryMuscles: <String>['Triceps'],
    equipment: 'Bodyweight',
    isCompound: true,
  ),
  Exercise(
    id: 'burpee',
    name: 'Burpee',
    primaryMuscle: 'Full Body',
    secondaryMuscles: <String>[],
    equipment: 'Bodyweight',
    isCompound: true,
  ),
];

void main() {
  const service = FocusSuggestionService();

  test('push focuses on chest, shoulders, and triceps', () {
    final result = service.suggest(
      focus: FocusArea.push,
      exercises: _exercises,
      availableEquipment: EquipmentGroup.values,
    );
    expect(result.map((item) => item.id), <String>[
      'bench',
      'fly',
      'pushup',
    ]);
  });

  test('excluded exercises and unavailable equipment are removed', () {
    final result = service.suggest(
      focus: FocusArea.push,
      exercises: _exercises,
      availableEquipment: const <EquipmentGroup>[
        EquipmentGroup.bodyweight,
        EquipmentGroup.barbell,
      ],
      excludedExerciseIds: const <String>{'bench'},
    );
    expect(result.map((item) => item.id), <String>['pushup']);
  });

  test('full body falls back to compound movements', () {
    final result = service.suggest(
      focus: FocusArea.fullBody,
      exercises: _exercises,
      availableEquipment: EquipmentGroup.values,
    );
    expect(result.first.id, 'burpee');
    expect(result.any((item) => item.isCompound), isTrue);
  });

  test('all returns the requested number of unique exercises', () {
    final result = service.suggest(
      focus: FocusArea.all,
      exercises: _exercises,
      availableEquipment: EquipmentGroup.values,
      limit: 4,
    );
    expect(result, hasLength(4));
    expect(result.map((item) => item.id).toSet(), hasLength(4));
  });

  test('legs uses lower body muscles', () {
    final result = service.suggest(
      focus: FocusArea.lower,
      exercises: _exercises,
      availableEquipment: EquipmentGroup.values,
    );
    expect(result.map((item) => item.id), <String>['squat']);
  });

  test('empty input and non-positive limit return empty lists', () {
    expect(
      service.suggest(
        focus: FocusArea.all,
        exercises: const <Exercise>[],
      ),
      isEmpty,
    );
    expect(
      service.suggest(
        focus: FocusArea.all,
        exercises: _exercises,
        limit: 0,
      ),
      isEmpty,
    );
  });
}
