import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/progression_suggestion.dart';

void main() {
  group('ProgressionSuggestion', () {
    const suggestion = ProgressionSuggestion(
      exerciseId: 'barbell-bench-press',
      weightKg: 82.5,
      reps: 8,
      previousWeightKg: 80,
      previousReps: 12,
      action: ProgressionAction.increase,
      sourceWorkoutId: 'session-1',
      sourceSetId: 'set-1',
    );

    test('round-trips through JSON', () {
      final decoded = ProgressionSuggestion.fromJson(suggestion.toJson());

      expect(decoded.toJson(), suggestion.toJson());
      expect(decoded.isIncrease, isTrue);
    });

    test('reads missing fields with safe defaults', () {
      final decoded = ProgressionSuggestion.fromJson(const <String, dynamic>{});

      expect(decoded.exerciseId, '');
      expect(decoded.weightKg, 0);
      expect(decoded.reps, 0);
      expect(decoded.action, ProgressionAction.repeat);
      expect(decoded.sourceWorkoutId, isNull);
      expect(decoded.sourceSetId, isNull);
      expect(decoded.isIncrease, isFalse);
    });

    test('copyWith replaces only the supplied fields', () {
      final updated = suggestion.copyWith(
        weightKg: 85,
        action: ProgressionAction.repeat,
      );

      expect(updated.weightKg, 85);
      expect(updated.action, ProgressionAction.repeat);
      expect(updated.previousWeightKg, suggestion.previousWeightKg);
      expect(updated.sourceSetId, suggestion.sourceSetId);
    });
  });
}
