import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/equipment_group.dart';

void main() {
  group('EquipmentGroup', () {
    test('defaults to every group', () {
      expect(EquipmentGroup.all, EquipmentGroup.values);
      expect(EquipmentGroup.fromJson(null), EquipmentGroup.values);
      expect(EquipmentGroup.fromJson('not-a-list'), EquipmentGroup.values);
    });

    test('reads names and ignores unknown values', () {
      final parsed = EquipmentGroup.fromJson(<String>[
        'dumbbells',
        'unknown',
        'barbell',
        'dumbbells',
      ]);

      expect(parsed, <EquipmentGroup>[
        EquipmentGroup.dumbbells,
        EquipmentGroup.barbell,
      ]);
    });

    test('falls back to every group when storage is empty', () {
      expect(EquipmentGroup.fromJson(const <String>[]), EquipmentGroup.values);
    });

    test('serialises group names', () {
      expect(
        EquipmentGroup.toJson(const <EquipmentGroup>[
          EquipmentGroup.bodyweight,
          EquipmentGroup.cables,
        ]),
        <String>['bodyweight', 'cables'],
      );
    });

    test('expands groups into library equipment values', () {
      final equipment = EquipmentGroup.expand(const <EquipmentGroup>[
        EquipmentGroup.barbell,
        EquipmentGroup.accessories,
      ]);

      expect(equipment, <String>{
        'Barbell',
        'EZ Bar',
        'Ab Wheel',
        'Medicine Ball',
        'Sled',
      });
    });

    test('every group maps at least one library equipment value', () {
      for (final group in EquipmentGroup.values) {
        expect(group.equipment, isNotEmpty, reason: group.name);
        expect(group.label, isNotEmpty, reason: group.name);
        expect(group.description, isNotEmpty, reason: group.name);
      }
    });
  });
}
