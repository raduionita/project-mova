/// Named route paths from the navigation tree in DESIGN.md section 9.
class Routes {
  const Routes._();

  static const String welcome = '/welcome';
  static const String onboardingUnits = '/onboarding/units';
  static const String onboardingGender = '/onboarding/gender';
  static const String onboardingBirthDate = '/onboarding/birth-date';
  static const String onboardingWeight = '/onboarding/weight';
  static const String onboardingHeight = '/onboarding/height';
  static const String onboardingGoals = '/onboarding/goals';
  static const String onboardingExperience = '/onboarding/experience';
  static const String onboardingSchedule = '/onboarding/schedule';
  static const String onboardingEquipment = '/onboarding/equipment';
  static const String onboardingNotifications = '/onboarding/notifications';
  static const String onboardingPlan = '/onboarding/plan';

  static const String today = '/today';
  static const String calendar = '/calendar';
  static const String plan = '/plan';
  static const String exercises = '/exercises';

  /// Legacy Train tab route. It now opens the Calendar screen.
  static const String train = '/train';

  /// Exercise detail routes are `/train/exercises/:id`.
  static const String trainExercises = '/train/exercises';

  static String exerciseDetail(String exerciseId) {
    return '$trainExercises/${Uri.encodeComponent(exerciseId)}';
  }

  /// Returns the exercise id for a detail route, or null when [route] is not an
  /// exercise detail route.
  static String? exerciseIdFromRoute(String? route) {
    if (route == null || !route.startsWith('$trainExercises/')) {
      return null;
    }
    final id = route.substring(trainExercises.length + 1);
    if (id.isEmpty) {
      return null;
    }
    return Uri.decodeComponent(id);
  }

  /// Routine list and detail routes are `/train/routines` and
  /// `/train/routines/:id`.
  static const String routines = '/train/routines';

  static String routineDetail(String routineId) {
    return '$routines/${Uri.encodeComponent(routineId)}';
  }

  static const String routineNew = '$routines/new';

  static String routineEdit(String routineId) {
    return '${routineDetail(routineId)}/edit';
  }

  /// Returns the routine id for an edit route, or null when [route] is not a
  /// routine edit route.
  static String? routineEditIdFromRoute(String? route) {
    if (route == null ||
        !route.startsWith('$routines/') ||
        !route.endsWith('/edit')) {
      return null;
    }
    final id = route.substring(routines.length + 1, route.length - 5);
    if (id.isEmpty || id == 'new') {
      return null;
    }
    return Uri.decodeComponent(id);
  }

  /// True for the new and edit routine builder routes.
  static bool isRoutineBuilderRoute(String? route) {
    return route == routineNew || routineEditIdFromRoute(route) != null;
  }

  /// Returns the routine id for a detail route, or null for the list, builder,
  /// or unrelated routes.
  static String? routineIdFromRoute(String? route) {
    if (route == null || !route.startsWith('$routines/')) {
      return null;
    }
    final id = route.substring(routines.length + 1);
    if (id.isEmpty || id == 'new' || id.endsWith('/edit')) {
      return null;
    }
    return Uri.decodeComponent(id);
  }

  static const String progress = '/progress';

  /// Workout history routes are `/progress/history` and
  /// `/progress/history/:id`.
  static const String progressHistory = '$progress/history';
  static const String progressWeight = '$progress/weight';
  static const String progressPhotos = '$progress/photos';

  static String progressHistoryDetail(String sessionId) {
    return '$progressHistory/${Uri.encodeComponent(sessionId)}';
  }

  /// Returns the session id for a history detail route, or null for the list
  /// and unrelated routes.
  static String? progressHistoryIdFromRoute(String? route) {
    if (route == null || !route.startsWith('$progressHistory/')) {
      return null;
    }
    final id = route.substring(progressHistory.length + 1);
    if (id.isEmpty) {
      return null;
    }
    return Uri.decodeComponent(id);
  }

  static const String social = '/social';
  static const String me = '/me';

  static const String meEdit = '$me/edit';
  static const String meSettings = '$me/settings';
  static const String meEquipment = '$me/equipment';

  /// Legal document routes are `/me/legal/:doc`.
  static const String meLegal = '$me/legal';

  static String legalDocument(String doc) {
    return '$meLegal/${Uri.encodeComponent(doc)}';
  }

  /// Returns the document id for a legal route, or null when [route] is not a
  /// legal document route.
  static String? legalDocFromRoute(String? route) {
    if (route == null || !route.startsWith('$meLegal/')) {
      return null;
    }
    final doc = route.substring(meLegal.length + 1);
    if (doc.isEmpty || doc.contains('/')) {
      return null;
    }
    return Uri.decodeComponent(doc);
  }

  static const String meLicenses = '$me/licenses';

  static const String logger = '/logger';
  static const String run = '/run';
  static const String summary = '/summary';

  /// Ordered onboarding steps after the welcome screen.
  static const List<String> onboardingSteps = <String>[
    onboardingUnits,
    onboardingGender,
    onboardingBirthDate,
    onboardingWeight,
    onboardingHeight,
    onboardingGoals,
    onboardingExperience,
    onboardingSchedule,
    onboardingEquipment,
    onboardingNotifications,
    onboardingPlan,
  ];
}
