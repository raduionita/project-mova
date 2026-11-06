import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/unit_preferences.dart';
import 'package:mova/services/unit_conversion_service.dart';

void main() {
  const service = UnitConversionService();

  test('converts between metric and imperial units', () {
    expect(service.kgToLb(80), closeTo(176.37, 0.01));
    expect(service.lbToKg(176.37), closeTo(80, 0.01));
    expect(service.cmToIn(180), closeTo(70.87, 0.01));
    expect(service.inToCm(70.87), closeTo(180, 0.01));
    expect(service.kmToMi(5), closeTo(3.11, 0.01));
    expect(service.miToKm(3.11), closeTo(5, 0.01));
  });

  test('rounds inputs to the allowed step', () {
    expect(service.roundInputKg(82.2), 82);
    expect(service.roundInputKg(82.3), 82.5);
    expect(service.roundInputKg(82.25), 82.5);
    expect(service.roundInputCm(180.4), 180);
    expect(service.roundInputCm(180.5), 181);
  });

  test('formats weight without trailing zeros', () {
    expect(service.displayWeight(80, WeightUnit.kg), '80 kg');
    expect(service.displayWeight(82.5, WeightUnit.kg), '82.5 kg');
    expect(service.displayWeight(80, WeightUnit.lb), '176.4 lb');
  });

  test('formats height without trailing zeros', () {
    expect(service.displayHeight(180, HeightUnit.cm), '180 cm');
    expect(service.displayHeight(180, HeightUnit.inches), '70.9 in');
  });

  test('formats distance without trailing zeros', () {
    expect(service.displayDistance(5, DistanceUnit.km), '5 km');
    expect(service.displayDistance(5, DistanceUnit.mi), '3.1 mi');
    expect(service.displayDistance(5.5, DistanceUnit.km), '5.5 km');
  });

  test('exposes labels and increments', () {
    expect(service.weightLabel(WeightUnit.kg), 'kg');
    expect(service.weightLabel(WeightUnit.lb), 'lb');
    expect(service.heightLabel(HeightUnit.cm), 'cm');
    expect(service.heightLabel(HeightUnit.inches), 'in');
    expect(service.distanceLabel(DistanceUnit.km), 'km');
    expect(service.distanceLabel(DistanceUnit.mi), 'mi');
    expect(service.weightIncrement(WeightUnit.kg), 0.5);
    expect(service.weightIncrement(WeightUnit.lb), 1);
    expect(service.heightIncrement(HeightUnit.cm), 1);
    expect(service.heightIncrement(HeightUnit.inches), 1);
  });
}
