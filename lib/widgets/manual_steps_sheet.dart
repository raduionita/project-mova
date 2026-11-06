import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../common/formatters.dart';
import '../models/step_entry.dart';
import '../providers/steps_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final steps = int.tryParse(_controller.text.trim());
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
              autofocus: true,
              enabled: !_isSaving,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
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
            const SizedBox(height: AppSpacing.x3l),
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
