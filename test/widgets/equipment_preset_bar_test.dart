import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/equipment_group.dart';
import 'package:mova/models/equipment_preset.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_chip.dart';
import 'package:mova/widgets/equipment_preset_bar.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

void main() {
  test('each preset matches only its own selection', () {
    for (final preset in EquipmentPreset.all) {
      expect(preset.matches(preset.groups), isTrue);
    }
    expect(
      EquipmentPreset.bodyweightOnly.matches(EquipmentPreset.home.groups),
      isFalse,
    );
    expect(
      EquipmentPreset.fullGym.matches(EquipmentPreset.home.groups),
      isFalse,
    );
  });

  testWidgets('tapping a preset reports its groups and highlights it', (
    tester,
  ) async {
    EquipmentPreset? applied;
    await tester.pumpWidget(
      _wrap(
        EquipmentPresetBar(
          selected: EquipmentPreset.home.groups,
          onApply: (preset) => applied = preset,
        ),
      ),
    );

    expect(find.byKey(const Key('equipment-preset-home')), findsOneWidget);
    await tester.tap(find.byKey(const Key('equipment-preset-bodyweight-only')));
    await tester.pumpAndSettle();

    expect(applied, EquipmentPreset.bodyweightOnly);
    expect(
      tester
          .widget<AppChip>(find.byKey(const Key('equipment-preset-home')))
          .selected,
      isTrue,
    );
  });

  testWidgets('disabled presets do nothing', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EquipmentPresetBar(
          selected: const <EquipmentGroup>[],
          enabled: false,
          onApply: (_) => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('equipment-preset-full-gym')));
    await tester.pumpAndSettle();

    expect(tapped, isFalse);
  });
}
