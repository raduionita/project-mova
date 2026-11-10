import '../models/goal.dart';
import '../theme/app_icons.dart';

/// Display label for a training goal.
String goalLabel(Goal goal) {
  switch (goal) {
    case Goal.buildMuscle:
      return 'Build muscle';
    case Goal.getStronger:
      return 'Get stronger';
    case Goal.loseWeight:
      return 'Lose weight';
    case Goal.stayHealthy:
      return 'Stay healthy';
  }
}

/// One-line explanation of a training goal.
String goalDescription(Goal goal) {
  switch (goal) {
    case Goal.buildMuscle:
      return 'Add size with steady volume.';
    case Goal.getStronger:
      return 'Lift heavier with lower reps.';
    case Goal.loseWeight:
      return 'Burn energy with higher reps.';
    case Goal.stayHealthy:
      return 'Train consistently without burnout.';
  }
}

/// SVG asset that represents a training goal.
String goalIcon(Goal goal) {
  switch (goal) {
    case Goal.buildMuscle:
      return AppIcons.dumbbell;
    case Goal.getStronger:
      return AppIcons.trophy;
    case Goal.loseWeight:
      return AppIcons.flame;
    case Goal.stayHealthy:
      return AppIcons.heart;
  }
}
