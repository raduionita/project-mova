import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/onboarding_draft.dart';
import 'package:mova/navigation/onboarding_flow.dart';
import 'package:mova/navigation/routes.dart';

void main() {
  test('step numbers follow the route order', () {
    expect(OnboardingFlow.stepForRoute(Routes.onboardingUnits), 1);
    expect(OnboardingFlow.stepForRoute(Routes.onboardingGender), 2);
    expect(OnboardingFlow.stepForRoute(Routes.onboardingBirthDate), 3);
    expect(OnboardingFlow.stepForRoute(Routes.onboardingSchedule), 8);
    expect(OnboardingFlow.stepForRoute(Routes.onboardingEquipment), 9);
    expect(OnboardingFlow.stepForRoute(Routes.onboardingNotifications), 10);
    expect(OnboardingFlow.stepForRoute(Routes.onboardingPlan), 11);
    expect(OnboardingFlow.stepForRoute(Routes.welcome), 0);
    expect(OnboardingFlow.stepForRoute(Routes.today), 0);
  });

  test('route for step clamps into range', () {
    expect(OnboardingFlow.routeForStep(1), Routes.onboardingUnits);
    expect(OnboardingFlow.routeForStep(9), Routes.onboardingEquipment);
    expect(OnboardingFlow.routeForStep(10), Routes.onboardingNotifications);
    expect(OnboardingFlow.routeForStep(11), Routes.onboardingPlan);
    expect(OnboardingFlow.routeForStep(0), Routes.onboardingUnits);
    expect(OnboardingFlow.routeForStep(99), Routes.onboardingPlan);
  });

  test('next and previous routes walk the flow', () {
    expect(OnboardingFlow.nextRoute(Routes.welcome), Routes.onboardingUnits);
    expect(
      OnboardingFlow.nextRoute(Routes.onboardingUnits),
      Routes.onboardingGender,
    );
    expect(OnboardingFlow.nextRoute(Routes.onboardingPlan), isNull);
    expect(OnboardingFlow.nextRoute(Routes.today), isNull);

    expect(
      OnboardingFlow.previousRoute(Routes.onboardingUnits),
      Routes.welcome,
    );
    expect(
      OnboardingFlow.previousRoute(Routes.onboardingGender),
      Routes.onboardingUnits,
    );
    expect(OnboardingFlow.previousRoute(Routes.welcome), isNull);
  });

  test('drafts resume at the saved step', () {
    final now = DateTime.utc(2026, 11, 5);

    expect(
      OnboardingFlow.resumeRoute(OnboardingDraft(updatedAt: now)),
      Routes.welcome,
    );
    expect(
      OnboardingFlow.resumeRoute(
        OnboardingDraft(currentStep: OnboardingStep.units, updatedAt: now),
      ),
      Routes.onboardingUnits,
    );
    expect(
      OnboardingFlow.resumeRoute(
        OnboardingDraft(currentStep: OnboardingStep.plan, updatedAt: now),
      ),
      Routes.onboardingPlan,
    );
    expect(
      OnboardingFlow.resumeRoute(
        OnboardingDraft(currentStep: OnboardingStep.weight, updatedAt: now),
      ),
      Routes.onboardingWeight,
    );
  });

  test('onboarding routes and the last step are recognised', () {
    expect(OnboardingFlow.isOnboardingRoute(Routes.welcome), isTrue);
    expect(OnboardingFlow.isOnboardingRoute(Routes.onboardingGoals), isTrue);
    expect(OnboardingFlow.isOnboardingRoute(Routes.today), isFalse);
    expect(OnboardingFlow.isLastStep(Routes.onboardingPlan), isTrue);
    expect(OnboardingFlow.isLastStep(Routes.onboardingNotifications), isFalse);
  });
}
