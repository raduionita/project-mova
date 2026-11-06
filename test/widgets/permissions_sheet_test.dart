import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/permissions_sheet.dart';

Widget _host(PermissionsSheet sheet) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Builder(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => sheet,
                );
              },
              child: const Text('Open sheet'),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> _open(WidgetTester tester, PermissionsSheet sheet) async {
  await tester.pumpWidget(_host(sheet));
  await tester.tap(find.text('Open sheet'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('notification denial offers a settings shortcut', (tester) async {
    await _open(
      tester,
      const PermissionsSheet(
        kind: PermissionKind.notifications,
        permanentlyDenied: true,
      ),
    );

    expect(find.text('Allow workout reminders'), findsOneWidget);
    expect(find.byKey(const Key('permissions-open-settings')), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('health denial explains the blocked access', (tester) async {
    await _open(
      tester,
      const PermissionsSheet(
        kind: PermissionKind.health,
        permanentlyDenied: true,
      ),
    );

    expect(find.text('Allow step access'), findsOneWidget);
    expect(find.textContaining('blocked for Mova'), findsOneWidget);
  });

  testWidgets('unavailable notifications hide the settings shortcut', (
    tester,
  ) async {
    await _open(
      tester,
      const PermissionsSheet(
        kind: PermissionKind.notifications,
        unavailable: true,
      ),
    );

    expect(find.text('Reminders are not available'), findsOneWidget);
    expect(find.byKey(const Key('permissions-open-settings')), findsNothing);
  });

  testWidgets('unavailable health points at manual steps', (tester) async {
    await _open(
      tester,
      const PermissionsSheet(kind: PermissionKind.health, unavailable: true),
    );

    expect(find.text('Health access is not available'), findsOneWidget);
    expect(find.textContaining('manually from Today'), findsOneWidget);
  });
}
