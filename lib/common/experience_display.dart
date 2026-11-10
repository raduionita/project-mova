import '../models/experience_level.dart';
import '../theme/app_icons.dart';

/// Display label for a training experience level.
String experienceLevelLabel(ExperienceLevel level) {
  switch (level) {
    case ExperienceLevel.beginner:
      return 'Beginner';
    case ExperienceLevel.regular:
      return 'Regular';
    case ExperienceLevel.gymRat:
      return 'Gym rat';
    case ExperienceLevel.veteran:
      return 'Veteran';
  }
}

/// SVG asset that represents an experience level.
///
/// Onboarding, profile edit, and the Me avatar all read from this map so the
/// icon a user picks stays the icon they see later.
String experienceLevelIcon(ExperienceLevel level) {
  switch (level) {
    case ExperienceLevel.beginner:
      return AppIcons.seedling;
    case ExperienceLevel.regular:
      return AppIcons.dumbbell;
    case ExperienceLevel.gymRat:
      return AppIcons.flame;
    case ExperienceLevel.veteran:
      return AppIcons.trophy;
  }
}
