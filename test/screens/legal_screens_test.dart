import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/screens/me/legal_document_screen.dart';
import 'package:mova/screens/me/licenses_screen.dart';
import 'package:mova/theme/app_theme.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.dark, home: child);
}

void main() {
  testWidgets('privacy document renders bundled content', (tester) async {
    await tester.pumpWidget(
      _wrap(const LegalDocumentScreen(documentId: 'privacy')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mova privacy policy'), findsOneWidget);
    expect(find.textContaining('local-first'), findsWidgets);
  });

  testWidgets('terms document renders bundled content', (tester) async {
    await tester.pumpWidget(
      _wrap(const LegalDocumentScreen(documentId: 'terms')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mova terms of use'), findsOneWidget);
    expect(find.textContaining('Not medical advice'), findsOneWidget);
  });

  testWidgets('help document renders bundled content', (tester) async {
    await tester.pumpWidget(
      _wrap(const LegalDocumentScreen(documentId: 'help')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Help and support'), findsWidgets);
    expect(
      find.textContaining('Mova is designed to work without an account'),
      findsOneWidget,
    );
  });

  testWidgets('unknown legal document shows the offline fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const LegalDocumentScreen(documentId: 'missing')),
    );
    await tester.pumpAndSettle();

    expect(find.text('This document could not be loaded.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('licenses screen lists bundled packages', (tester) async {
    final controller = StreamController<LicenseEntry>();
    await tester.pumpWidget(_wrap(LicensesScreen(licenses: controller.stream)));
    controller.add(
      LicenseEntryWithLineBreaks(<String>[
        'sample_package',
      ], 'Sample license text.'),
    );
    await controller.close();
    await tester.pumpAndSettle();

    expect(find.text('Open-source licenses'), findsOneWidget);
    expect(find.text('sample_package'), findsOneWidget);

    await tester.tap(find.text('sample_package'));
    await tester.pumpAndSettle();
    expect(find.text('Sample license text.'), findsOneWidget);
  });

  testWidgets('licenses screen shows an empty state without packages', (
    tester,
  ) async {
    final controller = StreamController<LicenseEntry>();
    await tester.pumpWidget(_wrap(LicensesScreen(licenses: controller.stream)));
    await controller.close();
    await tester.pumpAndSettle();

    expect(find.text('Open-source licenses'), findsOneWidget);
    expect(find.text('No licenses found'), findsOneWidget);
  });
}
