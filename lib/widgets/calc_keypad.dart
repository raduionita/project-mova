import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_icon.dart';

/// Reserved values passed to [CalcKeypad.onKey] for non-character keys.
class CalcKeys {
  const CalcKeys._();

  static const String clear = 'clear';
  static const String backspace = 'backspace';
  static const String equals = 'equals';
  static const String decimal = '.';
  static const String doubleZero = '00';
}

/// In-app calculator keypad for numeric sheets.
///
/// Character keys pass their label through unchanged. Utility keys pass one of
/// the [CalcKeys] values instead.
class CalcKeypad extends StatelessWidget {
  const CalcKeypad({super.key, required this.onKey, this.allowDecimal = false});

  final ValueChanged<String> onKey;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _row(<Widget>[
          _key(CalcKeys.clear),
          _key(CalcKeys.backspace),
          _key('÷', operator: true),
          _key('×', operator: true),
        ]),
        _row(<Widget>[
          _key('7'),
          _key('8'),
          _key('9'),
          _key('-', operator: true),
        ]),
        _row(<Widget>[
          _key('4'),
          _key('5'),
          _key('6'),
          _key('+', operator: true),
        ]),
        _row(<Widget>[
          _key('1'),
          _key('2'),
          _key('3'),
          _key(CalcKeys.equals, equals: true),
        ]),
        _row(
          allowDecimal
              ? <Widget>[
                  _key('0', flex: 2),
                  _key(CalcKeys.decimal),
                  _key(CalcKeys.doubleZero),
                ]
              : <Widget>[_key('0', flex: 3), _key(CalcKeys.doubleZero)],
        ),
      ],
    );
  }

  Widget _row(List<Widget> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < keys.length; index += 1) ...<Widget>[
            if (index > 0) const SizedBox(width: AppSpacing.md),
            Expanded(flex: _flex(keys[index]), child: keys[index]),
          ],
        ],
      ),
    );
  }

  int _flex(Widget key) {
    if (key is _CalcKey) {
      return key.flex;
    }
    return 1;
  }

  Widget _key(
    String token, {
    bool operator = false,
    bool equals = false,
    int flex = 1,
  }) {
    return _CalcKey(
      token: token,
      operator: operator,
      equals: equals,
      flex: flex,
      onTap: () => onKey(token),
    );
  }
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({
    required this.token,
    required this.onTap,
    this.operator = false,
    this.equals = false,
    this.flex = 1,
  });

  final String token;
  final VoidCallback onTap;
  final bool operator;
  final bool equals;
  final int flex;

  @override
  Widget build(BuildContext context) {
    final background = equals
        ? AppColors.lime
        : operator
        ? AppColors.surfaceAlt
        : AppColors.card;
    final foreground = equals
        ? AppColors.limeInk
        : operator
        ? AppColors.lime
        : AppColors.text;
    final label = _semanticLabel(token);

    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          key: ValueKey<String>('calc-key-$token'),
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: equals ? AppColors.lime : AppColors.line,
                ),
              ),
              child: _content(foreground),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(Color foreground) {
    if (token == CalcKeys.backspace) {
      return AppIcon(asset: AppIcons.backspace, size: 20, color: foreground);
    }
    return Text(
      token == CalcKeys.clear
          ? 'C'
          : token == CalcKeys.equals
          ? '='
          : token,
      style: AppTypography.bodyStrong.copyWith(
        color: foreground,
        fontSize: token == '00' ? 14 : 18,
      ),
    );
  }

  String _semanticLabel(String token) {
    switch (token) {
      case CalcKeys.clear:
        return 'Clear';
      case CalcKeys.backspace:
        return 'Backspace';
      case CalcKeys.equals:
        return 'Equals';
      case CalcKeys.decimal:
        return 'Decimal point';
      case CalcKeys.doubleZero:
        return 'Double zero';
      case '+':
        return 'Add';
      case '-':
        return 'Subtract';
      case '×':
        return 'Multiply';
      case '÷':
        return 'Divide';
      default:
        return token;
    }
  }
}
