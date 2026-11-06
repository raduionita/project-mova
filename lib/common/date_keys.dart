/// Local calendar keys. Weeks start on Monday.
class DateKeys {
  const DateKeys._();

  /// Local day key in `YYYY-MM-DD` form.
  static String dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Local Monday at midnight for the week containing [date].
  static DateTime weekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
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
