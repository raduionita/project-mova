import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/providers/steps_provider.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/manual_steps_sheet.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 6, 12);

Future<StepsProvider> _openSheet(
  WidgetTester tester, {
  int steps = 0,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final provider = StepsProvider(
    StorageService.inMemory(),
    clock: FakeClock(_now),
  );
  await provider.load();
  if (steps > 0) {
    await provider.saveManualSteps(steps);
  }

  await tester.pumpWidget(
    ChangeNotifierProvider<StepsProvider>.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => ManualStepsSheet.show(context),
                child: const Text('Open steps'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open steps'));
  await tester.pumpAndSettle();
  return provider;
}

Future<void> _tapKey(WidgetTester tester, String token) async {
  await tester.tap(find.byKey(ValueKey<String>('calc-key-$token')));
  await tester.pump();
}

void main() {
  testWidgets('evaluates an expression and saves the step count', (
    tester,
  ) async {
    final provider = await _openSheet(tester);

    for (final token in <String>['3', '0', '0', '0', '+', '5', '0', '0']) {
      await _tapKey(tester, token);
    }

    expect(find.byKey(const Key('manual-steps-calc-result')), findsOneWidget);
    expect(find.text('= 3,500 steps'), findsOneWidget);

    await tester.tap(find.byKey(const Key('manual-steps-save')));
    await tester.pumpAndSettle();

    expect(provider.todaySteps, 3500);
    expect(find.text('Add steps'), findsNothing);
  });

  testWidgets('shows the saved count when reopening the sheet', (
    tester,
  ) async {
    await _openSheet(tester, steps: 7200);

    expect(find.text('Saved today: 7,200 · Manual'), findsOneWidget);
    expect(find.text('7200'), findsOneWidget);
  });

  testWidgets('rejects an expression above the daily cap', (tester) async {
    final provider = await _openSheet(tester);

    await _tapKey(tester, 'clear');
    for (final token in <String>['2', '0', '0', '0', '0', '0', '+', '1']) {
      await _tapKey(tester, token);
    }
    await _tapKey(tester, 'equals');

    expect(
      find.text('Enter a step count from 0 to 200,000.'),
      findsOneWidget,
    );
    expect(provider.todayEntry, isNull);
  });
}
