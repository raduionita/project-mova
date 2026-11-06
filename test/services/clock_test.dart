import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/clock.dart';

void main() {
  test('system clock returns wall time', () {
    final before = DateTime.now();
    final now = const SystemClock().now();
    final after = DateTime.now();

    expect(now.isBefore(before), isFalse);
    expect(now.isAfter(after), isFalse);
  });

  test('fake clock can be set and advanced', () {
    final clock = FakeClock(DateTime.utc(2026, 11, 5, 12));

    expect(clock.now(), DateTime.utc(2026, 11, 5, 12));

    clock.advance(const Duration(minutes: 30));
    expect(clock.now(), DateTime.utc(2026, 11, 5, 12, 30));

    clock.set(DateTime.utc(2027, 1, 1));
    expect(clock.now(), DateTime.utc(2027, 1, 1));
  });
}
