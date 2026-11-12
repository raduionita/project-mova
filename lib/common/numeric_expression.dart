/// Evaluates a simple arithmetic expression typed into a numeric field.
///
/// Supports numbers with an optional decimal point, unary minus, and the
/// operators `+`, `-`, `*`, and `/`. The display may use `-` or the typographic
/// minus, `*` or `x`, and `/` or the division sign. Multiplication and division
/// run before addition and subtraction. Returns null for invalid input, a
/// trailing operator, or division by zero.
double? evaluateNumericExpression(String source) {
  final input = source
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll(' ', '')
      .trim();
  if (input.isEmpty) {
    return null;
  }

  final tokens = <Object>[];
  var index = 0;
  var expectNumber = true;
  while (index < input.length) {
    if (expectNumber) {
      final start = index;
      if (input[index] == '-') {
        index += 1;
      }
      var digits = 0;
      while (index < input.length && _isDigit(input[index])) {
        index += 1;
        digits += 1;
      }
      if (index < input.length && input[index] == '.') {
        index += 1;
        while (index < input.length && _isDigit(input[index])) {
          index += 1;
          digits += 1;
        }
      }
      if (digits == 0) {
        return null;
      }
      final value = double.tryParse(input.substring(start, index));
      if (value == null) {
        return null;
      }
      tokens.add(value);
      expectNumber = false;
    } else {
      final operator = input[index];
      if (operator != '+' &&
          operator != '-' &&
          operator != '*' &&
          operator != '/') {
        return null;
      }
      tokens.add(operator);
      index += 1;
      expectNumber = true;
    }
  }
  if (tokens.isEmpty || expectNumber) {
    return null;
  }

  final values = <double>[];
  final operators = <String>[];
  var current = tokens.first as double;
  for (var token = 1; token < tokens.length; token += 2) {
    final operator = tokens[token] as String;
    final next = tokens[token + 1] as double;
    if (operator == '*') {
      current *= next;
    } else if (operator == '/') {
      if (next == 0) {
        return null;
      }
      current /= next;
    } else {
      values.add(current);
      operators.add(operator);
      current = next;
    }
  }
  values.add(current);

  var result = values.first;
  for (var index = 0; index < operators.length; index += 1) {
    result = operators[index] == '+'
        ? result + values[index + 1]
        : result - values[index + 1];
  }
  return result.isFinite ? result : null;
}

bool _isDigit(String character) {
  final code = character.codeUnitAt(0);
  return code >= 48 && code <= 57;
}
