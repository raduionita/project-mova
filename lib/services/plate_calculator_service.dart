import '../models/plate_calculation.dart';
import '../models/plate_loadout.dart';

/// Greedy plate loading for a target barbell weight.
class PlateCalculatorService {
  const PlateCalculatorService();

  PlateCalculation calculate({
    required double target,
    required PlateLoadout loadout,
    required double barWeight,
  }) {
    final safeTarget = target.isFinite && target > 0 ? target : 0.0;
    final safeBar = barWeight.isFinite && barWeight > 0
        ? barWeight
        : loadout.defaultBarWeight;
    final perSide = (safeTarget - safeBar) / 2;

    if (perSide < 0) {
      return PlateCalculation(
        target: safeTarget,
        barWeight: safeBar,
        perSideTarget: perSide,
        platesPerSide: const <double, int>{},
        achieved: safeBar,
        remainder: 0,
        belowBar: true,
      );
    }

    final plates = <double, int>{};
    var remaining = perSide;
    for (final plate in loadout.plateWeights) {
      if (remaining + 0.001 < plate) {
        continue;
      }
      final count = (remaining / plate).floor();
      if (count > 0) {
        plates[plate] = count;
        remaining -= plate * count;
      }
    }

    final loaded = plates.entries.fold<double>(
      0,
      (total, entry) => total + entry.key * entry.value,
    );
    final achieved = safeBar + loaded * 2;
    return PlateCalculation(
      target: safeTarget,
      barWeight: safeBar,
      perSideTarget: perSide,
      platesPerSide: plates,
      achieved: achieved,
      remainder: safeTarget - achieved,
      belowBar: false,
    );
  }
}
