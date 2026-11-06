import '../models/unit_preferences.dart';

/// Converts stored metric values to display units and formats them.
///
/// Storage stays in kilograms, centimeters, and kilometers.
class UnitConversionService {
  const UnitConversionService();

  static const double _lbPerKg = 2.2046226218487757;
  static const double _inPerCm = 0.39370078740157477;
  static const double _miPerKm = 0.621371192237334;

  double kgToLb(double kg) => kg * _lbPerKg;

  double lbToKg(double lb) => lb / _lbPerKg;

  /// Snaps a user-entered kilogram value to the half-kilogram input step.
  double roundInputKg(double kg) => (kg * 2).round() / 2;

  double cmToIn(double cm) => cm * _inPerCm;

  double inToCm(double inches) => inches / _inPerCm;

  /// Snaps a user-entered centimeter value to the one-centimeter input step.
  double roundInputCm(double cm) => cm.roundToDouble();

  double kmToMi(double km) => km * _miPerKm;

  double miToKm(double miles) => miles / _miPerKm;

  String displayWeight(double kg, WeightUnit unit) {
    final value = unit == WeightUnit.kg ? kg : kgToLb(kg);
    return '${_trimDecimal(value.toStringAsFixed(1))} ${weightLabel(unit)}';
  }

  String displayHeight(double cm, HeightUnit unit) {
    final value = unit == HeightUnit.cm ? cm : cmToIn(cm);
    return '${_trimDecimal(value.toStringAsFixed(1))} ${heightLabel(unit)}';
  }

  String displayDistance(double km, DistanceUnit unit) {
    final value = unit == DistanceUnit.km ? km : kmToMi(km);
    return '${_trimDecimal(value.toStringAsFixed(1))} ${distanceLabel(unit)}';
  }

  String weightLabel(WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kg:
        return 'kg';
      case WeightUnit.lb:
        return 'lb';
    }
  }

  String heightLabel(HeightUnit unit) {
    switch (unit) {
      case HeightUnit.cm:
        return 'cm';
      case HeightUnit.inches:
        return 'in';
    }
  }

  String distanceLabel(DistanceUnit unit) {
    switch (unit) {
      case DistanceUnit.km:
        return 'km';
      case DistanceUnit.mi:
        return 'mi';
    }
  }

  double weightIncrement(WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kg:
        return 0.5;
      case WeightUnit.lb:
        return 1;
    }
  }

  double heightIncrement(HeightUnit unit) {
    switch (unit) {
      case HeightUnit.cm:
        return 1;
      case HeightUnit.inches:
        return 1;
    }
  }

  String _trimDecimal(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }
}
