import '../models/plan_day.dart';
import '../models/training_plan.dart';
import '../models/workout_session.dart';

/// Next rotation session plus a short reason and optional recovery warning.
class SessionSuggestion {
  const SessionSuggestion({
    required this.day,
    required this.dayIndex,
    required this.reason,
    this.recoveryWarning,
    this.lastSession,
  });

  final PlanDay day;
  final int dayIndex;
  final String reason;
  final String? recoveryWarning;
  final WorkoutSession? lastSession;
}

/// Picks the next plan session from completed rotation history.
class SessionSuggestionService {
  const SessionSuggestionService();

  /// Copy shown when no plan exists yet.
  static const String noPlanReason =
      'Choose a focus and Mova will suggest exercises.';

  /// Returns the next session after the most recent completed plan workout.
  ///
  /// Only completed plan sessions after [TrainingPlan.generatedAt] advance the
  /// rotation. Routines, empty workouts, and walks never move it.
  SessionSuggestion? suggest({
    required TrainingPlan? plan,
    required List<WorkoutSession> history,
    required DateTime now,
  }) {
    if (plan == null || plan.days.isEmpty) {
      return null;
    }

    final completed = history
        .where((session) {
          if (session.status != SessionStatus.completed) {
            return false;
          }
          if (session.source != SessionSource.plan) {
            return false;
          }
          final finishedAt = session.completedAt ?? session.startedAt;
          return !finishedAt.isBefore(plan.generatedAt);
        })
        .toList(growable: false)
      ..sort((a, b) {
        final aDate = a.completedAt ?? a.startedAt;
        final bDate = b.completedAt ?? b.startedAt;
        return aDate.compareTo(bDate);
      });

    final last = completed.isEmpty ? null : completed.last;
    var nextIndex = 0;
    if (last != null) {
      final slot = last.slotKey;
      final lastIndex = slot == null
          ? -1
          : plan.days.indexWhere((day) => day.slotKey == slot);
      if (lastIndex != -1) {
        nextIndex = (lastIndex + 1) % plan.days.length;
      }
    }

    final day = plan.days[nextIndex];
    return SessionSuggestion(
      day: day,
      dayIndex: nextIndex,
      reason: _reason(plan, history, last, now),
      recoveryWarning: _recoveryWarning(last, now),
      lastSession: last,
    );
  }

  String _reason(
    TrainingPlan plan,
    List<WorkoutSession> history,
    WorkoutSession? last,
    DateTime now,
  ) {
    final neglected = _neglectedMuscle(plan, history, now);
    if (neglected != null) {
      return 'You have not trained ${neglected.muscle.toLowerCase()} '
          'in ${neglected.days} days';
    }
    if (last == null) {
      return 'Start your rotation with Day 1.';
    }
    final days = _daysBetween(last.completedAt ?? last.startedAt, now);
    final title = last.displayTitle.trim().isEmpty
        ? last.name.trim()
        : last.displayTitle.trim();
    if (days <= 0) {
      return 'Because you trained $title today';
    }
    if (days == 1) {
      return 'Because you trained $title 1 day ago';
    }
    return 'Because you trained $title $days days ago';
  }

  String? _recoveryWarning(WorkoutSession? last, DateTime now) {
    if (last == null) {
      return null;
    }
    final days = _daysBetween(last.completedAt ?? last.startedAt, now);
    if (days > 0) {
      return null;
    }
    final title = last.displayTitle.trim().isEmpty
        ? last.name.trim()
        : last.displayTitle.trim();
    return 'You trained $title today. This is a suggestion, not a block.';
  }

  _MuscleGap? _neglectedMuscle(
    TrainingPlan plan,
    List<WorkoutSession> history,
    DateTime now,
  ) {
    final muscles = <String>{
      for (final day in plan.days)
        for (final muscle in day.muscleGroups) muscle,
    };
    if (muscles.isEmpty || history.isEmpty) {
      return null;
    }

    final lastTrained = <String, DateTime>{};
    for (final session in history) {
      if (session.status != SessionStatus.completed) {
        continue;
      }
      final at = session.completedAt ?? session.startedAt;
      final sessionMuscles = session.muscleGroups.isEmpty
          ? _musclesForPlanDay(plan, session.planDayId)
          : session.muscleGroups;
      for (final muscle in sessionMuscles) {
        final current = lastTrained[muscle];
        if (current == null || at.isAfter(current)) {
          lastTrained[muscle] = at;
        }
      }
    }
    if (lastTrained.isEmpty) {
      return null;
    }

    _MuscleGap? best;
    for (final muscle in muscles) {
      final at = lastTrained[muscle];
      if (at == null) {
        continue;
      }
      final days = _daysBetween(at, now);
      if (days < 7) {
        continue;
      }
      if (best == null || days > best.days) {
        best = _MuscleGap(muscle: muscle, days: days);
      }
    }
    return best;
  }

  List<String> _musclesForPlanDay(TrainingPlan plan, String? planDayId) {
    if (planDayId == null) {
      return const <String>[];
    }
    for (final day in plan.days) {
      if (day.id == planDayId) {
        return day.muscleGroups;
      }
    }
    return const <String>[];
  }

  int _daysBetween(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    return end.difference(start).inDays;
  }
}

class _MuscleGap {
  const _MuscleGap({required this.muscle, required this.days});

  final String muscle;
  final int days;
}
