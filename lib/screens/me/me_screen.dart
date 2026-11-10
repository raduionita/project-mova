import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../common/display_name.dart';
import '../../common/experience_display.dart';
import '../../common/formatters.dart';
import '../../models/app_settings.dart';
import '../../models/experience_level.dart';
import '../../models/goal.dart';
import '../../navigation/routes.dart';
import '../../providers/profile_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/unit_conversion_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../widgets/app_icon.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/settings_row.dart';

/// Me tab: identity, lifetime totals, and the entry to settings.
class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  static const UnitConversionService _units = UnitConversionService();

  String _version = '1.0.0';

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

  String _experienceLabel(ExperienceLevel? level) {
    if (level == null) {
      return 'Add experience';
    }
    return experienceLevelLabel(level);
  }

  String _goalLabel(Goal goal) {
    switch (goal) {
      case Goal.buildMuscle:
        return 'Build muscle';
      case Goal.getStronger:
        return 'Get stronger';
      case Goal.loseWeight:
        return 'Lose weight';
      case Goal.stayHealthy:
        return 'Stay healthy';
    }
  }

  String _reminderLabel(AppSettings settings) {
    if (!settings.remindersEnabled) {
      return 'Off';
    }
    final hour = settings.reminderHour.toString().padLeft(2, '0');
    final minute = settings.reminderMinute.toString().padLeft(2, '0');
    final count = settings.reminderWeekdays.length;
    return '$hour:$minute · ${count == 1 ? '1 day' : '$count days'}';
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

  void _push(String route) {
    Navigator.of(context).pushNamed(route);
  }

  Widget _buildAvatar(ExperienceLevel? level) {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
      ),
      child: AppIcon(
        key: const Key('me-avatar-icon'),
        asset: level == null ? AppIcons.navMe : experienceLevelIcon(level),
        size: 32,
        color: AppColors.limeInk,
      ),
    );
  }

  Widget _buildProfileCard() {
    final profile = context.watch<ProfileProvider>().profile;
    final name = profileDisplayName(profile);
    final experience = _experienceLabel(profile?.experienceLevel);
    final goals = profile?.goals ?? const <Goal>[];
    return AppCard(
      featured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _buildAvatar(profile?.experienceLevel),
              const SizedBox(width: AppSpacing.x2l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h1.copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: <Widget>[
                        AppTag(label: experience, variant: AppTagVariant.lime),
                        if (goals.isNotEmpty)
                          AppTag(
                            label: _goalLabel(goals.first),
                            variant: AppTagVariant.neutral,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (goals.length > 1) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Also training for ${goals.skip(1).map(_goalLabel).join(', ')}.',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.x2l),
          OutlinedButton.icon(
            key: const Key('me-edit-profile'),
            onPressed: () => _push(Routes.meEdit),
            icon: const AppIcon(
              asset: AppIcons.edit,
              size: 18,
              color: AppColors.lime,
            ),
            label: const Text('Edit profile'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.lime,
              side: BorderSide(color: AppColors.limeBorder45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final progress = context.watch<ProgressProvider>();
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    return Row(
      children: <Widget>[
        Expanded(
          child: AppStatTile(
            value: '${progress.totalWorkouts}',
            label: 'workouts',
            assetIcon: AppIcons.dumbbell,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: formatVolume(progress.totalVolumeKg, unit: unit),
            label: 'volume',
            assetIcon: AppIcons.scale,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: '${progress.streak}',
            label: 'day streak',
            assetIcon: AppIcons.flame,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList() {
    final settings = context.watch<SettingsProvider>().settings;
    final units = settings.unitPreferences;
    final rows = <Widget>[
      SettingsRow(
        key: const Key('me-edit-profile-row'),
        assetIcon: AppIcons.navMe,
        label: 'Edit profile',
        value: 'Name, body, goals',
        onTap: () => _push(Routes.meEdit),
      ),
      SettingsRow(
        key: const Key('me-units-row'),
        assetIcon: AppIcons.ruler,
        label: 'Units',
        value:
            '${_units.weightLabel(units.weightUnit)} · '
            '${_units.distanceLabel(units.distanceUnit)} · '
            '${_units.heightLabel(units.heightUnit)}',
        onTap: () => _push(Routes.meSettings),
      ),
      SettingsRow(
        key: const Key('me-reminders-row'),
        assetIcon: AppIcons.bell,
        label: 'Workout reminders',
        value: _reminderLabel(settings),
        onTap: () => _push(Routes.meSettings),
      ),
      SettingsRow(
        key: const Key('me-integrations-row'),
        assetIcon: AppIcons.link,
        label: 'Integrations',
        value: _healthLabel(settings.healthProvider),
        onTap: () => _push(Routes.meSettings),
      ),
      SettingsRow(
        key: const Key('me-privacy-row'),
        assetIcon: AppIcons.shield,
        label: 'Privacy and social',
        value: 'Your data stays on this device',
        onTap: () => _push(Routes.meSettings),
      ),
      SettingsRow(
        key: const Key('me-help-row'),
        assetIcon: AppIcons.help,
        label: 'Help and support',
        value: 'FAQ and contact',
        onTap: () => _push(Routes.legalDocument('help')),
      ),
      SettingsRow(
        key: const Key('me-reset-row'),
        assetIcon: AppIcons.refresh,
        label: 'Reset local data',
        value: 'Remove everything on this device',
        isDestructive: true,
        onTap: () => _push(Routes.meSettings),
      ),
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: <Widget>[
          for (var index = 0; index < rows.length; index++) ...<Widget>[
            rows[index],
            if (index != rows.length - 1)
              const Divider(
                color: AppColors.line,
                height: 1,
                indent: 44,
                endIndent: AppSpacing.md,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildVersionRow() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SettingsRow(
        assetIcon: AppIcons.info,
        label: 'Mova version',
        value: _version,
        onTap: null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2l,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Me',
                style: AppTypography.h1.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.x2l),
              _buildProfileCard(),
              const SizedBox(height: AppSpacing.x2l),
              _buildStats(),
              const SizedBox(height: AppSpacing.x3l),
              Text(
                'Settings',
                style: AppTypography.h2.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSettingsList(),
              const SizedBox(height: AppSpacing.x2l),
              _buildVersionRow(),
            ],
          ),
        ),
      ),
    );
  }
}
