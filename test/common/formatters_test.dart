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
}
