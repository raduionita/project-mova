import 'package:flutter_test/flutter_test.dart';
import 'package:mova/app.dart';
import 'package:mova/services/storage_service.dart';

void main() {
  testWidgets('app starts on welcome for a fresh install', (tester) async {
    await tester.pumpWidget(MovaApp(storage: StorageService.inMemory()));
    await tester.pumpAndSettle();

    expect(find.text('Train with a plan'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Flutter Demo'), findsNothing);
  });
}
