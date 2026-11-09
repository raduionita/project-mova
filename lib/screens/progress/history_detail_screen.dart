import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_coordinator.dart';
import '../../common/formatters.dart';
import '../../models/personal_record.dart';
import '../../models/session_exercise.dart';
import '../../models/unit_preferences.dart';
import '../../models/workout_session.dart';
import '../../models/workout_set.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/clock.dart';
import '../../services/share_card_service.dart';
import '../../services/unit_conversion_service.dart';
import '../../services/workout_calculator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/share_card_sheet.dart';

/// One completed workout with exercises, sets, notes, and deletion.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({
    super.key,
    required this.sessionId,
    this.clock,
    this.shareCardService = const ShareCardService(),
  });

  final String sessionId;
  final Clock? clock;
  final ShareCardService shareCardService;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
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
    final history = context.read<HistoryProvider>();
    final library = context.read<ExerciseProvider>();
    await Future.wait<void>(<Future<void>>[
      if (history.workouts.isEmpty && !history.isLoading) history.load(),
      if (library.exercises.isEmpty && !library.isLoading) library.load(),
    ]);
  }

  Future<void> _share(WorkoutSession session) async {
    final progress = context.read<ProgressProvider>();
    PersonalRecord? record;
    for (final item in progress.prs.values) {
      if (item.sessionId == session.id) {
        record = item;
        break;
      }
    }
    await ShareCardSheet.show(
      context,
      session: session,
      record: record,
      service: widget.shareCardService,
    );
  }

  Future<void> _confirmDelete(WorkoutSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.x2l),
          ),
          title: Text(
            'Delete workout?',
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
          content: Text(
            'Delete "${session.name}"? Personal records and your streak will '
            'be recalculated. This cannot be undone.',
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: AppTypography.label.copyWith(color: AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: AppTypography.label.copyWith(color: AppColors.orange),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final coordinator = context.read<AppCoordinator>();
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await coordinator.deleteWorkout(widget.sessionId);
    if (!mounted) {
      return;
    }
    if (!deleted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            coordinator.historyProvider.error ?? 'Could not delete workout.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  String _formatWeight(double weightKg, WeightUnit unit) {
    if (weightKg <= 0) {
      return '-';
    }
    final value = unit == WeightUnit.kg ? weightKg : _units.kgToLb(weightKg);
    final fixed = value.toStringAsFixed(1);
    final trimmed = fixed.endsWith('.0')
        ? fixed.substring(0, fixed.length - 2)
        : fixed;
    return '$trimmed ${_units.weightLabel(unit)}';
  }

  Widget _buildSetRow(WorkoutSet set, WeightUnit unit) {
    final value = set.weightKg <= 0
        ? '- × ${set.reps}'
        : '${_formatWeight(set.weightKg, unit)} × ${set.reps}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: AppSpacing.x4l,
            child: Text(
              '${set.index + 1}',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
            ),
          ),
          if (set.isWarmup) const AppTag(label: 'Warm-up'),
        ],
      ),
    );
  }

  Widget _buildExercise(
    SessionExercise exercise,
    ExerciseProvider library,
    WeightUnit unit,
  ) {
    final name = library.byId(exercise.exerciseId)?.name ?? 'Unknown exercise';
    final sets = <WorkoutSet>[...exercise.sets]
      ..sort((a, b) => a.index.compareTo(b.index));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                sets.length == 1 ? '1 set' : '${sets.length} sets',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          if (exercise.notes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              exercise.notes,
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final set in sets) _buildSetRow(set, unit),
        ],
      ),
    );
  }

  Widget _buildContent(
    WorkoutSession session,
    ExerciseProvider library,
    WeightUnit unit,
  ) {
    final date = session.completedAt ?? session.startedAt;
    final duration = WorkoutCalculator.sessionDurationSeconds(session, _now);
    final volume = WorkoutCalculator.volumeKg(session.exercises);
    final sets = WorkoutCalculator.completedSetCount(session.exercises);
    final exercises = <SessionExercise>[...session.exercises]
      ..sort((a, b) => a.order.compareTo(b.order));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTag(label: formatDetailDate(date)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  session.name,
                  style: AppTypography.h1.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.x2l),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppStatTile(
                        value: formatDuration(duration),
                        label: 'time',
                        assetIcon: AppIcons.clock,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppStatTile(
                        value: formatVolume(volume, unit: unit),
                        label: 'volume',
                        assetIcon: AppIcons.scale,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppStatTile(
                        value: '$sets',
                        label: 'sets',
                        assetIcon: AppIcons.check,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2l),
                for (
                  var index = 0;
                  index < exercises.length;
                  index++
                ) ...<Widget>[
                  if (index > 0) const SizedBox(height: AppSpacing.md),
                  _buildExercise(exercises[index], library, unit),
                ],
                if (session.notes.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.x2l),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Notes',
                          style: AppTypography.title.copyWith(
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          session.notes,
                          style: AppTypography.body.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Share card',
          variant: AppButtonVariant.ghost,
          onPressed: () => _share(session),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Delete workout',
          variant: AppButtonVariant.destructive,
          onPressed: () => _confirmDelete(session),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final library = context.watch<ExerciseProvider>();
    final settings = context.watch<SettingsProvider>();
    final session = history.byId(widget.sessionId);
    final unit = settings.settings.unitPreferences.weightUnit;

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
              const AppBackBar(label: 'History'),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: session == null
                    ? (history.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.lime,
                              ),
                            )
                          : const AppEmptyState(
                              assetIcon: AppIcons.search,
                              title: 'Workout not found',
                              message:
                                  'This workout was deleted or is no longer '
                                  'on this device.',
                            ))
                    : _buildContent(session, library, unit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
