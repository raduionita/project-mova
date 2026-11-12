/// Local calendar keys. Week starts are configurable, defaulting to Monday.
class DateKeys {
  const DateKeys._();

  /// Local day key in `YYYY-MM-DD` form.
  static String dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Local midnight for the week containing [date].
  ///
  /// [weekStart] is an ISO weekday, 1=Monday through 7=Sunday.
  static DateTime weekStart(DateTime date, {int weekStart = DateTime.monday}) {
    final start = weekStart.clamp(1, 7);
    final offset = (date.weekday - start + 7) % 7;
    return DateTime(date.year, date.month, date.day - offset);
  }

  /// ISO weekdays in display order for [weekStart].
  static List<int> weekdayOrder(int weekStart) {
    final start = weekStart.clamp(1, 7);
    return <int>[
      for (var index = 0; index < 7; index++) ((start - 1 + index) % 7) + 1,
    ];
  }

  /// Seven local dates for the week containing [date].
  static List<DateTime> weekDates(
    DateTime date, {
    int weekStart = DateTime.monday,
  }) {
    final start = DateKeys.weekStart(date, weekStart: weekStart);
    return <DateTime>[
      for (var index = 0; index < 7; index++)
        DateTime(start.year, start.month, start.day + index),
    ];
  }

  /// Local month key in `YYYY-MM` form.
  static String monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  /// Days in [month] of [year], including leap-year February.
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Whole years between [birthDate] and [on], counting a birthday that has
  /// not happened yet this year as one year younger.
  static int ageOn(DateTime birthDate, DateTime on) {
    var age = on.year - birthDate.year;
    final hadBirthday =
        on.month > birthDate.month ||
        (on.month == birthDate.month && on.day >= birthDate.day);
    if (!hadBirthday) {
      age -= 1;
    }
    return age;
  }
}
