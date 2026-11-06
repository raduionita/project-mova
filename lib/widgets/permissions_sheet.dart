import 'package:flutter/material.dart';

import '../services/app_settings_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// The permission being explained by [PermissionsSheet].
enum PermissionKind { notifications, health }

/// Guidance shown at the point of use after a permission is denied or the
/// integration is unavailable.
class PermissionsSheet extends StatelessWidget {
  const PermissionsSheet({
    super.key,
    required this.kind,
    this.unavailable = false,
    this.permanentlyDenied = false,
    this.launcher = const AppSettingsLauncher(),
  });

  final PermissionKind kind;
  final bool unavailable;
  final bool permanentlyDenied;
  final AppSettingsLauncher launcher;

  static Future<void> show(
    BuildContext context, {
    required PermissionKind kind,
    bool unavailable = false,
    bool permanentlyDenied = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.panel,
      builder: (_) => PermissionsSheet(
        kind: kind,
        unavailable: unavailable,
        permanentlyDenied: permanentlyDenied,
      ),
    );
  }

  String get _title {
    if (unavailable) {
      return kind == PermissionKind.notifications
          ? 'Reminders are not available'
          : 'Health access is not available';
    }
    return kind == PermissionKind.notifications
        ? 'Allow workout reminders'
        : 'Allow step access';
  }

  String get _message {
    if (unavailable) {
      return kind == PermissionKind.notifications
          ? 'This build cannot schedule local notifications. Your workouts and '
                'data still work normally.'
          : 'Health Connect or Apple Health is not available on this device. '
                'Add today\'s steps manually from Today.';
    }
    if (permanentlyDenied) {
      return kind == PermissionKind.notifications
          ? 'Notifications are blocked for Mova. Open system settings and '
                'allow notifications, then enable reminders again.'
          : 'Health access is blocked for Mova. Open system settings and allow '
                'step access, then connect health again.';
    }
    return kind == PermissionKind.notifications
        ? 'Mova needs notification permission to send local workout '
              'reminders. You can change this later in system settings.'
        : 'Mova reads today\'s step total only when you connect health. The '
              'data stays on this device and is never transmitted.';
  }

  IconData get _icon {
    if (unavailable) {
      return Icons.block_outlined;
    }
    return kind == PermissionKind.notifications
        ? Icons.notifications_off_outlined
        : Icons.monitor_heart_outlined;
  }

  Future<void> _openSettings(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launcher.open();
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Open your device settings to change this permission.'),
        ),
      );
    }
    navigator.pop();
  }

  Widget _buildIcon() {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.limeSoft,
          borderRadius: BorderRadius.circular(AppRadii.x3l),
        ),
        child: Icon(_icon, size: 34, color: AppColors.lime),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSettings = !unavailable && permanentlyDenied;
    return Padding(
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
          _buildIcon(),
          const SizedBox(height: AppSpacing.x2l),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.x3l),
          if (showSettings)
            AppButton(
              key: const Key('permissions-open-settings'),
              label: 'Open settings',
              icon: Icons.settings_outlined,
              onPressed: () => _openSettings(context),
            ),
          if (showSettings) const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Got it',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
