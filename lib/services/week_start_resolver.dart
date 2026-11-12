/// Resolves the effective week start from an explicit override or locale.
class WeekStartResolver {
  const WeekStartResolver();

  /// Flutter's first day index is 0=Sunday through 6=Saturday.
  ///
  /// Returns an ISO weekday, 1=Monday through 7=Sunday. An unknown locale
  /// falls back to Monday.
  int resolve({int? override, required int localeFirstDayIndex}) {
    if (override != null && override >= 1 && override <= 7) {
      return override;
    }
    if (localeFirstDayIndex < 0 || localeFirstDayIndex > 6) {
      return DateTime.monday;
    }
    return localeFirstDayIndex == 0 ? 7 : localeFirstDayIndex;
  }
}
