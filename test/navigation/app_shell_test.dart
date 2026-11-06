import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/navigation/app_navigation.dart';
import 'package:mova/navigation/app_shell.dart';
import 'package:mova/navigation/routes.dart';
import 'package:mova/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.dark, home: child);
}

void main() {
  testWidgets('shell shows the bar on the Today route', (tester) async {
    final taps = <AppTab>[];
    await tester.pumpWidget(
      _wrap(
        AppShell(
          currentRoute: Routes.today,
          onTabSelected: taps.add,
          child: const Center(child: Text('Today body')),
        ),
      ),
    );

    expect(find.text('Today body'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    await tester.tap(find.text('Today'));
    expect(taps, <AppTab>[AppTab.today]);
  });

  testWidgets('shell hides the bar on logger and summary routes', (
    tester,
  ) async {
    for (final route in <String>[Routes.logger, Routes.summary]) {
      await tester.pumpWidget(
        _wrap(
          AppShell(
            currentRoute: route,
            onTabSelected: (_) {},
            child: const Center(child: Text('Full screen')),
          ),
        ),
      );

      expect(find.text('Full screen'), findsOneWidget);
      expect(find.text('Today'), findsNothing, reason: route);
    }
  });

  testWidgets('shell hides the bar on onboarding routes', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppShell(
          currentRoute: Routes.welcome,
          onTabSelected: (_) {},
          child: const Center(child: Text('Welcome')),
        ),
      ),
    );

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('shell keeps a locked tab hidden', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppShell(
          currentRoute: Routes.train,
          onTabSelected: (_) {},
          phase: AppPhase.foundation,
          child: const Center(child: Text('Train placeholder')),
        ),
      ),
    );

    expect(find.text('Train placeholder'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(find.text('Train'), findsNothing);
  });
}
