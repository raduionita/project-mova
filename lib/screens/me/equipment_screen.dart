import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_coordinator.dart';
import '../../models/equipment_group.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/equipment_multi_select.dart';

/// Settings route for changing available equipment.
class EquipmentSettingsScreen extends StatefulWidget {
  const EquipmentSettingsScreen({super.key});

  @override
  State<EquipmentSettingsScreen> createState() =>
      _EquipmentSettingsScreenState();
}

class _EquipmentSettingsScreenState extends State<EquipmentSettingsScreen> {
  late List<EquipmentGroup> _equipment;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _equipment = List<EquipmentGroup>.of(
      context.read<ProfileProvider>().profile?.availableEquipment ??
          EquipmentGroup.values,
    );
  }

  Future<void> _save() async {
    if (_isSaving || _equipment.isEmpty) {
      return;
    }
    final plan = context.read<PlanProvider>().plan;
    bool? regenerate;
    if (plan != null) {
      regenerate = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              'Update this week\'s plan?',
              style: AppTypography.h2.copyWith(color: AppColors.text),
            ),
            content: Text(
              'Your current week was built with the previous equipment. '
              'Regenerating replaces the current week but keeps history and '
              'PRs.',
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: AppTypography.label.copyWith(color: AppColors.muted),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Save only',
                  style: AppTypography.label.copyWith(color: AppColors.text),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'Save and regenerate',
                  style: AppTypography.label.copyWith(color: AppColors.lime),
                ),
              ),
            ],
          );
        },
      );
      if (regenerate == null || !mounted) {
        return;
      }
    }

    setState(() => _isSaving = true);
    final coordinator = context.read<AppCoordinator>();
    final saved = await coordinator.updateEquipment(
      _equipment,
      regeneratePlan: regenerate ?? false,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? regenerate == true
                    ? 'Equipment saved. Plan regenerated.'
                    : 'Equipment saved.'
              : 'Could not update your plan. Equipment was kept.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const AppBackBar(label: 'Me'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2l,
                  AppSpacing.md,
                  AppSpacing.x2l,
                  AppSpacing.x3l,
                ),
                children: <Widget>[
                  Text(
                    'Equipment',
                    style: AppTypography.h1.copyWith(color: AppColors.text),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Plans and swaps only include what you can train with.',
                    style: AppTypography.body.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.x3l),
                  EquipmentMultiSelect(
                    selected: _equipment,
                    onChanged: (value) => setState(() => _equipment = value),
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: AppSpacing.x2l),
                  Text(
                    _equipment.isEmpty
                        ? 'Select at least one equipment option.'
                        : '${_equipment.length} selected',
                    style: AppTypography.caption.copyWith(
                      color: _equipment.isEmpty
                          ? AppColors.orange
                          : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3l),
                  AppButton(
                    label: 'Save changes',
                    isLoading: _isSaving,
                    onPressed: _equipment.isEmpty || _isSaving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
