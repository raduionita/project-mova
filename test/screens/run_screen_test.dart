import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/providers/settings_provider.dart';
import 'package:mova/providers/workout_provider.dart';
import 'package:mova/screens/run/run_screen.dart';
import 'package:mova/services/clock.dart';
import 'package:mova/services/storage_service.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:provider/provider.dart';

final DateTime _now = DateTime(2026, 11, 12, 8);
late FakeClock _clock;

Future<(WorkoutProvider, SettingsProvider)> _setup() async {
  final storage = StorageService.inMemory();
  final workout = WorkoutProvider(storage, clock: _clock);
  final settings = SettingsProvider(storage);
  await settings.load();
  return (workout, settings);
}

Widget _wrap(WorkoutProvider workout, SettingsProvider settings, Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WorkoutProvider>.value(value: workout),
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
    ],
    child: MaterialApp(theme: AppTheme.dark, home: home),
  );
}

void main() {
  setUp(() {
    _clock = FakeClock(_now);
  });

  testWidgets('starts, pauses, resumes, and keeps a timer', (tester) async {
    final (workout, settings) = await _setup();
    await tester.pumpWidget(
      _wrap(workout, settings, RunScreen(clock: _clock)),
    );

    expect(find.text('Ready for a run?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('run-start')));
    await tester.pumpAndSettle();

    expect(workout.activeSession?.source.name, 'run');
    expect(find.text('Running'), findsOneWidget);

    _clock.advance(const Duration(minutes: 1, seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:05'), findsOneWidget);

    await tester.tap(find.byKey(const Key('run-toggle-pause')));
    await tester.pumpAndSettle();
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume run'), findsOneWidget);

    await tester.tap(find.byKey(const Key('run-toggle-pause')));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Pause run'), findsOneWidget);
  });
}
