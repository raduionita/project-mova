import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/date_keys.dart';
import '../../common/formatters.dart';
import '../../models/unit_preferences.dart';
import '../../models/weight_entry.dart';
import '../../navigation/routes.dart';
import '../../providers/profile_provider.dart';
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
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/body_weight_sheet.dart';
import '../../widgets/weight_chart.dart';

/// Body-weight log with the current value, a trend chart, and history.
class WeightLogScreen extends StatefulWidget {
  const WeightLogScreen({super.key, this.clock});

  final Clock? clock;

  @override
  State<WeightLogScreen> createState() => _WeightLogScreenState();
}

class _WeightLogScreenState extends State<WeightLogScreen> {
  static const UnitConversionService _units = UnitConversionService();

  DateTime get _now => (widget.clock ?? const SystemClock()).now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final weights = context.read<WeightProvider>();
    final profile = context.read<ProfileProvider>();
    await Future.wait<void>(<Future<void>>[
      if (weights.entries.isEmpty && !weights.isLoading) weights.load(),
      if (profile.profile == null && !profile.isLoading) profile.load(),
    ]);
    if (!mounted) {
      return;
    }
    final current = profile.profile;
    if (current != null &&
        weights.entries.isEmpty &&
        current.bodyWeightKg > 0) {
      await weights.seedInitial(current.bodyWeightKg, date: current.updatedAt);
    }
  }

  Future<void> _addWeight() async {
    await BodyWeightSheet.show(context);
  }

  String _entryLabel(WeightEntry entry) {
    final parsed = DateTime.tryParse(entry.dateKey);
    if (parsed == null) {
      return entry.dateKey;
    }
    if (DateKeys.dayKey(parsed) == DateKeys.dayKey(_now)) {
      return 'Today';
    }
    return formatShortDate(parsed);
  }

  String _weight(double kg, WeightUnit unit) {
    return _units.displayWeight(kg, unit);
  }

  Widget _buildSummary(WeightProvider weights, WeightUnit unit) {
    final latest = weights.latest;
    final previous = weights.entries.length > 1 ? weights.entries[1] : null;
    final delta = latest == null || previous == null
        ? null
        : latest.weightKg - previous.weightKg;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Current weight',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      latest == null ? '-' : _weight(latest.weightKg, unit),
                      key: const Key('weight-log-current'),
                      style: AppTypography.display.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              if (delta != null)
                AppTag(
                  key: const Key('weight-log-delta'),
                  label:
                      '${delta == 0 ? '' : delta > 0 ? '+' : '-'}'
                      '${_units.displayWeight(delta.abs(), unit)}',
                  variant: delta == 0
                      ? AppTagVariant.neutral
                      : AppTagVariant.lime,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2l),
          AppButton(
            key: const Key('weight-log-add'),
            label: 'Add weight',
            assetIcon: AppIcons.plus,
            onPressed: _addWeight,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(WeightProvider weights, WeightUnit unit) {
    final ordered = weights.entries.reversed.toList(growable: false);
    if (ordered.isEmpty) {
      return AppCard(
        child: Text(
          'Log your weight to start a trend. One entry per day is enough.',
          style: AppTypography.body.copyWith(color: AppColors.muted),
        ),
      );
    }
    final values = ordered
        .map((entry) => entry.weightKg)
        .toList(growable: false);
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Trend',
                  style: AppTypography.title.copyWith(color: AppColors.text),
                ),
              ),
              Text(
                '${_weight(low, unit)} - ${_weight(high, unit)}',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2l),
          WeightChart(key: const Key('weight-log-chart'), entries: ordered),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(WeightEntry entry, WeightUnit unit) {
    return Padding(
      key: Key('weight-entry-${entry.dateKey}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              _entryLabel(entry),
              style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
            ),
          ),
          Text(
            _weight(entry.weightKg, unit),
            style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory(WeightProvider weights, WeightUnit unit) {
    if (weights.entries.isEmpty) {
      return Text(
        'No entries yet.',
        style: AppTypography.caption.copyWith(color: AppColors.muted),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: <Widget>[
          for (
            var index = 0;
            index < weights.entries.length;
            index++
          ) ...<Widget>[
            _buildHistoryRow(weights.entries[index], unit),
            if (index != weights.entries.length - 1)
              const Divider(height: 1, color: AppColors.line),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(WeightProvider weights, WeightUnit unit) {
    return AppEmptyState(
      assetIcon: AppIcons.scale,
      title: 'No weight entries',
      message: 'Add your weight to start a simple trend.',
      actionLabel: 'Add weight',
      onAction: _addWeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final weights = context.watch<WeightProvider>();
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;

    final body = weights.isLoading && weights.entries.isEmpty
        ? const Center(child: CircularProgressIndicator(color: AppColors.lime))
        : weights.entries.isEmpty
        ? _buildEmpty(weights, unit)
        : SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildSummary(weights, unit),
                const SizedBox(height: AppSpacing.x2l),
                _buildChartCard(weights, unit),
                const SizedBox(height: AppSpacing.x3l),
                Text(
                  'History',
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildHistory(weights, unit),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2l,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppBackBar(
                label: 'Progress',
                onBack: () =>
                    Navigator.of(context).pushReplacementNamed(Routes.progress),
              ),
              Text(
                'Body weight',
                style: AppTypography.h1.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'One entry per day. Stored only on this device.',
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.x2l),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
