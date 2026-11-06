import 'package:flutter_test/flutter_test.dart';
import 'package:mova/services/id_service.dart';

void main() {
  test('default IDs are UUID v4 strings and unique', () {
    final service = IdService();
    final first = service.next();
    final second = service.next();
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    expect(uuidV4.hasMatch(first), isTrue);
    expect(uuidV4.hasMatch(second), isTrue);
    expect(first, isNot(second));
  });

  test('injected generator produces a deterministic sequence', () {
    var counter = 0;
    final service = IdService(generator: () => 'id-${++counter}');

    expect(service.next(), 'id-1');
    expect(service.next(), 'id-2');
    expect(service.next(), 'id-3');
  });
}
