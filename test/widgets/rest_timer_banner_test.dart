import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/widgets/rest_timer_banner.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('counts down from the end timestamp and skips', (tester) async {
    final clock = FakeClock(DateTime.utc(2026, 11, 6, 12));
    var skipped = false;
    await tester.pumpWidget(
      _wrap(
        RestTimerBanner(
          endsAt: clock.now().add(const Duration(seconds: 90)),
          totalSeconds: 90,
          onSkip: () => skipped = true,
          clock: clock,
        ),
      ),
    );

    expect(find.text('Rest · 1:30'), findsOneWidget);

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Rest · 1:00'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    expect(skipped, isTrue);
  });

  testWidgets('recomputes after background time and finishes once', (
    tester,
  ) async {
    final clock = FakeClock(DateTime.utc(2026, 11, 6, 12));
    var finished = 0;
    await tester.pumpWidget(
      _wrap(
        RestTimerBanner(
          endsAt: clock.now().add(const Duration(seconds: 120)),
          totalSeconds: 120,
          onSkip: () {},
          onFinished: () => finished++,
          clock: clock,
        ),
      ),
    );

    expect(find.text('Rest · 2:00'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 95));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('Rest · 0:25'), findsOneWidget);
    expect(finished, 0);

    clock.advance(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(finished, 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('restarts when the end timestamp changes', (tester) async {
    final clock = FakeClock(DateTime.utc(2026, 11, 6, 12));
    await tester.pumpWidget(
      _wrap(
        RestTimerBanner(
          endsAt: clock.now().add(const Duration(seconds: 60)),
          totalSeconds: 60,
          onSkip: () {},
          clock: clock,
        ),
      ),
    );
    expect(find.text('Rest · 1:00'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        RestTimerBanner(
          endsAt: clock.now().add(const Duration(seconds: 90)),
          totalSeconds: 90,
          onSkip: () {},
          clock: clock,
        ),
      ),
    );
    expect(find.text('Rest · 1:30'), findsOneWidget);
  });
}
