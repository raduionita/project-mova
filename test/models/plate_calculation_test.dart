import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/plate_calculation.dart';

void main() {
  group('PlateCalculation', () {
    test('sorts plates from heaviest to lightest', () {
      final result = PlateCalculation(
        target: 100,
        barWeight: 20,
        perSideTarget: 40,
        platesPerSide: <double, int>{5: 1, 25: 1, 10: 1},
        achieved: 100,
        remainder: 0,
        belowBar: false,
      );

      expect(result.plates, <double>[25, 10, 5]);
      expect(result.isExact, isTrue);
    });

    test('is not exact when a remainder remains', () {
      final result = PlateCalculation(
        target: 103,
        barWeight: 20,
        perSideTarget: 41.5,
        platesPerSide: <double, int>{25: 1, 15: 1, 1.25: 1},
        achieved: 102.5,
        remainder: 0.5,
        belowBar: false,
      );

      expect(result.isExact, isFalse);
    });

    test('a target below the bar is never exact', () {
      final result = PlateCalculation(
        target: 10,
        barWeight: 20,
        perSideTarget: -5,
        platesPerSide: const <double, int>{},
        achieved: 20,
        remainder: 0,
        belowBar: true,
      );

      expect(result.isExact, isFalse);
    });
  });
}
