import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/goal_display.dart';
import 'package:mova/models/goal.dart';
import 'package:mova/theme/app_icons.dart';

void main() {
  test('labels every training goal', () {
    expect(goalLabel(Goal.buildMuscle), 'Build muscle');
    expect(goalLabel(Goal.getStronger), 'Get stronger');
    expect(goalLabel(Goal.loseWeight), 'Lose weight');
    expect(goalLabel(Goal.stayHealthy), 'Stay healthy');
  });

  test('describes every training goal', () {
    expect(goalDescription(Goal.buildMuscle), 'Add size with steady volume.');
    expect(goalDescription(Goal.getStronger), 'Lift heavier with lower reps.');
    expect(goalDescription(Goal.loseWeight), 'Burn energy with higher reps.');
    expect(
      goalDescription(Goal.stayHealthy),
      'Train consistently without burnout.',
    );
  });

  test('maps every training goal to its icon', () {
    expect(goalIcon(Goal.buildMuscle), AppIcons.dumbbell);
    expect(goalIcon(Goal.getStronger), AppIcons.trophy);
    expect(goalIcon(Goal.loseWeight), AppIcons.flame);
    expect(goalIcon(Goal.stayHealthy), AppIcons.heart);
  });
}
