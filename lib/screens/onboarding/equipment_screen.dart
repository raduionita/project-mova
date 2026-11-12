import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/equipment_group.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/equipment_multi_select.dart';
import '../../widgets/equipment_preset_bar.dart';
import 'onboarding_scaffold.dart';

/// Onboarding step 9: the equipment the user can train with.
class OnboardingEquipmentScreen extends StatefulWidget {
  const OnboardingEquipmentScreen({super.key, this.onRoute});

  final ValueChanged<String>? onRoute;

  @override
  State<OnboardingEquipmentScreen> createState() =>
      _OnboardingEquipmentScreenState();
}

class _OnboardingEquipmentScreenState extends State<OnboardingEquipmentScreen> {
  late List<EquipmentGroup> _equipment;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _equipment = List<EquipmentGroup>.of(
      context.read<OnboardingProvider>().draft.availableEquipment,
    );
  }

  void _open(BuildContext context, String route) {
    final handler = widget.onRoute;
    if (handler != null) {
      handler(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _continue() async {
    if (_isBusy || _equipment.isEmpty) {
      return;
    }
    setState(() => _isBusy = true);
    final onboarding = context.read<OnboardingProvider>();
    await onboarding.setEquipment(_equipment);
    final next = OnboardingFlow.nextRoute(Routes.onboardingEquipment)!;
    onboarding.syncStep(OnboardingFlow.stepFor(next));
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    _open(context, next);
  }

  void _back(BuildContext context) {
    final previous = OnboardingFlow.previousRoute(Routes.onboardingEquipment)!;
    context.read<OnboardingProvider>().syncStep(
      OnboardingFlow.stepFor(previous),
    );
    _open(context, previous);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Your equipment',
      subtitle:
          'Select what you can train with. We will only plan exercises you '
          'can do.',
      currentStep: OnboardingFlow.stepForRoute(Routes.onboardingEquipment),
      onBack: () => _back(context),
      onContinue: _equipment.isEmpty || _isBusy ? null : _continue,
      continueEnabled: _equipment.isNotEmpty,
      isBusy: _isBusy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          EquipmentPresetBar(
            selected: _equipment,
            onApply: (preset) => setState(
              () => _equipment = List<EquipmentGroup>.of(preset.groups),
            ),
          ),
          const SizedBox(height: AppSpacing.x2l),
          EquipmentMultiSelect(
            selected: _equipment,
            onChanged: (value) => setState(() => _equipment = value),
          ),
        ],
      ),
    );
  }
}
