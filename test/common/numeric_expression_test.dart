import 'package:flutter_test/flutter_test.dart';
import 'package:mova/common/numeric_expression.dart';

void main() {
  group('evaluateNumericExpression', () {
    test('reads plain and decimal numbers', () {
      expect(evaluateNumericExpression('82'), 82);
      expect(evaluateNumericExpression('82.5'), 82.5);
      expect(evaluateNumericExpression('0.25'), 0.25);
      expect(evaluateNumericExpression('12.'), 12);
    });

    test(
      'runs multiplication and division before addition and subtraction',
      () {
        expect(evaluateNumericExpression('45+25*2'), 95);
        expect(evaluateNumericExpression('100/4-5'), 20);
        expect(evaluateNumericExpression('2+3*4-5'), 9);
        expect(evaluateNumericExpression('2*3+4*5'), 26);
      },
    );

    test('accepts calculator symbols and a leading minus', () {
      expect(evaluateNumericExpression('100÷4'), 25);
      expect(evaluateNumericExpression('12×3'), 36);
      expect(evaluateNumericExpression('−5+8'), 3);
      expect(evaluateNumericExpression(' 80 + 2.5 '), 82.5);
    });

    test('rejects incomplete or malformed expressions', () {
      expect(evaluateNumericExpression(''), isNull);
      expect(evaluateNumericExpression('5+'), isNull);
      expect(evaluateNumericExpression('+5'), isNull);
      expect(evaluateNumericExpression('5..2'), isNull);
      expect(evaluateNumericExpression('2+*3'), isNull);
      expect(evaluateNumericExpression('abc'), isNull);
    });

    test('rejects division by zero', () {
      expect(evaluateNumericExpression('10/0'), isNull);
      expect(evaluateNumericExpression('10÷0'), isNull);
    });
  });
}
