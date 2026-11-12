import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/week_start_resolver.dart';

void main() {
  const resolver = WeekStartResolver();

  test('an explicit override wins over the locale', () {
    expect(
      resolver.resolve(override: DateTime.sunday, localeFirstDayIndex: 1),
      DateTime.sunday,
    );
    expect(
      resolver.resolve(override: DateTime.saturday, localeFirstDayIndex: 0),
      DateTime.saturday,
    );
  });

  test('locale indices convert from Sunday-first to ISO weekdays', () {
    expect(resolver.resolve(localeFirstDayIndex: 0), DateTime.sunday);
    expect(resolver.resolve(localeFirstDayIndex: 1), DateTime.monday);
    expect(resolver.resolve(localeFirstDayIndex: 6), DateTime.saturday);
  });

  test('unknown locale indices and invalid overrides fall back to Monday', () {
    expect(resolver.resolve(localeFirstDayIndex: -1), DateTime.monday);
    expect(resolver.resolve(localeFirstDayIndex: 7), DateTime.monday);
    expect(
      resolver.resolve(override: 0, localeFirstDayIndex: 7),
      DateTime.monday,
    );
    expect(
      resolver.resolve(override: 8, localeFirstDayIndex: 0),
      DateTime.sunday,
    );
  });
}
