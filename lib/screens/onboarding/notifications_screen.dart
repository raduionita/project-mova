import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_onboarding_type.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_toggle.dart';
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
    final editingPlan = onboarding.editingPlan;

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
    final next = editingPlan
        ? Routes.onboardingPlan
        : OnboardingFlow.nextRoute(Routes.onboardingNotifications)!;
    if (editingPlan) {
      onboarding.endPlanEdit();
    }
    onboarding.syncStep(OnboardingFlow.stepFor(next));
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(context, next);
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
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: AppColors.lime.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.lime.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: AppIcon(asset: AppIcons.bell, size: 34, color: AppColors.lime),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget trailing) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: AppOnboardingType.choiceTitle.copyWith(
              color: AppColors.text,
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildNotifCard(Widget child) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg + AppSpacing.xxs,
        ),
        child: child,
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
          _buildNotifCard(
            _buildInfoRow(
              'Workout reminders',
              const AppToggle(value: true, semanticLabel: 'Workout reminders'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildNotifCard(
            _buildInfoRow(
              'Reminder time',
              Text(
                '18:00',
                style: AppOnboardingType.choiceDesc.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
