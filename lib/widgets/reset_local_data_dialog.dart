import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_coordinator.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import 'app_icon.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Confirmation dialog for clearing every local Mova key.
///
/// The dialog performs the reset itself and returns true when the local data
/// was cleared. The caller owns the navigation back to the welcome screen.
class ResetLocalDataDialog extends StatefulWidget {
  const ResetLocalDataDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ResetLocalDataDialog(),
    );
  }

  @override
  State<ResetLocalDataDialog> createState() => _ResetLocalDataDialogState();
}

class _ResetLocalDataDialogState extends State<ResetLocalDataDialog> {
  static const List<String> _losses = <String>[
    'Profile, goals, and body measurements',
    'Training plan and routines',
    'Workout history, personal records, and streak',
    'Daily steps and feed posts',
    'Units, reminders, and privacy settings',
  ];

  bool _isResetting = false;
  String? _error;

  Future<void> _reset() async {
    if (_isResetting) {
      return;
    }
    setState(() {
      _isResetting = true;
      _error = null;
    });
    final coordinator = context.read<AppCoordinator>();
    final messenger = ScaffoldMessenger.of(context);
    final done = await coordinator.resetLocalData();
    if (!mounted) {
      return;
    }
    if (!done) {
      setState(() {
        _isResetting = false;
        _error = 'Could not clear local data. Try again.';
      });
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Local data cleared. Starting fresh.')),
    );
    Navigator.of(context).pop(true);
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.orangeBorder50),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppIcon(
            asset: AppIcons.alert,
            size: 20,
            color: AppColors.orange,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'This cannot be undone. There is no account and no cloud copy.',
              style: AppTypography.caption.copyWith(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.x2l),
      ),
      title: Text(
        'Reset local data?',
        style: AppTypography.h2.copyWith(color: AppColors.text),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Everything Mova stores on this device will be removed.',
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final loss in _losses)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppIcon(
                      asset: AppIcons.minus,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        loss,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            _buildWarning(),
            if (_error != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: AppTypography.caption.copyWith(color: AppColors.orange),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.x3l,
        0,
        AppSpacing.x3l,
        AppSpacing.x2l,
      ),
      actions: <Widget>[
        AppButton(
          key: const Key('reset-cancel'),
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          fullWidth: false,
          onPressed: _isResetting
              ? null
              : () => Navigator.of(context).pop(false),
        ),
        AppButton(
          key: const Key('reset-confirm'),
          label: 'Reset everything',
          variant: AppButtonVariant.destructive,
          fullWidth: false,
          isLoading: _isResetting,
          onPressed: _isResetting ? null : _reset,
        ),
      ],
    );
  }
}
