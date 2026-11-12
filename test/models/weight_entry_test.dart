import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/weight_entry.dart';

void main() {
  test('WeightEntry round-trips through JSON', () {
    final entry = WeightEntry(
      dateKey: '2026-11-06',
      weightKg: 79.5,
      updatedAt: DateTime.utc(2026, 11, 6, 8, 30),
    );

    final decoded = WeightEntry.fromJson(entry.toJson());

    expect(decoded.dateKey, '2026-11-06');
    expect(decoded.weightKg, 79.5);
    expect(decoded.updatedAt, DateTime.utc(2026, 11, 6, 8, 30));
  });
}
