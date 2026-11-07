import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/equipment_group.dart';
import '../../models/unit_preferences.dart';
import '../../navigation/routes.dart';
import '../../providers/profile_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/social_provider.dart';
import '../../providers/steps_provider.dart';
import '../../services/health_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_segmented_control.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/day_selector.dart';
import '../../widgets/permissions_sheet.dart';
import '../../widgets/reset_local_data_dialog.dart';
import '../../widgets/settings_row.dart';

/// Settings route reached from Me and from the Today reminder bell.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.healthService});

  /// Injectable health service for widget tests.
  final HealthService? healthService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final HealthService _health = widget.healthService ?? HealthService();

  String _version = '1.0.0';
  bool _savingReminders = false;
  bool _savingHealth = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((info) {
          if (mounted) {
            setState(() => _version = info.version);
          }
        })
        .catchError((Object _) => null);
  }

  String _reminderTimeLabel(AppSettings settings) {
    final hour = settings.reminderHour.toString().padLeft(2, '0');
    final minute = settings.reminderMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _reminderSummary(AppSettings settings) {
    if (!settings.remindersEnabled) {
      return 'Off';
    }
    final days = settings.reminderWeekdays.length;
    return '${_reminderTimeLabel(settings)} · '
        '${days == 1 ? '1 day' : '$days days'}';
  }

  String _healthLabel(HealthProvider provider) {
    switch (provider) {
      case HealthProvider.none:
        return 'Not connected';
      case HealthProvider.appleHealth:
        return 'Apple Health';
      case HealthProvider.healthConnect:
        return 'Health Connect';
      case HealthProvider.unavailable:
        return 'Unavailable';
    }
  }

  bool _isHealthConnected(HealthProvider provider) {
    return provider == HealthProvider.appleHealth ||
        provider == HealthProvider.healthConnect;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveUnits(UnitPreferences preferences) async {
    final settings = context.read<SettingsProvider>();
    final saved = await settings.setUnitPreferences(preferences);
    if (!saved) {
      _showMessage(settings.error ?? 'Could not save units.');
    }
  }

  Future<void> _toggleReminders(bool enabled) async {
    if (_savingReminders) {
      return;
    }
    final settings = context.read<SettingsProvider>();
    final current = settings.settings;
    if (!enabled) {
      setState(() => _savingReminders = true);
      final saved = await settings.setReminders(
        enabled: false,
        weekdays: current.reminderWeekdays,
        hour: current.reminderHour,
        minute: current.reminderMinute,
      );
      if (!mounted) {
        return;
      }
      setState(() => _savingReminders = false);
      if (!saved) {
        _showMessage(settings.error ?? 'Could not save reminders.');
      }
      return;
    }

    setState(() => _savingReminders = true);
    final service = settings.notificationService;
    final available = await service.isAvailable();
    if (!mounted) {
      return;
    }
    if (!available) {
      setState(() => _savingReminders = false);
      await PermissionsSheet.show(
        context,
        kind: PermissionKind.notifications,
        unavailable: true,
      );
      return;
    }
    final granted = await service.requestPermission();
    if (!mounted) {
      return;
    }
    if (!granted) {
      setState(() => _savingReminders = false);
      await PermissionsSheet.show(
        context,
        kind: PermissionKind.notifications,
        permanentlyDenied: true,
      );
      return;
    }
    final saved = await settings.setReminders(
      enabled: true,
      weekdays: current.reminderWeekdays,
      hour: current.reminderHour,
      minute: current.reminderMinute,
    );
    if (!mounted) {
      return;
    }
    setState(() => _savingReminders = false);
    if (!saved) {
      _showMessage(settings.error ?? 'Could not save reminders.');
    }
  }

  Future<void> _setReminderDays(List<int> days) async {
    final settings = context.read<SettingsProvider>();
    final current = settings.settings;
    if (days.isEmpty) {
      _showMessage('Choose at least one reminder day.');
      return;
    }
    final saved = await settings.setReminders(
      enabled: current.remindersEnabled,
      weekdays: days,
      hour: current.reminderHour,
      minute: current.reminderMinute,
    );
    if (!saved) {
      _showMessage(settings.error ?? 'Could not save reminder days.');
    }
  }

  Future<void> _pickReminderTime() async {
    final settings = context.read<SettingsProvider>();
    final current = settings.settings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.reminderHour,
        minute: current.reminderMinute,
      ),
      helpText: 'Reminder time',
    );
    if (picked == null || !mounted) {
      return;
    }
    final saved = await settings.setReminders(
      enabled: current.remindersEnabled,
      weekdays: current.reminderWeekdays,
      hour: picked.hour,
      minute: picked.minute,
    );
    if (!saved) {
      _showMessage(settings.error ?? 'Could not save reminder time.');
    }
  }

  Future<void> _toggleHealth() async {
    if (_savingHealth) {
      return;
    }
    final settings = context.read<SettingsProvider>();
    final current = settings.settings.healthProvider;
    if (_isHealthConnected(current)) {
      final saved = await settings.setHealthProvider(HealthProvider.none);
      if (saved) {
        _showMessage('Health disconnected. Steps stay on this device.');
      } else {
        _showMessage(settings.error ?? 'Could not update health.');
      }
      return;
    }

    setState(() => _savingHealth = true);
    final available = await _health.isAvailable();
    if (!mounted) {
      return;
    }
    if (!available) {
      await settings.setHealthProvider(HealthProvider.unavailable);
      if (!mounted) {
        return;
      }
      setState(() => _savingHealth = false);
      await PermissionsSheet.show(
        context,
        kind: PermissionKind.health,
        unavailable: true,
      );
      return;
    }
    final granted = await _health.requestPermission();
    if (!mounted) {
      return;
    }
    if (!granted) {
      setState(() => _savingHealth = false);
      await PermissionsSheet.show(
        context,
        kind: PermissionKind.health,
        permanentlyDenied: true,
      );
      return;
    }
    final saved = await settings.setHealthProvider(_health.provider);
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() => _savingHealth = false);
      _showMessage(settings.error ?? 'Could not update health.');
      return;
    }
    await context.read<StepsProvider>().syncHealth(enabled: true);
    if (!mounted) {
      return;
    }
    setState(() => _savingHealth = false);
    _showMessage('Health connected. Today will show your steps.');
  }

  Future<void> _setPostWorkouts(bool enabled) async {
    final settings = context.read<SettingsProvider>();
    final saved = await settings.setPostWorkoutsToFeed(enabled);
    if (!saved) {
      _showMessage(settings.error ?? 'Could not save privacy settings.');
    }
  }

  Future<void> _hideSamples() async {
    final social = context.read<SocialProvider>();
    final settings = context.read<SettingsProvider>();
    social.setSamplesDismissed(true);
    final hidden = await social.dismissSamples();
    if (!hidden) {
      _showMessage(social.error ?? 'Could not hide sample posts.');
      return;
    }
    await settings.dismissSampleFeed();
    _showMessage('Sample posts hidden.');
  }

  Future<void> _openReset() async {
    final done = await ResetLocalDataDialog.show(context);
    if (done != true || !mounted) {
      return;
    }
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.welcome, (route) => false);
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: AppTypography.h2.copyWith(color: AppColors.text)),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        child,
        const SizedBox(height: AppSpacing.x3l),
      ],
    );
  }

  Widget _buildUnitsCard(AppSettings settings) {
    final units = settings.unitPreferences;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Weight',
            style: AppTypography.label.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSegmentedControl<WeightUnit>(
            key: const Key('settings-weight-units'),
            options: const <AppSegmentOption<WeightUnit>>[
              AppSegmentOption<WeightUnit>(
                value: WeightUnit.kg,
                label: 'Kilograms',
              ),
              AppSegmentOption<WeightUnit>(
                value: WeightUnit.lb,
                label: 'Pounds',
              ),
            ],
            selected: units.weightUnit,
            onChanged: (unit) => _saveUnits(units.copyWith(weightUnit: unit)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Distance',
            style: AppTypography.label.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSegmentedControl<DistanceUnit>(
            key: const Key('settings-distance-units'),
            options: const <AppSegmentOption<DistanceUnit>>[
              AppSegmentOption<DistanceUnit>(
                value: DistanceUnit.km,
                label: 'Kilometers',
              ),
              AppSegmentOption<DistanceUnit>(
                value: DistanceUnit.mi,
                label: 'Miles',
              ),
            ],
            selected: units.distanceUnit,
            onChanged: (unit) => _saveUnits(units.copyWith(distanceUnit: unit)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Body',
            style: AppTypography.label.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSegmentedControl<HeightUnit>(
            key: const Key('settings-height-units'),
            options: const <AppSegmentOption<HeightUnit>>[
              AppSegmentOption<HeightUnit>(
                value: HeightUnit.cm,
                label: 'Centimeters',
              ),
              AppSegmentOption<HeightUnit>(
                value: HeightUnit.inches,
                label: 'Inches',
              ),
            ],
            selected: units.heightUnit,
            onChanged: (unit) => _saveUnits(units.copyWith(heightUnit: unit)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Values are stored as kg, km, and cm on this device and converted '
            'for display.',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersCard(AppSettings settings) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: <Widget>[
          SettingsRow(
            key: const Key('settings-reminders-row'),
            icon: Icons.notifications_none,
            label: 'Workout reminders',
            value: _savingReminders ? 'Saving...' : _reminderSummary(settings),
            showChevron: false,
            onTap: _savingReminders
                ? null
                : () => _toggleReminders(!settings.remindersEnabled),
            trailing: Switch.adaptive(
              key: const Key('settings-reminders-switch'),
              value: settings.remindersEnabled,
              onChanged: _savingReminders ? null : _toggleReminders,
              activeTrackColor: AppColors.lime,
              activeThumbColor: AppColors.limeInk,
            ),
          ),
          if (settings.remindersEnabled) ...<Widget>[
            const Divider(
              color: AppColors.line,
              height: 1,
              indent: 44,
              endIndent: AppSpacing.md,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Reminder days',
                    style: AppTypography.label.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DaySelector(
                    key: const Key('settings-reminder-days'),
                    selectedDays: settings.reminderWeekdays,
                    onChanged: _setReminderDays,
                  ),
                ],
              ),
            ),
            SettingsRow(
              key: const Key('settings-reminder-time'),
              icon: Icons.schedule,
              label: 'Reminder time',
              value: _reminderTimeLabel(settings),
              onTap: _pickReminderTime,
            ),
          ],
          const Divider(
            color: AppColors.line,
            height: 1,
            indent: 44,
            endIndent: AppSpacing.md,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Reminders are scheduled locally. Delivery follows your device '
              'battery and notification settings.',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(AppSettings settings) {
    final connected = _isHealthConnected(settings.healthProvider);
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: <Widget>[
          SettingsRow(
            key: const Key('settings-health-row'),
            icon: Icons.monitor_heart_outlined,
            label: _healthLabel(settings.healthProvider),
            value: connected
                ? 'Reading steps on this device'
                : 'Connect to read today\'s steps',
            showChevron: false,
            onTap: _savingHealth ? null : _toggleHealth,
            trailing: _savingHealth
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AppTag(
                    label: connected ? 'Connected' : 'Connect',
                    variant: connected
                        ? AppTagVariant.lime
                        : AppTagVariant.neutral,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Text(
              'Health access is optional. Step data is read only with '
              'permission and never leaves this device. Manual entry stays '
              'available on Today.',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(AppSettings settings) {
    final social = context.watch<SocialProvider>();
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.lock_outline, size: 20, color: AppColors.lime),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Text(
                    'Mova has no account and no cloud sync. Your profile, '
                    'workouts, steps, and feed stay on this device.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: AppColors.line,
            height: 1,
            indent: 44,
            endIndent: AppSpacing.md,
          ),
          SettingsRow(
            key: const Key('settings-share-workouts'),
            icon: Icons.people_outline,
            label: 'Post workouts to feed',
            value: settings.postWorkoutsToFeed
                ? 'Own posts appear in Social'
                : 'Own posts stay hidden',
            showChevron: false,
            onTap: () => _setPostWorkouts(!settings.postWorkoutsToFeed),
            trailing: Switch.adaptive(
              value: settings.postWorkoutsToFeed,
              onChanged: _setPostWorkouts,
              activeTrackColor: AppColors.lime,
              activeThumbColor: AppColors.limeInk,
            ),
          ),
          if (social.hasSamples) ...<Widget>[
            const Divider(
              color: AppColors.line,
              height: 1,
              indent: 44,
              endIndent: AppSpacing.md,
            ),
            SettingsRow(
              key: const Key('settings-hide-samples'),
              icon: Icons.visibility_off_outlined,
              label: 'Hide sample posts',
              value: 'Remove the three labeled samples',
              onTap: _hideSamples,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegalCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: <Widget>[
          SettingsRow(
            key: const Key('settings-privacy'),
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy policy',
            onTap: () =>
                Navigator.of(context)
                    .pushNamed(Routes.legalDocument('privacy')),
          ),
          const Divider(
            color: AppColors.line,
            height: 1,
            indent: 44,
            endIndent: AppSpacing.md,
          ),
          SettingsRow(
            key: const Key('settings-terms'),
            icon: Icons.description_outlined,
            label: 'Terms of use',
            onTap: () =>
                Navigator.of(context).pushNamed(Routes.legalDocument('terms')),
          ),
          const Divider(
            color: AppColors.line,
            height: 1,
            indent: 44,
            endIndent: AppSpacing.md,
          ),
          SettingsRow(
            key: const Key('settings-licenses'),
            icon: Icons.code,
            label: 'Open-source licenses',
            onTap: () => Navigator.of(context).pushNamed(Routes.meLicenses),
          ),
          const Divider(
            color: AppColors.line,
            height: 1,
            indent: 44,
            endIndent: AppSpacing.md,
          ),
          SettingsRow(
            key: const Key('settings-help'),
            icon: Icons.help_outline,
            label: 'Help and support',
            onTap: () =>
                Navigator.of(context).pushNamed(Routes.legalDocument('help')),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SettingsRow(
        key: const Key('settings-reset'),
        icon: Icons.restart_alt,
        label: 'Reset local data',
        value: 'Delete everything and start fresh',
        isDestructive: true,
        onTap: _openReset,
      ),
    );
  }

  Widget _buildVersionRow() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SettingsRow(
        icon: Icons.info_outline,
        label: 'Mova version',
        value: _version,
        showChevron: false,
        onTap: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final profile = context.watch<ProfileProvider>().profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
              child: AppBackBar(
                label: 'Me',
                onBack: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x2l,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Settings',
                      style: AppTypography.h1.copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Units, equipment, reminders, health, privacy, and local '
                      'data.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3l),
                    _buildSection(
                      title: 'Equipment',
                      subtitle: 'Used for plans and exercise swaps.',
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: SettingsRow(
                          key: const Key('settings-equipment-row'),
                          icon: Icons.fitness_center,
                          label: 'Equipment',
                          value:
                              '${profile?.availableEquipment.length ?? EquipmentGroup.values.length} '
                              'selected',
                          onTap: () =>
                              Navigator.of(context)
                                  .pushNamed(Routes.meEquipment),
                        ),
                      ),
                    ),
                    _buildSection(
                      title: 'Units',
                      subtitle: 'Applies to every weight and body measurement.',
                      child: _buildUnitsCard(settings),
                    ),
                    _buildSection(
                      title: 'Reminders',
                      child: _buildRemindersCard(settings),
                    ),
                    _buildSection(
                      title: 'Integrations',
                      child: _buildHealthCard(settings),
                    ),
                    _buildSection(
                      title: 'Privacy and social',
                      child: _buildPrivacyCard(settings),
                    ),
                    _buildSection(title: 'Data', child: _buildDataCard()),
                    _buildSection(
                      title: 'Legal and support',
                      child: _buildLegalCard(),
                    ),
                    _buildVersionRow(),
                    const SizedBox(height: AppSpacing.x3l),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
