/// Muscle focus choices shown when an empty workout starts.
enum FocusArea {
  all(label: 'All', muscles: <String>[]),
  fullBody(label: 'Full body', muscles: <String>['Full Body']),
  upper(
    label: 'Upper',
    muscles: <String>[
      'Chest',
      'Back',
      'Shoulders',
      'Biceps',
      'Triceps',
      'Forearms',
    ],
  ),
  lower(
    label: 'Lower',
    muscles: <String>['Quads', 'Hamstrings', 'Glutes', 'Calves'],
  ),
  push(label: 'Push', muscles: <String>['Chest', 'Shoulders', 'Triceps']),
  pull(label: 'Pull', muscles: <String>['Back', 'Biceps', 'Forearms']),
  legs(
    label: 'Legs',
    muscles: <String>['Quads', 'Hamstrings', 'Glutes', 'Calves'],
  ),
  chest(label: 'Chest', muscles: <String>['Chest']),
  back(label: 'Back', muscles: <String>['Back']),
  shoulders(label: 'Shoulders', muscles: <String>['Shoulders']),
  arms(label: 'Arms', muscles: <String>['Biceps', 'Triceps', 'Forearms']),
  core(label: 'Core', muscles: <String>['Core']);

  const FocusArea({required this.label, required this.muscles});

  final String label;
  final List<String> muscles;
}
