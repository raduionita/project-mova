import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/date_keys.dart';

void main() {
  test('day keys are local and zero padded', () {
    expect(DateKeys.dayKey(DateTime(2026, 1, 5)), '2026-01-05');
    expect(DateKeys.dayKey(DateTime(2026, 11, 2, 23, 59)), '2026-11-02');
  });

  test('month keys are zero padded', () {
    expect(DateKeys.monthKey(DateTime(2026, 1, 5)), '2026-01');
    expect(DateKeys.monthKey(DateTime(2026, 11, 30)), '2026-11');
  });

  test('days in month handles leap years', () {
    expect(DateKeys.daysInMonth(2024, 2), 29);
    expect(DateKeys.daysInMonth(2025, 2), 28);
    expect(DateKeys.daysInMonth(2026, 4), 30);
    expect(DateKeys.daysInMonth(2026, 12), 31);
  });

  test('age counts a birthday that has not happened yet', () {
    final on = DateTime(2026, 11, 5);
    expect(DateKeys.ageOn(DateTime(2001, 11, 5), on), 25);
    expect(DateKeys.ageOn(DateTime(2001, 11, 6), on), 24);
    expect(DateKeys.ageOn(DateTime(2013, 11, 6), on), 12);
    expect(DateKeys.ageOn(DateTime(2013, 11, 5), on), 13);
    expect(DateKeys.ageOn(DateTime(1906, 1, 1), on), 120);
  });

  test('weeks start on Monday at local midnight', () {
    final sunday = DateTime(2026, 11, 8, 23, 30);
    final monday = DateKeys.weekStart(sunday);

    expect(monday, DateTime(2026, 11, 2));
    expect(monday.weekday, DateTime.monday);
    expect(DateKeys.weekStart(DateTime(2026, 11, 2)), DateTime(2026, 11, 2));
  });

  test('weeks can start on Sunday', () {
    final wednesday = DateTime(2026, 11, 4, 9);

    expect(
      DateKeys.weekStart(wednesday, weekStart: DateTime.sunday),
      DateTime(2026, 11, 1),
    );
    expect(
      DateKeys.weekStart(
        DateTime(2026, 11, 8, 23, 59),
        weekStart: DateTime.sunday,
      ),
      DateTime(2026, 11, 8),
    );
    expect(
      DateKeys.weekStart(DateTime(2026, 11, 7), weekStart: DateTime.saturday),
      DateTime(2026, 11, 7),
    );
  });

  test('weekday order follows the configured start', () {
    expect(DateKeys.weekdayOrder(DateTime.monday), <int>[1, 2, 3, 4, 5, 6, 7]);
    expect(DateKeys.weekdayOrder(DateTime.sunday), <int>[7, 1, 2, 3, 4, 5, 6]);
    expect(DateKeys.weekdayOrder(DateTime.saturday), <int>[
      6,
      7,
      1,
      2,
      3,
      4,
      5,
    ]);
  });

  test('week dates return seven local midnights from the start', () {
    final dates = DateKeys.weekDates(
      DateTime(2026, 11, 4, 15, 30),
      weekStart: DateTime.sunday,
    );

    expect(dates, hasLength(7));
    expect(dates.first, DateTime(2026, 11, 1));
    expect(dates.last, DateTime(2026, 11, 7));
    expect(dates.every((date) => date.hour == 0), isTrue);
  });
}
