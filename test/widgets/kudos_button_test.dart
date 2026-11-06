import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/kudos_button.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders the local count and an outline heart', (tester) async {
    await tester.pumpWidget(_wrap(const KudosButton(count: 12, given: false)));

    expect(find.text('12'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('a given kudos uses the filled heart', (tester) async {
    await tester.pumpWidget(_wrap(const KudosButton(count: 13, given: true)));

    expect(find.text('13'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
  });

  testWidgets('tapping reports the toggle', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(KudosButton(count: 1, given: false, onPressed: () => taps++)),
    );

    await tester.tap(find.byType(KudosButton));

    expect(taps, 1);
  });

  testWidgets('exposes a toggle label with the count', (tester) async {
    await tester.pumpWidget(
      _wrap(KudosButton(count: 7, given: false, onPressed: () {})),
    );

    expect(
      tester.getSemantics(find.byType(KudosButton)),
      matchesSemantics(
        isButton: true,
        hasToggledState: true,
        isToggled: false,
        label: 'Give kudos, 7',
        hasTapAction: true,
      ),
    );
  });
}
