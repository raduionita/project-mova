import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/result.dart';

void main() {
  test('ok result carries a value', () {
    const result = Result<int>.ok(7);

    expect(result.isOk, isTrue);
    expect(result.isFailure, isFalse);
    expect(result.value, 7);
    expect(result.message, isNull);
  });

  test('failure result carries a message', () {
    const result = Result<int>.failure('Missing profile');

    expect(result.isOk, isFalse);
    expect(result.isFailure, isTrue);
    expect(result.value, isNull);
    expect(result.message, 'Missing profile');
  });

  test('void results can report success without a value', () {
    const result = Result<void>.ok(null);

    expect(result.isOk, isTrue);
    expect(result.isFailure, isFalse);
  });
}
