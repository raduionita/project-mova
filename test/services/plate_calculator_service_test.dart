import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/plate_loadout.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/services/plate_calculator_service.dart';

const PlateCalculatorService _service = PlateCalculatorService();

void main() {
  test('loads 100 kg with a 20 kg bar as 25 and 15 per side', () {
    final result = _service.calculate(
      target: 100,
      loadout: PlateLoadout.kg,
      barWeight: 20,
    );

    expect(result.belowBar, isFalse);
    expect(result.isExact, isTrue);
    expect(result.platesPerSide, <double, int>{25: 1, 15: 1});
    expect(result.achieved, 100);
  });

  test('loads 225 lb with a 45 lb bar as two 45s per side', () {
    final result = _service.calculate(
      target: 225,
      loadout: PlateLoadout.lb,
      barWeight: 45,
    );

    expect(result.isExact, isTrue);
    expect(result.platesPerSide, <double, int>{45: 2});
    expect(result.achieved, 225);
  });

  test('uses several plates when needed', () {
    final result = _service.calculate(
      target: 140,
      loadout: PlateLoadout.kg,
      barWeight: 20,
    );

    expect(result.isExact, isTrue);
    expect(result.platesPerSide, <double, int>{25: 2, 10: 1});
  });

  test('reports the remainder when the target is not loadable', () {
    final result = _service.calculate(
      target: 103,
      loadout: PlateLoadout.kg,
      barWeight: 20,
    );

    expect(result.isExact, isFalse);
    expect(result.achieved, 102.5);
    expect(result.remainder, closeTo(0.5, 0.001));
  });

  test('flags targets below the bar', () {
    final result = _service.calculate(
      target: 10,
      loadout: PlateLoadout.kg,
      barWeight: 20,
    );

    expect(result.belowBar, isTrue);
    expect(result.platesPerSide, isEmpty);
    expect(result.achieved, 20);
    expect(result.isExact, isFalse);
  });

  test('falls back to the loadout bar for invalid bar input', () {
    final result = _service.calculate(
      target: 100,
      loadout: PlateLoadout.kg,
      barWeight: 0,
    );

    expect(result.barWeight, PlateLoadout.kg.defaultBarWeight);
    expect(result.achieved, 100);
  });

  test('treats invalid targets as zero', () {
    final result = _service.calculate(
      target: -20,
      loadout: PlateLoadout.kg,
      barWeight: 20,
    );

    expect(result.target, 0);
    expect(result.belowBar, isTrue);
  });

  test('resolves the loadout for each unit', () {
    expect(PlateLoadout.forUnit(WeightUnit.kg), same(PlateLoadout.kg));
    expect(PlateLoadout.forUnit(WeightUnit.lb), same(PlateLoadout.lb));
  });
}
