import 'package:flutter/material.dart';

import '../navigation/app_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Phase-aware bottom navigation bar from DESIGN.md section 8.12.
///
/// Tabs that have not reached their release phase are not built, so later
/// phases stay hidden until [phase] enables them.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    this.phase = AppNavigation.currentPhase,
  });

  static const double _height = 56;
  static const double _iconSize = 22;

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;
  final AppPhase phase;

  List<AppTabItem> get _tabs => AppNavigation.visibleTabs(phase: phase);

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _height,
          child: Row(
            children: <Widget>[
              for (final item in tabs)
                Expanded(child: _buildItem(item, item.tab == currentTab)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(AppTabItem item, bool selected) {
    final color = selected ? AppColors.lime : AppColors.tabInactive;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkResponse(
        onTap: () => onTabSelected(item.tab),
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: _iconSize,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: AppTypography.micro.copyWith(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
