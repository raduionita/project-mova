import 'dart:collection';

/// Result of calculating plates for one barbell target.
class PlateCalculation {
  PlateCalculation({
    required this.target,
    required this.barWeight,
    required this.perSideTarget,
    required Map<double, int> platesPerSide,
    required this.achieved,
    required this.remainder,
    required this.belowBar,
  }) : platesPerSide = Map<double, int>.unmodifiable(
         LinkedHashMap<double, int>.fromEntries(
           platesPerSide.entries.toList()
             ..sort((a, b) => b.key.compareTo(a.key)),
         ),
       );

  final double target;
  final double barWeight;
  final double perSideTarget;
  final Map<double, int> platesPerSide;
  final double achieved;
  final double remainder;
  final bool belowBar;

  bool get isExact => !belowBar && remainder.abs() <= 0.01;

  List<double> get plates => platesPerSide.keys.toList(growable: false);
}
