import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/formatters.dart';
import '../../models/personal_record.dart';
import '../../models/unit_preferences.dart';
import '../../models/workout_session.dart';
import '../../navigation/routes.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/clock.dart';
import '../../services/haptics_service.dart';
import '../../services/share_card_service.dart';
import '../../services/unit_conversion_service.dart';
import '../../services/workout_calculator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/pr_badge.dart';
import '../../widgets/share_card_sheet.dart';

/// Arguments for the summary route.
class SummaryArgs {
  const SummaryArgs({
    required this.session,
    this.records = const <PersonalRecord>[],
  });

  final WorkoutSession session;
  final List<PersonalRecord> records;
}

/// Post-workout summary with duration, volume, completed sets, and any new
/// personal records. Saving the workout is wired in TRN-15.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({
    super.key,
    required this.session,
    this.records = const <PersonalRecord>[],
    this.onSave,
    this.onShare,
    this.clock,
    this.haptics,
    this.shareCardService = const ShareCardService(),
  });

  final WorkoutSession session;
  final List<PersonalRecord> records;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final Clock? clock;
  final HapticsService? haptics;
  final ShareCardService shareCardService;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final UnitConversionService _units = const UnitConversionService();

  Clock get _clock => widget.clock ?? const SystemClock();

  late final HapticsService _haptics = widget.haptics ?? const HapticsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLibrary();
      _playRecordFeedback();
    });
  }

  void _playRecordFeedback() {
    if (!mounted || _records.isEmpty) {
      return;
    }
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    unawaited(_haptics.personalRecord(reduceMotion: reduceMotion));
  }

  Future<void> _loadLibrary() async {
    if (!mounted) {
      return;
    }
    final library = context.read<ExerciseProvider>();
    if (library.exercises.isEmpty && !library.isLoading) {
      await library.load();
    }
  }

  List<PersonalRecord> get _records {
    final records =
        widget.records
            .where((record) => record.bestE1rmKg > 0)
            .toList(growable: false)
          ..sort((a, b) => b.bestE1rmKg.compareTo(a.bestE1rmKg));
    return records;
  }

  String _exerciseName(ExerciseProvider library, String exerciseId) {
    return library.byId(exerciseId)?.name ?? 'Exercise';
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Workout complete',
          style: AppTypography.h1.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.session.name,
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildPrCard(
    ExerciseProvider library,
    PersonalRecord record,
    WeightUnit unit,
  ) {
    final delta = record.bestE1rmKg - record.previousBestKg;
    return AppCard(
      featured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const PrBadge(),
              const Spacer(),
              if (record.achievedAt.millisecondsSinceEpoch > 0)
                Text(
                  formatShortDate(record.achievedAt),
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${_exerciseName(library, record.exerciseId)} · est. 1RM',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _units.displayWeight(record.bestE1rmKg, unit),
            style: AppTypography.metric.copyWith(color: AppColors.gold),
          ),
          if (record.previousBestKg > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            AppTag(
              label:
                  '${delta >= 0 ? '+' : ''}${_units.displayWeight(delta, unit)} vs last best',
              variant: AppTagVariant.neutral,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetrics(WeightUnit unit) {
    final seconds = WorkoutCalculator.sessionDurationSeconds(
      widget.session,
      _clock.now(),
    );
    final volume = WorkoutCalculator.volumeKg(widget.session.exercises);
    final sets = WorkoutCalculator.completedSetCount(widget.session.exercises);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: AppStatTile(
            value: formatDuration(seconds),
            label: 'Time',
            assetIcon: AppIcons.clock,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: formatVolume(volume, unit: unit),
            label: 'Volume',
            assetIcon: AppIcons.dumbbell,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: '$sets',
            label: 'Sets',
            assetIcon: AppIcons.check,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final library = context.watch<ExerciseProvider>();
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    final records = _records;
    final topRecord = records.isEmpty ? null : records.first;
    final otherRecords = records.length > 1
        ? records.sublist(1)
        : const <PersonalRecord>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildHeader(),
                const SizedBox(height: AppSpacing.x3l),
                if (topRecord != null) ...<Widget>[
                  _buildPrCard(library, topRecord, unit),
                  const SizedBox(height: AppSpacing.x2l),
                ],
                _buildMetrics(unit),
                if (otherRecords.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.x3l),
                  Text(
                    'Also new',
                    style: AppTypography.label.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final record in otherRecords)
                        AppTag(
                          label:
                              '${_exerciseName(library, record.exerciseId)} ${_units.displayWeight(record.bestE1rmKg, unit)}',
                          variant: AppTagVariant.gold,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        AppButton(label: 'Save workout', onPressed: _save),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Share card',
          variant: AppButtonVariant.ghost,
          onPressed: _share,
        ),
      ],
    );
  }

  Future<void> _share() async {
    final onShare = widget.onShare;
    if (onShare != null) {
      onShare();
      return;
    }
    final records = _records;
    await ShareCardSheet.show(
      context,
      session: widget.session,
      record: records.isEmpty ? null : records.first,
      service: widget.shareCardService,
    );
  }

  void _save() {
    final onSave = widget.onSave;
    if (onSave != null) {
      onSave();
      return;
    }
    Navigator.of(context).pushReplacementNamed(Routes.today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2l,
            vertical: AppSpacing.xl,
          ),
          child: _buildContent(),
        ),
      ),
    );
  }
}
