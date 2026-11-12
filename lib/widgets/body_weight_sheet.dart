import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../common/constants.dart';
import '../common/numeric_expression.dart';
import '../models/unit_preferences.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/weight_provider.dart';
import '../services/unit_conversion_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'calc_keypad.dart';

/// Bottom sheet that captures body weight for the strength score.
///
/// Returns true when the profile weight was saved and progress was refreshed.
class BodyWeightSheet extends StatefulWidget {
  const BodyWeightSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.panel,
      builder: (_) => const BodyWeightSheet(),
    );
  }

  @override
  State<BodyWeightSheet> createState() => _BodyWeightSheetState();
}

class _BodyWeightSheetState extends State<BodyWeightSheet> {
  static const UnitConversionService _units = UnitConversionService();

  late final TextEditingController _controller = TextEditingController(
    text: _initialText(),
  );
  bool _isSaving = false;
  String? _error;

  WeightUnit get _unit {
    return context.read<SettingsProvider>().settings.unitPreferences.weightUnit;
  }

  double get _displayValue {
    final kg = context.read<ProfileProvider>().profile?.bodyWeightKg ?? 0;
    return _unit == WeightUnit.kg ? kg : _units.kgToLb(kg);
  }

  String _initialText() {
    final value = _displayValue;
    if (value <= 0) {
      return '';
    }
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  String _formatLimit(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

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
      setState(() => _error = 'Enter a valid number.');
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

  double? _previewValue() {
    final text = _controller.text.trim();
    for (var index = 1; index < text.length; index += 1) {
      if (_operatorPattern.hasMatch(text[index])) {
        return evaluateNumericExpression(text);
      }
    }
    return null;
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
    if (parsed == null) {
      setState(() => _error = 'Enter your body weight.');
      return;
    }
    final kg = _unit == WeightUnit.kg ? parsed : _units.lbToKg(parsed);
    final rounded = _units.roundInputKg(kg);
    if (rounded < kMinWeightKg || rounded > kMaxWeightKg) {
      setState(() {
        _error =
            'Enter a weight from ${_formatLimit(_minDisplay)} to '
            '${_formatLimit(_maxDisplay)} ${_units.weightLabel(_unit)}.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    final profile = context.read<ProfileProvider>();
    final weights = context.read<WeightProvider>();
    final progress = context.read<ProgressProvider>();
    final logged = await weights.logWeight(rounded);
    if (!mounted) {
      return;
    }
    if (!logged) {
      setState(() {
        _isSaving = false;
        _error = weights.error ?? 'Could not save your weight.';
      });
      return;
    }
    final saved = await profile.updateBodyWeight(rounded);
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() {
        _isSaving = false;
        _error = profile.error ?? 'Could not save body weight.';
      });
      return;
    }
    await progress.recompute();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  double get _minDisplay =>
      _unit == WeightUnit.kg ? kMinWeightKg : _units.kgToLb(kMinWeightKg);

  double get _maxDisplay =>
      _unit == WeightUnit.kg ? kMaxWeightKg : _units.kgToLb(kMaxWeightKg);

  @override
  Widget build(BuildContext context) {
    final unitLabel = _units.weightLabel(_unit);
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
              'Body weight',
              style: AppTypography.h2.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The strength score compares your lifts with your body weight. '
              'Only saved on this device.',
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.x2l),
            TextField(
              key: const Key('body-weight-field'),
              controller: _controller,
              enabled: !_isSaving,
              keyboardType: TextInputType.none,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.+\-*/×÷]')),
              ],
              onChanged: _onChanged,
              textAlign: TextAlign.right,
              style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
              decoration: InputDecoration(
                labelText: 'Body weight',
                suffixText: unitLabel,
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
                  '= ${_formatNumber(preview)} $unitLabel',
                  key: const Key('body-weight-calc-result'),
                  style: AppTypography.caption.copyWith(color: AppColors.lime),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            CalcKeypad(allowDecimal: true, onKey: _handleKey),
            const SizedBox(height: AppSpacing.x2l),
            AppButton(
              key: const Key('body-weight-save'),
              label: 'Save body weight',
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
