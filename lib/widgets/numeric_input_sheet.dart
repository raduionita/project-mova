import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

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

  void _submit() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < widget.min || value > widget.max) {
      setState(() {
        _error = widget.min == 0 && widget.max >= 100000
            ? 'Enter a valid number.'
            : 'Enter a value from ${_formatLimit(widget.min)} to '
                  '${_formatLimit(widget.max)}.';
      });
      return;
    }
    Navigator.of(context).pop(value);
  }

  String _formatLimit(double value) {
    final fixed = value.toStringAsFixed(widget.allowDecimal ? 1 : 0);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  @override
  Widget build(BuildContext context) {
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
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: widget.allowDecimal,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                  widget.allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
                ),
              ],
              textAlign: TextAlign.right,
              style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
              decoration: InputDecoration(
                labelText: widget.label,
                helperText: widget.helperText,
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.caption.copyWith(color: AppColors.orange),
              ),
            ],
            const SizedBox(height: AppSpacing.x3l),
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
}
