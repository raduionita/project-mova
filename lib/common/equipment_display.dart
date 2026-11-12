import '../theme/app_icons.dart';

/// Maps an exercise library equipment value to its SVG icon and label.
class EquipmentDisplay {
  const EquipmentDisplay._();

  static String iconFor(String equipment) {
    switch (equipment) {
      case 'Barbell':
      case 'EZ Bar':
        return AppIcons.barbell;
      case 'Dumbbell':
        return AppIcons.dumbbell;
      case 'Kettlebell':
        return AppIcons.kettlebell;
      case 'Machine':
        return AppIcons.machine;
      case 'Cable':
        return AppIcons.cable;
      case 'Bodyweight':
        return AppIcons.bodyweight;
      case 'Ab Wheel':
      case 'Medicine Ball':
      case 'Sled':
        return AppIcons.accessory;
    }
    return AppIcons.dumbbell;
  }
}
