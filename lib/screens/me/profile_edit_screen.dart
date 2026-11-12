import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../common/experience_display.dart';
import '../../common/goal_display.dart';
import '../../models/experience_level.dart';
import '../../models/gender.dart';
import '../../models/goal.dart';
import '../../models/unit_preferences.dart';
import '../../providers/profile_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weight_provider.dart';
import '../../services/clock.dart';
import '../../services/unit_conversion_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_choice_card.dart';
import '../../widgets/app_multi_select.dart';
import '../../widgets/birth_date_sheet.dart';
import '../../widgets/numeric_input_sheet.dart';
import '../../widgets/settings_row.dart';

/// Full-screen profile editing for the local guest profile.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, this.clock});

  final Clock? clock;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const UnitConversionService _units = UnitConversionService();

  static const List<({ExperienceLevel level, String description})>
  _experienceOptions = <({ExperienceLevel level, String description})>[
    (
      level: ExperienceLevel.beginner,
      description: 'New to training or returning after a break.',
    ),
    (
      level: ExperienceLevel.regular,
      description: 'Training consistently for under a year.',
    ),
    (
      level: ExperienceLevel.gymRat,
      description: 'Years of structured training.',
    ),
    (
      level: ExperienceLevel.veteran,
      description: 'Advanced, competition-minded.',
    ),
  ];

  static final List<AppMultiSelectOption<Goal>> _goalOptions =
      <AppMultiSelectOption<Goal>>[
        for (final goal in Goal.values)
          AppMultiSelectOption<Goal>(
            value: goal,
            label: goalLabel(goal),
            description: goalDescription(goal),
            assetIcon: goalIcon(goal),
          ),
      ];

  late final TextEditingController _nameController;
  ExperienceLevel? _experience;
  late List<Goal> _goals;
  Gender? _gender;
  DateTime? _birthDate;
  late double _heightCm;
  late double _bodyWeightKg;
  bool _isSaving = false;
  String? _error;

  Clock get _clock => widget.clock ?? const SystemClock();

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _experience = profile?.experienceLevel;
    _goals = List<Goal>.of(profile?.goals ?? const <Goal>[]);
    _gender = profile?.gender;
    _birthDate = profile?.birthDate;
    _heightCm = profile?.heightCm ?? 0;
    _bodyWeightKg = profile?.bodyWeightKg ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _experienceLabel(ExperienceLevel level) {
    return experienceLevelLabel(level);
  }

  String _genderLabel(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  String _dateLabel() {
    final date = _birthDate;
    if (date == null) {
      return 'Not set';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _heightLabel() {
    if (_heightCm <= 0) {
      return 'Not set';
    }
    final unit = context
        .read<SettingsProvider>()
        .settings
        .unitPreferences
        .heightUnit;
    return _units.displayHeight(_heightCm, unit);
  }

  String _weightLabel() {
    if (_bodyWeightKg <= 0) {
      return 'Not set';
    }
    final unit = context
        .read<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    return _units.displayWeight(_bodyWeightKg, unit);
  }

  Future<void> _pickBirthDate() async {
    final picked = await BirthDateSheet.show(
      context,
      initialDate: _birthDate,
      clock: widget.clock,
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _pickHeight() async {
    final unit = context
        .read<SettingsProvider>()
        .settings
        .unitPreferences
        .heightUnit;
    final initial = _heightCm <= 0
        ? (unit == HeightUnit.cm ? 170.0 : _units.cmToIn(170))
        : unit == HeightUnit.cm
        ? _heightCm
        : _units.cmToIn(_heightCm);
    final min = unit == HeightUnit.cm
        ? kMinHeightCm
        : _units.cmToIn(kMinHeightCm);
    final max = unit == HeightUnit.cm
        ? kMaxHeightCm
        : _units.cmToIn(kMaxHeightCm);
    final value = await showNumericInputSheet(
      context,
      title: 'Height',
      label: 'Height (${_units.heightLabel(unit)})',
      initialValue: initial,
      allowDecimal: unit == HeightUnit.inches,
      min: min,
      max: max,
      helperText: 'Stored as centimeters on this device.',
    );
    if (value == null || !mounted) {
      return;
    }
    final cm = unit == HeightUnit.cm ? value : _units.inToCm(value);
    setState(() => _heightCm = _units.roundInputCm(cm));
  }

  Future<void> _pickWeight() async {
    final unit = context
        .read<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    final initial = _bodyWeightKg <= 0
        ? (unit == WeightUnit.kg ? 75.0 : _units.kgToLb(75))
        : unit == WeightUnit.kg
        ? _bodyWeightKg
        : _units.kgToLb(_bodyWeightKg);
    final min = unit == WeightUnit.kg
        ? kMinWeightKg
        : _units.kgToLb(kMinWeightKg);
    final max = unit == WeightUnit.kg
        ? kMaxWeightKg
        : _units.kgToLb(kMaxWeightKg);
    final value = await showNumericInputSheet(
      context,
      title: 'Body weight',
      label: 'Body weight (${_units.weightLabel(unit)})',
      initialValue: initial,
      allowDecimal: true,
      min: min,
      max: max,
      helperText: 'Stored as kilograms on this device.',
    );
    if (value == null || !mounted) {
      return;
    }
    final kg = unit == WeightUnit.kg ? value : _units.lbToKg(value);
    setState(() => _bodyWeightKg = _units.roundInputKg(kg));
  }

  String? _validate() {
    if (_experience == null) {
      return 'Choose your training experience.';
    }
    if (_goals.isEmpty) {
      return 'Pick at least one goal.';
    }
    if (_gender == null) {
      return 'Choose how you identify.';
    }
    if (_birthDate == null) {
      return 'Choose your date of birth.';
    }
    if (_heightCm < kMinHeightCm || _heightCm > kMaxHeightCm) {
      return 'Set a height from $kMinHeightCm to $kMaxHeightCm cm.';
    }
    if (_bodyWeightKg < kMinWeightKg || _bodyWeightKg > kMaxWeightKg) {
      return 'Set a body weight from $kMinWeightKg to $kMaxWeightKg kg.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    final current = context.read<ProfileProvider>().profile;
    if (current == null) {
      setState(() => _error = 'No profile to update.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final profile = context.read<ProfileProvider>();
    final progress = context.read<ProgressProvider>();
    final weights = context.read<WeightProvider>();
    final weightChanged = (_bodyWeightKg - current.bodyWeightKg).abs() > 0.001;
    final saved = await profile.saveProfile(
      current.copyWith(
        displayName: _nameController.text.trim(),
        experienceLevel: _experience,
        goals: _goals,
        gender: _gender,
        birthDate: _birthDate,
        heightCm: _heightCm,
        bodyWeightKg: _bodyWeightKg,
        updatedAt: _clock.now(),
      ),
    );
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() {
        _isSaving = false;
        _error = profile.error ?? 'Could not save profile.';
      });
      return;
    }
    if (weightChanged) {
      await weights.logWeight(_bodyWeightKg);
    }
    await progress.recompute();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
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

  Widget _buildNameField() {
    return TextField(
      key: const Key('profile-name-field'),
      controller: _nameController,
      enabled: !_isSaving,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      maxLength: 40,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
      ],
      style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
      decoration: const InputDecoration(
        labelText: 'Name',
        hintText: 'Optional',
        counterText: '',
      ),
    );
  }

  Widget _buildExperienceOptions() {
    return Column(
      children: <Widget>[
        for (final option in _experienceOptions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppChoiceCard(
              label: _experienceLabel(option.level),
              description: option.description,
              assetIcon: experienceLevelIcon(option.level),
              selected: _experience == option.level,
              onTap: _isSaving
                  ? null
                  : () => setState(() => _experience = option.level),
            ),
          ),
      ],
    );
  }

  Widget _buildGenderOptions() {
    return Column(
      children: <Widget>[
        for (final gender in Gender.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppChoiceCard(
              label: _genderLabel(gender),
              description: switch (gender) {
                Gender.male => 'Use male reference values.',
                Gender.female => 'Use female reference values.',
                Gender.other => 'Skip the reference adjustment.',
              },
              assetIcon: switch (gender) {
                Gender.male => AppIcons.male,
                Gender.female => AppIcons.female,
                Gender.other => AppIcons.other,
              },
              selected: _gender == gender,
              onTap: _isSaving ? null : () => setState(() => _gender = gender),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: <Widget>[
          SettingsRow(
            key: const Key('profile-birth-row'),
            assetIcon: AppIcons.cake,
            label: 'Date of birth',
            value: _dateLabel(),
            onTap: _isSaving ? null : _pickBirthDate,
          ),
          const Divider(
            color: AppColors.line,
            height: 1,
            indent: 44,
            endIndent: AppSpacing.md,
          ),
          SettingsRow(
            key: const Key('profile-height-row'),
            assetIcon: AppIcons.ruler,
            label: 'Height',
            value: _heightLabel(),
            onTap: _isSaving ? null : _pickHeight,
          ),
          const Divider(
            color: AppColors.line,
            height: 1,
            indent: 44,
            endIndent: AppSpacing.md,
          ),
          SettingsRow(
            key: const Key('profile-weight-row'),
            assetIcon: AppIcons.scale,
            label: 'Body weight',
            value: _weightLabel(),
            onTap: _isSaving ? null : _pickWeight,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Edit profile',
                      style: AppTypography.h1.copyWith(color: AppColors.text),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Only saved on this device. Changes apply everywhere.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3l),
                    _buildSection(
                      title: 'Name',
                      subtitle: 'Leave blank to show your experience level.',
                      child: _buildNameField(),
                    ),
                    _buildSection(
                      title: 'Experience',
                      subtitle: 'Sets starting volume and exercise selection.',
                      child: _buildExperienceOptions(),
                    ),
                    _buildSection(
                      title: 'Goals',
                      subtitle: 'Pick all that apply. The first is your primary goal.',
                      child: AppMultiSelect<Goal>(
                        options: _goalOptions,
                        selected: _goals,
                        enabled: !_isSaving,
                        onChanged: (goals) => setState(() => _goals = goals),
                      ),
                    ),
                    _buildSection(
                      title: 'About you',
                      child: _buildGenderOptions(),
                    ),
                    _buildSection(
                      title: 'Body',
                      subtitle:
                          'Used for the strength score and reference values.',
                      child: _buildDetailsCard(),
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.orange,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.x2l),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2l,
                AppSpacing.md,
                AppSpacing.x2l,
                AppSpacing.x2l,
              ),
              child: AppButton(
                key: const Key('profile-save'),
                label: 'Save profile',
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
