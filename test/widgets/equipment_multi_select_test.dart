import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/equipment_group.dart';
import 'package:mova/theme/app_icons.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_choice_card.dart';
import 'package:mova/widgets/equipment_multi_select.dart';

const List<String> _equipmentIcons = <String>[
  AppIcons.bodyweight,
  AppIcons.dumbbell,
  AppIcons.barbell,
  AppIcons.machine,
  AppIcons.cable,
  AppIcons.kettlebell,
  AppIcons.accessory,
];

Widget _wrap() {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: SingleChildScrollView(
        child: EquipmentMultiSelect(
          selected: EquipmentGroup.values,
          onChanged: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('gives every equipment group its own icon', (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap());

    final cards = tester
        .widgetList<AppChoiceCard>(find.byType(AppChoiceCard))
        .toList();
    expect(cards, hasLength(EquipmentGroup.values.length));
    expect(cards.map((card) => card.assetIcon).toList(), _equipmentIcons);
    expect(
      cards.map((card) => card.assetIcon).toSet(),
      hasLength(cards.length),
    );
  });

  testWidgets('bundles every equipment icon asset', (tester) async {
    for (final asset in _equipmentIcons) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
