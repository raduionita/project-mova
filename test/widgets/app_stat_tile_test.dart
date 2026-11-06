import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/theme/app_colors.dart';
import 'package:mova/theme/app_theme.dart';
import 'package:mova/widgets/app_stat_tile.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('stat tile renders value, label, and icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AppStatTile(
          value: '12.4 t',
          label: 'Weekly volume',
          icon: Icons.fitness_center,
        ),
      ),
    );

    expect(find.text('12.4 t'), findsOneWidget);
    expect(find.text('Weekly volume'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.card);
    expect(decoration.border, Border.all(color: AppColors.line));
  });
}
