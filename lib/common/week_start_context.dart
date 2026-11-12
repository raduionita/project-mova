import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/week_start_resolver.dart';

/// Effective ISO week start for the current context.
int effectiveWeekStart(BuildContext context) {
  final override = context.watch<SettingsProvider>().settings.weekStart;
  final localeIndex = MaterialLocalizations.of(context).firstDayOfWeekIndex;
  return const WeekStartResolver().resolve(
    override: override,
    localeFirstDayIndex: localeIndex,
  );
}

/// English label for an ISO weekday.
String weekStartDayName(int weekStart) {
  switch (weekStart) {
    case DateTime.monday:
      return 'Monday';
    case DateTime.tuesday:
      return 'Tuesday';
    case DateTime.wednesday:
      return 'Wednesday';
    case DateTime.thursday:
      return 'Thursday';
    case DateTime.friday:
      return 'Friday';
    case DateTime.saturday:
      return 'Saturday';
    case DateTime.sunday:
      return 'Sunday';
    default:
      return 'Monday';
  }
}

/// Value shown in Me and Settings.
String weekStartValueLabel({required int? override, required int effective}) {
  if (override == null) {
    return 'Automatic (${weekStartDayName(effective)})';
  }
  return weekStartDayName(override);
}
