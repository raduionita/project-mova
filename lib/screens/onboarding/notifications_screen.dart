import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/onboarding_draft.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 9: workout reminders. Denied, unavailable, and Not now
/// paths all continue with reminders off.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.onRoute,
    this.notificationService = const NotificationService(),
  });

  /// Optional routing hook for tests. When null, named routes are pushed on
  /// the ambient navigator.
  final ValueChanged<String>? onRoute;

  final NotificationService notificationService;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isBusy = false;

  void _open(BuildContext context, String route) {
    final handler = widget.onRoute;
    if (handler != null) {
      handler(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  List<int> _reminderDays(OnboardingProvider onboarding) {
    final days = onboarding.draft.trainingDays;
    return days.isEmpty ? const <int>[1, 3, 5] : days;
  }

  Future<void> _finish({required bool enable}) async {
    if (_isBusy) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();
    final settings = context.read<SettingsProvider>();
    final editingPlan = onboarding.draft.currentStep == OnboardingStep.plan;

    var granted = false;
    if (enable) {
      final available = await widget.notificationService.isAvailable();
      if (available) {
        granted = await widget.notificationService.requestPermission();
      }
    }

    await settings.setReminders(
      enabled: granted,
      weekdays: _reminderDays(onboarding),
      hour: 18,
      minute: 0,
    );
    await onboarding.markNotificationsAsked(true);
    final advanced = editingPlan ? false : await onboarding.next();
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(
      context,
      editingPlan
          ? Routes.onboardingPlan
          : advanced
          ? OnboardingFlow.nextRoute(Routes.onboardingNotifications)!
          : Routes.onboardingNotifications,
    );
  }

  void _back(BuildContext context) {
    _open(
      context,
      OnboardingFlow.previousRoute(Routes.onboardingNotifications)!,
    );
  }

  Widget _buildBell() {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.limeSoft,
          borderRadius: BorderRadius.circular(AppRadii.x3l + AppRadii.md),
        ),
        child: const Icon(
          Icons.notifications_active_outlined,
          size: 44,
          color: AppColors.lime,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: AppColors.text),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyStrong.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Stay on schedule',
      subtitle: 'A short reminder before your workout. One nudge, no spam.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingNotifications),
      onBack: () => _back(context),
      onContinue: () => _finish(enable: true),
      continueLabel: 'Enable reminders',
      isBusy: _isBusy,
      onSkip: () => _finish(enable: false),
      skipLabel: 'Not now',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildBell(),
          const SizedBox(height: AppSpacing.x3l),
          AppCard(
            child: Column(
              children: <Widget>[
                _buildInfoRow('Workout reminders', 'Off'),
                const Divider(color: AppColors.line, height: 1),
                _buildInfoRow('Reminder time', '18:00'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
