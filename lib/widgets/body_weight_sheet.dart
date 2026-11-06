import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../common/constants.dart';
import '../models/unit_preferences.dart';
import '../providers/profile_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../services/unit_conversion_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final parsed = double.tryParse(_controller.text.trim());
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
    final progress = context.read<ProgressProvider>();
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
              autofocus: true,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
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
            const SizedBox(height: AppSpacing.x3l),
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
