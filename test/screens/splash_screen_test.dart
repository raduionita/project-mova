import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/screens/shared/splash_screen.dart';
import 'package:mova/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.dark, home: child);
}

void main() {
  testWidgets('renders the mark, wordmark, tagline, and loading bar', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SplashScreen()));

    expect(find.text('mova'), findsOneWidget);
    expect(find.text('Move. Log. Progress.'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('splash-loading-bar')),
      findsOneWidget,
    );
  });

  testWidgets('exposes a startup label for accessibility', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const SplashScreen()));

    expect(find.bySemanticsLabel(RegExp('Mova is starting')), findsOneWidget);

    handle.dispose();
  });

  testWidgets('uses the dark background', (tester) async {
    await tester.pumpWidget(_wrap(const SplashScreen()));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF0B0F16));
  });
}
