import '../models/onboarding_draft.dart';
import 'routes.dart';

/// Route order and resume helpers for the 11 onboarding screens.
class OnboardingFlow {
  const OnboardingFlow._();

  static const int totalSteps = 11;

  static const String firstRoute = Routes.onboardingUnits;
  static const String lastRoute = Routes.onboardingPlan;

  /// 1-based step for [route], or 0 when the route is not an onboarding step
  /// after welcome.
  static int stepForRoute(String route) {
    final index = Routes.onboardingSteps.indexOf(route);
    return index == -1 ? 0 : index + 1;
  }

  /// The draft step for [route]. Routes outside onboarding map to welcome.
  static OnboardingStep stepFor(String route) {
    if (route == Routes.welcome) {
      return OnboardingStep.welcome;
    }
    final index = Routes.onboardingSteps.indexOf(route);
    if (index == -1) {
      return OnboardingStep.welcome;
    }
    return OnboardingStep.values[index + 1];
  }

  /// Route for a 1-based [step], clamped into the valid range.
  static String routeForStep(int step) {
    final index = step.clamp(1, totalSteps) - 1;
    return Routes.onboardingSteps[index];
  }

  /// The route a saved draft should resume at.
  static String resumeRoute(OnboardingDraft draft) {
    if (draft.currentStep == OnboardingStep.welcome) {
      return Routes.welcome;
    }
    return routeForStep(draft.currentStep.index);
  }

  static String? nextRoute(String route) {
    if (route == Routes.welcome) {
      return firstRoute;
    }
    final step = stepForRoute(route);
    if (step == 0 || step >= totalSteps) {
      return null;
    }
    return routeForStep(step + 1);
  }

  static String? previousRoute(String route) {
    if (route == Routes.welcome) {
      return null;
    }
    final step = stepForRoute(route);
    if (step == 0) {
      return null;
    }
    if (step == 1) {
      return Routes.welcome;
    }
    return routeForStep(step - 1);
  }

  static bool isOnboardingRoute(String route) {
    return route == Routes.welcome || stepForRoute(route) > 0;
  }

  static bool isLastStep(String route) => route == lastRoute;
}
