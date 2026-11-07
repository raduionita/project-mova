import 'unit_preferences.dart';

/// Standard bar and plate choices for one weight unit.
class PlateLoadout {
  PlateLoadout({
    required this.unit,
    required List<double> barWeights,
    required List<double> plateWeights,
  }) : barWeights = List<double>.unmodifiable(barWeights),
       plateWeights = List<double>.unmodifiable(plateWeights);

  final WeightUnit unit;
  final List<double> barWeights;
  final List<double> plateWeights;

  double get defaultBarWeight => barWeights.first;

  static final PlateLoadout kg = PlateLoadout(
    unit: WeightUnit.kg,
    barWeights: const <double>[20, 15, 10],
    plateWeights: const <double>[25, 20, 15, 10, 5, 2.5, 1.25],
  );

  static final PlateLoadout lb = PlateLoadout(
    unit: WeightUnit.lb,
    barWeights: const <double>[45, 35, 25],
    plateWeights: const <double>[45, 35, 25, 10, 5, 2.5],
  );

  static PlateLoadout forUnit(WeightUnit unit) {
    return unit == WeightUnit.kg ? kg : lb;
  }
}
