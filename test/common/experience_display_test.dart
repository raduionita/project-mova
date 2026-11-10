import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/experience_display.dart';
import 'package:mova/models/experience_level.dart';
import 'package:mova/theme/app_icons.dart';

void main() {
  test('labels every experience level', () {
    expect(experienceLevelLabel(ExperienceLevel.beginner), 'Beginner');
    expect(experienceLevelLabel(ExperienceLevel.regular), 'Regular');
    expect(experienceLevelLabel(ExperienceLevel.gymRat), 'Gym rat');
    expect(experienceLevelLabel(ExperienceLevel.veteran), 'Veteran');
  });

  test('maps every experience level to its onboarding icon', () {
    expect(experienceLevelIcon(ExperienceLevel.beginner), AppIcons.seedling);
    expect(experienceLevelIcon(ExperienceLevel.regular), AppIcons.dumbbell);
    expect(experienceLevelIcon(ExperienceLevel.gymRat), AppIcons.flame);
    expect(experienceLevelIcon(ExperienceLevel.veteran), AppIcons.trophy);
  });
}
