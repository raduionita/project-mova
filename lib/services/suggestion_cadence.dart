import '../models/plan_day.dart';
import '../models/training_plan.dart';

/// One dashed future suggestion on the calendar.
class SuggestedSessionDate {
  const SuggestedSessionDate({
    required this.date,
    required this.day,
    required this.dayIndex,
  });

  final DateTime date;
  final PlanDay day;
  final int dayIndex;
}

/// Places the next rotation sessions on future calendar days.
class SuggestionCadence {
  const SuggestionCadence();

  /// Returns the next [count] suggested days, starting after [from].
  ///
  /// Spacing follows the average frequency, so a 3 day plan suggests roughly
  /// every other day while a 1 day plan suggests once a week.
  List<SuggestedSessionDate> next({
    required TrainingPlan plan,
    required int startIndex,
    required DateTime from,
    int count = 3,
  }) {
    if (plan.days.isEmpty || count <= 0) {
      return const <SuggestedSessionDate>[];
    }
    final interval = (7 / plan.daysPerWeek.clamp(1, 7)).round().clamp(1, 7);
    final base = DateTime(from.year, from.month, from.day);
    final suggestions = <SuggestedSessionDate>[];
    for (var index = 0; index < count; index++) {
      final dayIndex = (startIndex + index) % plan.days.length;
      suggestions.add(
        SuggestedSessionDate(
          date: DateTime(base.year, base.month, base.day + interval * (index + 1)),
          day: plan.days[dayIndex],
          dayIndex: dayIndex,
        ),
      );
    }
    return suggestions;
  }
}
