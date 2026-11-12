import '../models/equipment_group.dart';
import '../models/exercise.dart';
import '../models/focus_area.dart';

/// Picks a short, actionable exercise list for a focus selection.
class FocusSuggestionService {
  const FocusSuggestionService();

  /// Returns up to [limit] exercises that match [focus] and the available
  /// equipment. Compound movements are preferred when a focus has no exact
  /// primary muscle, such as Full body.
  List<Exercise> suggest({
    required FocusArea focus,
    required List<Exercise> exercises,
    List<EquipmentGroup>? availableEquipment,
    Set<String> excludedExerciseIds = const <String>{},
    int limit = 5,
  }) {
    if (limit <= 0 || exercises.isEmpty) {
      return const <Exercise>[];
    }
    final allowed = availableEquipment == null || availableEquipment.isEmpty
        ? null
        : EquipmentGroup.expand(availableEquipment);
    final compatible = exercises
        .where((exercise) {
          if (excludedExerciseIds.contains(exercise.id)) {
            return false;
          }
          return allowed == null || allowed.contains(exercise.equipment);
        })
        .toList(growable: false);

    final primary = <Exercise>[];
    final secondary = <Exercise>[];
    for (final exercise in compatible) {
      if (focus == FocusArea.all) {
        primary.add(exercise);
        continue;
      }
      if (focus.muscles.contains(exercise.primaryMuscle)) {
        primary.add(exercise);
      } else if (exercise.secondaryMuscles.any(focus.muscles.contains)) {
        secondary.add(exercise);
      }
    }

    final result = <Exercise>[];
    void addAll(Iterable<Exercise> source) {
      for (final exercise in source) {
        if (result.length >= limit) {
          return;
        }
        if (result.every((entry) => entry.id != exercise.id)) {
          result.add(exercise);
        }
      }
    }

    addAll(primary);
    addAll(secondary);
    if (focus == FocusArea.fullBody && result.length < limit) {
      addAll(compatible.where((exercise) => exercise.isCompound));
    }
    if (focus == FocusArea.all && result.length < limit) {
      addAll(compatible);
    }
    return List<Exercise>.unmodifiable(result);
  }
}
