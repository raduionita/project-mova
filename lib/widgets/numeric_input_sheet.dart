import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/numeric_expression.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'calc_keypad.dart';

/// Shows a keyboard-safe bottom sheet for one numeric value.
Future<double?> showNumericInputSheet(
  BuildContext context, {
  required String title,
  required String label,
  required double initialValue,
  bool allowDecimal = false,
  double min = 0,
  double max = 100000,
  String? helperText,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.panel,
    builder: (_) => NumericInputSheet(
      title: title,
      label: label,
      initialValue: initialValue,
      allowDecimal: allowDecimal,
      min: min,
      max: max,
      helperText: helperText,
    ),
  );
}

/// Numeric entry sheet used by the logger and other editable metrics.
///
/// Uses an in-app calculator keypad so weights and reps can be adjusted
/// without the OS keyboard. Hardware keyboards still type into the field.
class NumericInputSheet extends StatefulWidget {
  const NumericInputSheet({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    this.allowDecimal = false,
    this.min = 0,
    this.max = 100000,
    this.helperText,
  });

  final String title;
  final String label;
  final double initialValue;
  final bool allowDecimal;
  final double min;
  final double max;
  final String? helperText;

  @override
  State<NumericInputSheet> createState() => _NumericInputSheetState();
}

class _NumericInputSheetState extends State<NumericInputSheet> {
  static final RegExp _operatorPattern = RegExp(r'[+\-*/×÷]');

  late final TextEditingController _controller = _createController();
  String? _error;

  TextEditingController _createController() {
    final text = _initialText();
    return TextEditingController(text: text)
      ..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  String _initialText() {
    final fixed = widget.initialValue.toStringAsFixed(
      widget.allowDecimal ? 1 : 0,
    );
    if (!widget.allowDecimal) {
      return fixed;
    }
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleKey(String token) {
    switch (token) {
      case CalcKeys.clear:
        _setExpression('');
        return;
      case CalcKeys.backspace:
        _backspace();
        return;
      case CalcKeys.equals:
        _applyEquals();
        return;
      default:
        _insert(token);
    }
  }

  void _insert(String token) {
    if (token == CalcKeys.decimal && !widget.allowDecimal) {
      return;
    }
    final value = _controller.value;
    final text = value.text;
    var start = value.selection.start;
    var end = value.selection.end;
    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }
    if (start > end) {
      final swap = start;
      start = end;
      end = swap;
    }

    final left = text.substring(0, start);
    final right = text.substring(end);

    if (_isOperator(token)) {
      var base = left.trimRight();
      while (base.isNotEmpty && _isOperator(base[base.length - 1])) {
        base = base.substring(0, base.length - 1);
      }
      if (base.isEmpty && token != '-') {
        return;
      }
      _setExpression('$base$token$right');
      return;
    }

    var insert = token;
    if (token == CalcKeys.decimal) {
      final segment = left.split(_operatorPattern).last;
      if (segment.contains('.')) {
        return;
      }
      if (segment.isEmpty) {
        insert = '0.';
      }
    }

    _setExpression('$left$insert$right');
  }

  void _backspace() {
    final value = _controller.value;
    final text = value.text;
    var start = value.selection.start;
    var end = value.selection.end;
    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }
    if (start != end) {
      _setExpression(text.replaceRange(start, end, ''));
      return;
    }
    if (start == 0) {
      return;
    }
    _setExpression(text.replaceRange(start - 1, start, ''));
  }

  void _applyEquals() {
    final value = _evaluate();
    if (value == null) {
      setState(() => _error = 'Enter a valid number.');
      return;
    }
    final error = _errorFor(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    _setExpression(_formatNumber(value));
  }

  void _setExpression(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _error = null);
  }

  void _onChanged(String value) {
    final normalized = value
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('−', '-');
    if (normalized != value) {
      _controller.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }
    setState(() => _error = null);
  }

  void _submit() {
    final value = _evaluate();
    if (value == null) {
      setState(() => _error = 'Enter a valid number.');
      return;
    }
    final error = _errorFor(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(value);
  }

  double? _evaluate() {
    return evaluateNumericExpression(_controller.text.trim());
  }

  String? _errorFor(double value) {
    if (!widget.allowDecimal && value != value.roundToDouble()) {
      return 'Enter a whole number.';
    }
    if (value < widget.min || value > widget.max) {
      return widget.min == 0 && widget.max >= 100000
          ? 'Enter a valid number.'
          : 'Enter a value from ${_formatLimit(widget.min)} to '
                '${_formatLimit(widget.max)}.';
    }
    return null;
  }

  double? _previewValue() {
    final text = _controller.text.trim();
    if (!_hasCalculation(text)) {
      return null;
    }
    return evaluateNumericExpression(text);
  }

  bool _hasCalculation(String text) {
    for (var index = 1; index < text.length; index += 1) {
      if (_operatorPattern.hasMatch(text[index])) {
        return true;
      }
    }
    return false;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  String _formatLimit(double value) {
    final fixed = value.toStringAsFixed(widget.allowDecimal ? 1 : 0);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  bool _isOperator(String token) {
    return token == '+' || token == '-' || token == '×' || token == '÷';
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewValue();
    final previewError = preview == null ? null : _errorFor(preview);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x3l,
          AppSpacing.x2l,
          AppSpacing.x3l,
          AppSpacing.x3l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: AppSpacing.x6l,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x2l),
            Text(
              widget.title,
              style: AppTypography.h2.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: AppSpacing.x2l),
            _buildField(),
            if (widget.helperText != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.helperText!,
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
            if (preview != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '= ${_formatNumber(preview)}',
                  key: const Key('numeric-calc-result'),
                  style: AppTypography.bodyStrong.copyWith(
                    color: previewError == null
                        ? AppColors.lime
                        : AppColors.orange,
                  ),
                ),
              ),
            ],
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.caption.copyWith(color: AppColors.orange),
              ),
            ],
            const SizedBox(height: AppSpacing.x2l),
            CalcKeypad(allowDecimal: widget.allowDecimal, onKey: _handleKey),
            const SizedBox(height: AppSpacing.xs),
            AppButton(label: 'Done', onPressed: _submit),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: _error == null ? AppColors.line : AppColors.orange,
          width: _error == null ? 1 : 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            widget.label,
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.none,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: _onChanged,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(
                widget.allowDecimal
                    ? RegExp(r'[0-9.+\-*/×÷]')
                    : RegExp(r'[0-9+\-*/×÷]'),
              ),
            ],
            textAlign: TextAlign.right,
            style: AppTypography.metric.copyWith(color: AppColors.text),
            cursorColor: AppColors.lime,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
