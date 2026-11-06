import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/screens/onboarding/onboarding_scaffold.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_button.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.dark, home: child);
}

void main() {
  testWidgets('renders the step chrome, title, and subtitle', (tester) async {
    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          title: 'How do you train?',
          subtitle: 'Pick a unit for weight.',
          currentStep: 2,
          onBack: () {},
          onContinue: () {},
          child: const Text('Body content'),
        ),
      ),
    );

    expect(find.text('How do you train?'), findsOneWidget);
    expect(find.text('Pick a unit for weight.'), findsOneWidget);
    expect(find.text('Body content'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('step-segment-1')),
      findsOneWidget,
    );
  });

  testWidgets('back and continue invoke their callbacks', (tester) async {
    var back = 0;
    var next = 0;
    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          title: 'Step',
          currentStep: 1,
          onBack: () => back++,
          onContinue: () => next++,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.tap(find.text('Continue'));

    expect(back, 1);
    expect(next, 1);
  });

  testWidgets('validation disables continue', (tester) async {
    var next = 0;
    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          title: 'Step',
          currentStep: 1,
          onBack: () {},
          onContinue: () => next++,
          continueEnabled: false,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    expect(next, 0);
  });

  testWidgets('skip renders as a ghost action when provided', (tester) async {
    var skipped = 0;
    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          title: 'Weight',
          currentStep: 4,
          onBack: () {},
          onContinue: () {},
          onSkip: () => skipped++,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    expect(skipped, 1);
  });

  testWidgets('skip is hidden when not provided', (tester) async {
    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          title: 'Gender',
          currentStep: 2,
          onBack: () {},
          onContinue: () {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('busy state blocks continue and skip', (tester) async {
    var next = 0;
    var skipped = 0;
    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          title: 'Plan',
          currentStep: 10,
          onBack: () {},
          onContinue: () => next++,
          onSkip: () => skipped++,
          isBusy: true,
          continueLabel: 'Start using Mova',
          child: const SizedBox.shrink(),
        ),
      ),
    );

    final buttons = tester.widgetList<AppButton>(find.byType(AppButton));
    expect(buttons, isNotEmpty);
    expect(buttons.every((button) => button.onPressed == null), isTrue);

    await tester.tap(find.text('Skip'));
    expect(next, 0);
    expect(skipped, 0);
  });

  testWidgets('custom continue label is used', (tester) async {
    await tester.pumpWidget(
      _wrap(
        OnboardingScaffold(
          title: 'Plan',
          currentStep: 10,
          onBack: () {},
          onContinue: () {},
          continueLabel: 'Start using Mova',
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Start using Mova'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });
}
