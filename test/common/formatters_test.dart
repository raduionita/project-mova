import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/formatters.dart';

void main() {
  test('volume uses kilograms under a tonne and tonnes above', () {
    expect(formatVolume(0), '0 kg');
    expect(formatVolume(940), '940 kg');
    expect(formatVolume(940.5), '940.5 kg');
    expect(formatVolume(1000), '1 t');
    expect(formatVolume(9400), '9.4 t');
  });

  test('duration uses mm:ss under an hour and h:mm above', () {
    expect(formatDuration(0), '00:00');
    expect(formatDuration(59), '00:59');
    expect(formatDuration(90), '01:30');
    expect(formatDuration(3599), '59:59');
    expect(formatDuration(3600), '1:00');
    expect(formatDuration(3725), '1:02');
  });

  test('steps use thousands separators', () {
    expect(formatSteps(0), '0');
    expect(formatSteps(8240), '8,240');
    expect(formatSteps(1000000), '1,000,000');
  });

  test('dates use list and detail formats', () {
    final date = DateTime(2026, 11, 2, 18, 30);

    expect(formatShortDate(date), 'Mon, Nov 2');
    expect(formatDetailDate(date), 'Nov 2, 2026');
  });

  test('relative feed time uses minutes, hours, days, then a date', () {
    final now = DateTime(2026, 11, 6, 18);

    expect(formatRelativeTime(now, now), 'Just now');
    expect(
      formatRelativeTime(now.subtract(const Duration(minutes: 5)), now),
      '5m',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(hours: 3)), now),
      '3h',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 2)), now),
      '2d',
    );
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 10)), now),
      'Tue, Oct 27',
    );
  });
}
