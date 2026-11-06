import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/formatters.dart';
import '../../models/personal_record.dart';
import '../../models/unit_preferences.dart';
import '../../navigation/routes.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/clock.dart';
import '../../services/unit_conversion_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/body_weight_sheet.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/volume_bars.dart';

/// Progress dashboard with lifetime totals, score, weekly volume, and PRs.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.clock});

  final Clock? clock;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with WidgetsBindingObserver {
  static const UnitConversionService _units = UnitConversionService();

  DateTime get _now => (widget.clock ?? const SystemClock()).now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    final progress = context.read<ProgressProvider>();
    final library = context.read<ExerciseProvider>();
    final profile = context.read<ProfileProvider>();
    await Future.wait<void>(<Future<void>>[
      progress.load(),
      if (library.exercises.isEmpty && !library.isLoading) library.load(),
      if (profile.profile == null && !profile.isLoading) profile.load(),
    ]);
  }

  Future<void> _addBodyWeight() async {
    await BodyWeightSheet.show(context);
  }

  Future<void> _showScoreExplanation() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.panel,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3l,
            AppSpacing.x2l,
            AppSpacing.x3l,
            AppSpacing.x3l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'How the score works',
                style: AppTypography.h2.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'The score averages your best estimated one-rep max for the '
                'back squat, bench press, deadlift, and overhead press as a '
                'percentage of your body weight. It needs 3 workouts, 2 of '
                'those lifts, and your body weight.',
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'It is a personal strength trend. There is no gym, global, or '
                'percentile ranking.',
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.x3l),
              AppButton(
                label: 'Got it',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotals(ProgressProvider progress, WeightUnit unit) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppStatTile(
            value: '${progress.totalWorkouts}',
            label: 'workouts',
            icon: Icons.fitness_center,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: formatVolume(progress.totalVolumeKg, unit: unit),
            label: 'volume',
            icon: Icons.scale_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppStatTile(
            value: '${progress.streak}',
            label: 'day streak',
            icon: Icons.local_fire_department_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(ProgressProvider progress, ProfileProvider profile) {
    final score = progress.strengthScore;
    final hasBodyWeight = (profile.profile?.bodyWeightKg ?? 0) > 0;
    return AppCard(
      featured: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ProgressRing(
            value: score == null ? 0 : (score / 200).clamp(0.0, 1.0),
            label: 'Strength',
            valueLabel: score?.toString() ?? '-',
          ),
          const SizedBox(width: AppSpacing.x2l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Strength score',
                        style: AppTypography.h2.copyWith(color: AppColors.text),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const AppTag(label: 'Beta', variant: AppTagVariant.lime),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  score == null
                      ? progress.scoreReason ??
                            'Not enough training history for a strength score.'
                      : 'Relative to your body weight across tracked lifts.',
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
                if (score == null && !hasBodyWeight) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    key: const Key('add-body-weight'),
                    label: 'Add body weight',
                    icon: Icons.monitor_weight_outlined,
                    variant: AppButtonVariant.ghost,
                    fullWidth: false,
                    onPressed: _addBodyWeight,
                  ),
                ],
                TextButton(
                  key: const Key('score-explanation'),
                  onPressed: _showScoreExplanation,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'How it works',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.lime,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard(ProgressProvider progress, WeightUnit unit) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Weekly volume',
                  style: AppTypography.title.copyWith(color: AppColors.text),
                ),
              ),
              const AppTag(label: '7 days'),
            ],
          ),
          const SizedBox(height: AppSpacing.x2l),
          VolumeBars(volumeByDay: progress.weeklyVolume, now: _now, unit: unit),
        ],
      ),
    );
  }

  Widget _buildPrRow(
    PersonalRecord record,
    ExerciseProvider library,
    WeightUnit unit,
  ) {
    final name = library.byId(record.exerciseId)?.name ?? record.exerciseId;
    return Row(
      children: <Widget>[
        const AppTag(label: 'PR', variant: AppTagVariant.gold),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${_units.displayWeight(record.weightKg, unit)} × '
                '${record.reps} reps',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '${_units.displayWeight(record.bestE1rmKg, unit)} e1RM',
          style: AppTypography.caption.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildPrWall(ProgressProvider progress, ExerciseProvider library) {
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    final records = progress.prs.values.toList(growable: false)
      ..sort((a, b) => b.bestE1rmKg.compareTo(a.bestE1rmKg));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Personal records',
                  style: AppTypography.title.copyWith(color: AppColors.text),
                ),
              ),
              Text(
                '${records.length}',
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2l),
          if (records.isEmpty)
            Text(
              'No personal records yet.',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            )
          else
            for (var index = 0; index < records.length; index++) ...<Widget>[
              if (index > 0)
                const Divider(height: AppSpacing.x3l, color: AppColors.line),
              _buildPrRow(records[index], library, unit),
            ],
        ],
      ),
    );
  }

  Widget _buildHistoryShortcut(ProgressProvider progress) {
    return AppCard(
      onTap: () => Navigator.of(context).pushNamed(Routes.progressHistory),
      child: Row(
        children: <Widget>[
          const Icon(Icons.history, color: AppColors.lime),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Workout history',
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  progress.totalWorkouts == 1
                      ? '1 workout'
                      : '${progress.totalWorkouts} workouts',
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.insights_outlined,
      title: 'No workouts yet',
      message: 'Finish a workout to see your progress here.',
      actionLabel: 'Start your first workout',
      onAction: () => Navigator.of(context).pushReplacementNamed(Routes.today),
    );
  }

  Widget _buildContent(
    ProgressProvider progress,
    ProfileProvider profile,
    ExerciseProvider library,
    WeightUnit unit,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildTotals(progress, unit),
          const SizedBox(height: AppSpacing.x2l),
          _buildScoreCard(progress, profile),
          const SizedBox(height: AppSpacing.x2l),
          _buildVolumeCard(progress, unit),
          const SizedBox(height: AppSpacing.x2l),
          _buildPrWall(progress, library),
          const SizedBox(height: AppSpacing.x2l),
          _buildHistoryShortcut(progress),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final profile = context.watch<ProfileProvider>();
    final library = context.watch<ExerciseProvider>();
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;

    Widget body;
    if (progress.isLoading && progress.totalWorkouts == 0) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.lime),
      );
    } else if (progress.error != null && progress.totalWorkouts == 0) {
      body = AppEmptyState(
        icon: Icons.error_outline,
        title: 'Could not load progress',
        message: 'Your local history could not be read.',
        actionLabel: 'Try again',
        onAction: _load,
      );
    } else if (progress.totalWorkouts == 0) {
      body = _buildEmptyState();
    } else {
      body = _buildContent(progress, profile, library, unit);
    }

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
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Progress',
                      style: AppTypography.h1.copyWith(color: AppColors.text),
                    ),
                  ),
                  if (progress.totalWorkouts > 0)
                    Text(
                      'Lifetime',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x3l),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
