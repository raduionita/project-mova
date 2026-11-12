import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../common/formatters.dart';
import '../common/numeric_expression.dart';
import '../models/step_entry.dart';
import '../providers/steps_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'calc_keypad.dart';

/// Bottom sheet for the manual steps fallback.
///
/// Returns true when the count was saved through [StepsProvider].
class ManualStepsSheet extends StatefulWidget {
  const ManualStepsSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.panel,
      builder: (_) => const ManualStepsSheet(),
    );
  }

  @override
  State<ManualStepsSheet> createState() => _ManualStepsSheetState();
}

class _ManualStepsSheetState extends State<ManualStepsSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: context.read<StepsProvider>().todaySteps == 0
        ? ''
        : '${context.read<StepsProvider>().todaySteps}',
  );
  bool _isSaving = false;
  String? _error;

  static final RegExp _operatorPattern = RegExp(r'[+\-*/×÷]');

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
    _setExpression('$left$token$right');
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
    if (start > end) {
      final swap = start;
      start = end;
      end = swap;
    }
    if (start == end) {
      if (start == 0) {
        return;
      }
      start -= 1;
    }
    _setExpression(text.substring(0, start) + text.substring(end));
  }

  void _applyEquals() {
    final value = evaluateNumericExpression(_controller.text.trim());
    if (value == null) {
      setState(() => _error = 'Enter a step count from 0 to 200,000.');
      return;
    }
    final steps = value.round();
    if (steps < 0 || steps > 200000) {
      setState(() => _error = 'Enter a step count from 0 to 200,000.');
      return;
    }
    _setExpression('$steps');
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

  double? _previewValue() {
    final text = _controller.text.trim();
    for (var index = 1; index < text.length; index += 1) {
      if (_operatorPattern.hasMatch(text[index])) {
        return evaluateNumericExpression(text);
      }
    }
    return null;
  }

  bool _isOperator(String token) {
    return token == '+' || token == '-' || token == '×' || token == '÷';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = evaluateNumericExpression(_controller.text.trim());
    final steps = parsed?.round();
    if (steps == null || steps < 0 || steps > 200000) {
      setState(() => _error = 'Enter a step count from 0 to 200,000.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final provider = context.read<StepsProvider>();
    final saved = await provider.saveManualSteps(steps);
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() {
        _isSaving = false;
        _error = provider.error ?? 'Could not save steps.';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final entry = context.watch<StepsProvider>().todayEntry;
    final preview = _previewValue();
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
              'Add steps',
              style: AppTypography.h2.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Health access is optional. Enter today\'s count and it is '
              'labeled Manual on this device.',
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
            if (entry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Saved today: ${formatSteps(entry.steps)} · '
                '${entry.source == StepSource.health ? 'Health' : 'Manual'}',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: AppSpacing.x2l),
            TextField(
              key: const Key('manual-steps-field'),
              controller: _controller,
              enabled: !_isSaving,
              keyboardType: TextInputType.none,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.+\-*/×÷]')),
              ],
              onChanged: _onChanged,
              textAlign: TextAlign.right,
              style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
              decoration: const InputDecoration(
                labelText: 'Steps today',
                suffixText: 'steps',
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.caption.copyWith(color: AppColors.orange),
              ),
            ],
            if (preview != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '= ${formatSteps(preview.round())} steps',
                  key: const Key('manual-steps-calc-result'),
                  style: AppTypography.caption.copyWith(color: AppColors.lime),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            CalcKeypad(onKey: _handleKey),
            const SizedBox(height: AppSpacing.x2l),
            AppButton(
              key: const Key('manual-steps-save'),
              label: 'Save steps',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              onPressed: _isSaving
                  ? null
                  : () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
