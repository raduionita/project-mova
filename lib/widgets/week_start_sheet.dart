import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common/week_start_context.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Opens the week start picker.
Future<void> showWeekStartSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.panel,
    builder: (_) => const WeekStartSheet(),
  );
}

/// Bottom sheet that selects the effective week start.
class WeekStartSheet extends StatelessWidget {
  const WeekStartSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final effective = effectiveWeekStart(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x2l,
          AppSpacing.xl,
          AppSpacing.x2l,
          AppSpacing.x2l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Week starts on',
              style: AppTypography.h2.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Used by the calendar and weekly summaries.',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            _WeekStartOption(
              optionKey: const Key('week-start-option-auto'),
              label: 'Automatic (${weekStartDayName(effective)})',
              selected: settings.weekStart == null,
              onTap: () => _select(context, null),
            ),
            _WeekStartOption(
              optionKey: Key('week-start-option-${DateTime.sunday}'),
              label: weekStartDayName(DateTime.sunday),
              selected: settings.weekStart == DateTime.sunday,
              onTap: () => _select(context, DateTime.sunday),
            ),
            for (var day = DateTime.monday; day < DateTime.sunday; day++)
              _WeekStartOption(
                optionKey: Key('week-start-option-$day'),
                label: weekStartDayName(day),
                selected: settings.weekStart == day,
                onTap: () => _select(context, day),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, int? weekStart) async {
    await context.read<SettingsProvider>().setWeekStart(weekStart);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _WeekStartOption extends StatelessWidget {
  const _WeekStartOption({
    required this.optionKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key optionKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: optionKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: selected ? AppColors.text : AppColors.muted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_rounded, size: 20, color: AppColors.lime),
          ],
        ),
      ),
    );
  }
}
