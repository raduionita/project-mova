import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/date_keys.dart';
import '../../common/formatters.dart';
import '../../common/week_start_context.dart';
import '../../models/personal_record.dart';
import '../../models/unit_preferences.dart';
import '../../models/workout_session.dart';
import '../../navigation/routes.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/weight_provider.dart';
import '../../providers/wellness_provider.dart';
import '../../services/clock.dart';
import '../../services/muscle_balance_service.dart';
import '../../services/unit_conversion_service.dart';
import '../../services/week_streak_service.dart';
import '../../services/workout_calculator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/body_weight_sheet.dart';
import '../../widgets/progress_placeholder_card.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/volume_bars.dart';
import '../../widgets/weight_chart.dart';
import '../../widgets/wellness_quick_add.dart';

/// Plain-language definitions shown from the Progress header.
const List<(String, String)> _metricDefinitions = <(String, String)>[
  (
    'Workouts',
    'Completed sessions saved on this device. Discarded or unfinished '
        'sessions never count.',
  ),
  (
    'Volume',
    'Weight times reps for every completed set with external load. '
        'Bodyweight-only sets do not add volume.',
  ),
  (
    'Day streak',
    'Consecutive days with at least one completed workout, ending today.',
  ),
  (
    'Week streak',
    'Consecutive weeks that met your weekly target. The current week never '
        'ends a streak while it is still in progress.',
  ),
  (
    'Weekly consistency',
    'Sessions completed in the current calendar week compared with your plan '
        'target. Without a plan, the target is 3 sessions.',
  ),
  (
    'Weekly volume',
    'Volume from the current calendar week, starting on your week-start day.',
  ),
  (
    'Muscle balance',
    'Volume by muscle over the last 28 days. Primary muscles receive full '
        'volume and secondary muscles receive half.',
  ),
  (
    'PR',
    'The best estimated one-rep max for an exercise, from its heaviest '
        'completed set.',
  ),
  (
    'Wellness',
    'Nutrition, sleep, resting heart rate, and measurements are local trend '
        'notes. They are not medical advice.',
  ),
];

/// Progress dashboard with training, body, and wellness sections.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.clock});

  final Clock? clock;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with WidgetsBindingObserver {
  static const UnitConversionService _units = UnitConversionService();
  static const WeekStreakService _weeks = WeekStreakService();
  static const MuscleBalanceService _muscles = MuscleBalanceService();

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
    final weights = context.read<WeightProvider>();
    final wellness = context.read<WellnessProvider>();
    await Future.wait<void>(<Future<void>>[
      progress.load(),
      if (library.exercises.isEmpty && !library.isLoading) library.load(),
      if (profile.profile == null && !profile.isLoading) profile.load(),
      if (weights.entries.isEmpty && !weights.isLoading) weights.load(),
      if (wellness.entries.isEmpty && !wellness.isLoading) wellness.load(),
    ]);
  }

  Future<void> _addBodyWeight() async {
    await BodyWeightSheet.show(context);
  }

  Future<void> _openWeightLog() async {
    await Navigator.of(context).pushNamed(Routes.progressWeight);
  }

  void _startWorkout() {
    Navigator.of(context).pushNamed(Routes.today);
  }

  void _openPhotos() {
    Navigator.of(context).pushNamed(Routes.progressPhotos);
  }

  int _weeklyTarget(PlanProvider plan) {
    final target = plan.plan?.daysPerWeek ?? 3;
    return target < 1 ? 1 : target;
  }

  Map<String, double> _calendarWeekVolume(
    List<WorkoutSession> workouts,
    int weekStart,
  ) {
    final days = <String>{
      for (final date in DateKeys.weekDates(_now, weekStart: weekStart))
        DateKeys.dayKey(date),
    };
    final volume = <String, double>{};
    for (final workout in workouts) {
      final key = DateKeys.dayKey(
        workout.completedAt ?? workout.startedAt,
      );
      if (!days.contains(key)) {
        continue;
      }
      volume[key] =
          (volume[key] ?? 0) + WorkoutCalculator.volumeKg(workout.exercises);
    }
    return volume;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.label.copyWith(color: AppColors.muted),
      ),
    );
  }

  Widget _buildPlaceholderGrid(List<Widget> cards) {
    const gap = AppSpacing.md;
    final rows = <Widget>[];
    for (var index = 0; index < cards.length; index += 2) {
      final left = cards[index];
      final right = index + 1 < cards.length ? cards[index + 1] : null;
      rows.add(
        SizedBox(
          height: 168,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: left),
              const SizedBox(width: gap),
              Expanded(
                child: right ?? const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      if (index + 2 < cards.length) {
        rows.add(const SizedBox(height: gap));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildTotals(
    ProgressProvider progress,
    int weekStreak,
    WeightUnit unit,
  ) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: AppStatTile(
                value: '${progress.totalWorkouts}',
                label: 'workouts',
                assetIcon: AppIcons.dumbbell,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatTile(
                value: formatVolume(progress.totalVolumeKg, unit: unit),
                label: 'lifetime volume',
                assetIcon: AppIcons.scale,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: AppStatTile(
                key: const Key('progress-day-streak'),
                value: '${progress.streak}',
                label: 'day streak',
                assetIcon: AppIcons.flame,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatTile(
                key: const Key('progress-week-streak'),
                value: '$weekStreak',
                label: 'week streak',
                assetIcon: AppIcons.calendar,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightCard(
    WeightProvider weights,
    ProfileProvider profile,
    WeightUnit unit,
  ) {
    final latest =
        weights.latest?.weightKg ?? profile.profile?.bodyWeightKg ?? 0;
    final ordered = weights.entries.reversed.toList(growable: false);
    final hasTrend = ordered.length > 1;
    if (latest <= 0) {
      return ProgressPlaceholderCard(
        key: const Key('progress-weight-card'),
        title: 'Body weight',
        message: 'Add your weight to start a trend.',
        iconAsset: AppIcons.scale,
        actionLabel: 'Add weight',
        actionKey: const Key('progress-add-weight'),
        onAction: _addBodyWeight,
      );
    }
    return AppCard(
      key: const Key('progress-weight-card'),
      onTap: _openWeightLog,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const AppIcon(
                asset: AppIcons.scale,
                size: 22,
                color: AppColors.lime,
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Body weight',
                      style: AppTypography.title.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      latest <= 0
                          ? 'Add your weight to start a trend.'
                          : _units.displayWeight(latest, unit),
                      style: AppTypography.caption.copyWith(
                        color: latest <= 0 ? AppColors.muted : AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('progress-add-weight'),
                onPressed: _addBodyWeight,
                tooltip: 'Add weight',
                icon: const AppIcon(
                  asset: AppIcons.plus,
                  size: 20,
                  color: AppColors.lime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (hasTrend)
            WeightChart(entries: ordered, height: 90)
          else
            Text(
              weights.entries.isEmpty
                  ? 'Your first entry also updates your strength score.'
                  : 'Add another entry to see the trend line.',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
        ],
      ),
    );
  }

  Widget _buildConsistencyCard(
    int sessionsThisWeek,
    int target,
  ) {
    if (sessionsThisWeek == 0) {
      return ProgressPlaceholderCard(
        key: const Key('progress-consistency-card'),
        title: 'Weekly consistency',
        message: 'Log a session this week to track your $target-session target.',
        iconAsset: AppIcons.calendar,
        actionLabel: 'Start workout',
        actionKey: const Key('progress-consistency-start'),
        onAction: _startWorkout,
      );
    }
    final progress = (sessionsThisWeek / target).clamp(0.0, 1.0);
    final remaining = target - sessionsThisWeek;
    return AppCard(
      key: const Key('progress-consistency-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Weekly consistency',
                  style: AppTypography.title.copyWith(color: AppColors.text),
                ),
              ),
              AppTag(label: '$sessionsThisWeek of $target'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.xs),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lime),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            remaining <= 0
                ? 'Target reached for this week.'
                : '$remaining to go this week.',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeCard(
    Map<String, double> weekVolume,
    WeightUnit unit,
    int weekStart,
  ) {
    final total = weekVolume.values.fold(0.0, (sum, value) => sum + value);
    if (total <= 0) {
      return ProgressPlaceholderCard(
        key: const Key('progress-week-volume-card'),
        title: 'Weekly volume',
        message: 'Finish a working set this week to start your volume trend.',
        iconAsset: AppIcons.trendUp,
        actionLabel: 'Start workout',
        actionKey: const Key('progress-week-volume-start'),
        onAction: _startWorkout,
      );
    }
    return AppCard(
      key: const Key('progress-week-volume-card'),
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
              const AppTag(label: 'This week'),
            ],
          ),
          const SizedBox(height: AppSpacing.x2l),
          VolumeBars(
            volumeByDay: weekVolume,
            now: _now,
            unit: unit,
            weekStart: weekStart,
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleRow(
    String muscle,
    double volume,
    double maxVolume,
    WeightUnit unit,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 76,
            child: Text(
              muscle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: AppColors.text),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.xs),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: maxVolume <= 0 ? 0 : volume / maxVolume,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.lime,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 58,
            child: Text(
              formatVolume(volume, unit: unit),
              textAlign: TextAlign.right,
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleCard(
    Map<String, double> volumeByMuscle,
    WeightUnit unit,
  ) {
    final trained = volumeByMuscle.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    if (trained.isEmpty) {
      return ProgressPlaceholderCard(
        key: const Key('progress-muscle-card'),
        title: 'Muscle balance',
        message: 'Train this month to see volume across muscle groups.',
        iconAsset: AppIcons.bodyweight,
        actionLabel: 'Start workout',
        actionKey: const Key('progress-muscle-start'),
        onAction: _startWorkout,
      );
    }
    final visible = trained.take(6).toList(growable: false);
    final maxVolume = visible.first.value;
    final neglected = _muscles.neglectedMuscles(volumeByMuscle);
    return AppCard(
      key: const Key('progress-muscle-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Muscle balance',
                  style: AppTypography.title.copyWith(color: AppColors.text),
                ),
              ),
              const AppTag(label: '28 days'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final entry in visible)
            _buildMuscleRow(entry.key, entry.value, maxVolume, unit),
          if (neglected.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Neglect',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final muscle in neglected.take(5))
                  AppTag(label: muscle, variant: AppTagVariant.gold),
                if (neglected.length > 5)
                  AppTag(
                    label: '+${neglected.length - 5}',
                    variant: AppTagVariant.gold,
                  ),
              ],
            ),
          ],
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
    if (records.isEmpty) {
      return ProgressPlaceholderCard(
        key: const Key('progress-pr-card'),
        title: 'Personal records',
        message: 'Complete a weighted set to start your PR wall.',
        iconAsset: AppIcons.trophy,
        actionLabel: 'Start workout',
        actionKey: const Key('progress-pr-start'),
        onAction: _startWorkout,
      );
    }
    return AppCard(
      key: const Key('progress-pr-card'),
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
          for (var index = 0; index < records.length; index++) ...<Widget>[
            if (index > 0)
              const Divider(height: AppSpacing.x3l, color: AppColors.line),
            _buildPrRow(records[index], library, unit),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required Key key,
    required String title,
    required String value,
    required String caption,
    required String iconAsset,
    required VoidCallback onAdd,
    required Key addKey,
  }) {
    return AppCard(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppIcon(asset: iconAsset, size: 18, color: AppColors.lime),
              const Spacer(),
              IconButton(
                key: addKey,
                onPressed: onAdd,
                tooltip: 'Add $title',
                visualDensity: VisualDensity.compact,
                icon: const AppIcon(
                  asset: AppIcons.plus,
                  size: 17,
                  color: AppColors.lime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.title.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.micro.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildBodySection(
    WeightProvider weights,
    ProfileProvider profile,
    WellnessProvider wellness,
    WeightUnit unit,
  ) {
    final latest = wellness.latestMeasurement;
    final hasMeasurement = latest?.waistCm != null;
    final measurementCard = hasMeasurement
        ? _buildMetricCard(
            key: const Key('progress-measurements-card'),
            title: 'Measurements',
            value: '${latest!.waistCm!.toStringAsFixed(1)} cm',
            caption: 'Waist · latest',
            iconAsset: AppIcons.ruler,
            addKey: const Key('progress-measurements-add'),
            onAdd: () => addMeasurement(context),
          )
        : ProgressPlaceholderCard(
            key: const Key('progress-measurements-card'),
            title: 'Measurements',
            message: 'Add a waist measurement to start.',
            iconAsset: AppIcons.ruler,
            actionLabel: 'Add measurement',
            actionKey: const Key('progress-measurements-add'),
            onAction: () => addMeasurement(context),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionTitle('Body'),
        _buildWeightCard(weights, profile, unit),
        const SizedBox(height: AppSpacing.md),
        _buildPlaceholderGrid(<Widget>[
          measurementCard,
          ProgressPlaceholderCard(
            key: const Key('progress-photos-card'),
            title: 'Progress photos',
            message: 'Compare your look over time. Photos stay on this device.',
            iconAsset: AppIcons.document,
            actionLabel: 'Add photo',
            actionKey: const Key('progress-photos-add'),
            onAction: _openPhotos,
          ),
        ]),
      ],
    );
  }

  Widget _buildWellnessSection(WellnessProvider wellness) {
    final today = wellness.todayEntry;
    final nutrition = today != null && today.hasNutrition
        ? _buildMetricCard(
            key: const Key('progress-nutrition-card'),
            title: 'Nutrition',
            value: today.calories == null
                ? '${today.proteinGrams} g protein'
                : '${today.calories} kcal',
            caption: today.calories == null || today.proteinGrams == null
                ? 'Today'
                : '${today.proteinGrams} g protein',
            iconAsset: AppIcons.seedling,
            addKey: const Key('progress-nutrition-add'),
            onAdd: () => addNutrition(context),
          )
        : ProgressPlaceholderCard(
            key: const Key('progress-nutrition-card'),
            title: 'Nutrition',
            message: 'Log calories and protein for today.',
            iconAsset: AppIcons.seedling,
            actionLabel: 'Add nutrition',
            actionKey: const Key('progress-nutrition-add'),
            onAction: () => addNutrition(context),
          );
    final sleep = today != null && today.hasSleep
        ? _buildMetricCard(
            key: const Key('progress-sleep-card'),
            title: 'Sleep',
            value: formatSleep(today.sleepMinutes!),
            caption: 'Last night',
            iconAsset: AppIcons.clock,
            addKey: const Key('progress-sleep-add'),
            onAdd: () => addSleep(context),
          )
        : ProgressPlaceholderCard(
            key: const Key('progress-sleep-card'),
            title: 'Sleep',
            message: 'Log hours and minutes for last night.',
            iconAsset: AppIcons.clock,
            actionLabel: 'Add sleep',
            actionKey: const Key('progress-sleep-add'),
            onAction: () => addSleep(context),
          );
    final heartRate = today != null && today.hasRestingHeartRate
        ? _buildMetricCard(
            key: const Key('progress-rhr-card'),
            title: 'Resting heart rate',
            value: '${today.restingHeartRate} bpm',
            caption: 'Today',
            iconAsset: AppIcons.heart,
            addKey: const Key('progress-rhr-add'),
            onAdd: () => addRestingHeartRate(context),
          )
        : ProgressPlaceholderCard(
            key: const Key('progress-rhr-card'),
            title: 'Resting heart rate',
            message: 'Add a rested bpm reading.',
            iconAsset: AppIcons.heart,
            actionLabel: 'Add heart rate',
            actionKey: const Key('progress-rhr-add'),
            onAction: () => addRestingHeartRate(context),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSectionTitle('Wellness'),
        _buildPlaceholderGrid(<Widget>[nutrition, sleep, heartRate]),
      ],
    );
  }

  Widget _buildHistoryShortcut(ProgressProvider progress) {
    return AppCard(
      key: const Key('progress-history-shortcut'),
      onTap: () => Navigator.of(context).pushNamed(Routes.progressHistory),
      child: Row(
        children: <Widget>[
          const AppIcon(
            asset: AppIcons.history,
            size: 22,
            color: AppColors.lime,
          ),
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
          const AppIcon(
            asset: AppIcons.chevronRight,
            size: 20,
            color: AppColors.muted,
          ),
        ],
      ),
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
                    assetIcon: AppIcons.scale,
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

  Future<void> _showMetricsExplanation() async {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'What counts',
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final row in _metricDefinitions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 116,
                          child: Text(
                            row.$1,
                            style: AppTypography.bodyStrong.copyWith(
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            row.$2,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Got it',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    ProgressProvider progress,
    ProfileProvider profile,
    ExerciseProvider library,
    WeightProvider weights,
    WellnessProvider wellness,
    PlanProvider plan,
    WeightUnit unit,
    int weekStart,
  ) {
    final target = _weeklyTarget(plan);
    final sessionsThisWeek = _weeks.sessionsInWeek(
      progress.workouts,
      _now,
      weekStart: weekStart,
    );
    final weekStreak = _weeks.currentWeekStreak(
      progress.workouts,
      _now,
      weekStart: weekStart,
      target: target,
      profileCreatedAt: profile.profile?.createdAt,
    );
    final weekVolume = _calendarWeekVolume(progress.workouts, weekStart);
    final muscleVolume = _muscles.volumeByMuscle(progress.workouts, _now);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.x4l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSectionTitle('Training'),
          _buildTotals(progress, weekStreak, unit),
          const SizedBox(height: AppSpacing.x2l),
          _buildScoreCard(progress, profile),
          const SizedBox(height: AppSpacing.x2l),
          _buildConsistencyCard(sessionsThisWeek, target),
          const SizedBox(height: AppSpacing.x2l),
          _buildVolumeCard(weekVolume, unit, weekStart),
          const SizedBox(height: AppSpacing.x2l),
          _buildMuscleCard(muscleVolume, unit),
          const SizedBox(height: AppSpacing.x2l),
          _buildPrWall(progress, library),
          const SizedBox(height: AppSpacing.x3l),
          _buildBodySection(weights, profile, wellness, unit),
          const SizedBox(height: AppSpacing.x3l),
          _buildWellnessSection(wellness),
          const SizedBox(height: AppSpacing.x3l),
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
    final weights = context.watch<WeightProvider>();
    final wellness = context.watch<WellnessProvider>();
    final plan = context.watch<PlanProvider>();
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .weightUnit;
    final weekStart = effectiveWeekStart(context);

    Widget body;
    if (progress.isLoading && progress.totalWorkouts == 0) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.lime),
      );
    } else if (progress.error != null && progress.totalWorkouts == 0) {
      body = AppEmptyState(
        assetIcon: AppIcons.alert,
        title: 'Could not load progress',
        message: 'Your local history could not be read.',
        actionLabel: 'Try again',
        onAction: _load,
      );
    } else {
      body = _buildContent(
        progress,
        profile,
        library,
        weights,
        wellness,
        plan,
        unit,
        weekStart,
      );
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
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    key: const Key('progress-metrics-info'),
                    tooltip: 'What counts',
                    visualDensity: VisualDensity.compact,
                    onPressed: _showMetricsExplanation,
                    icon: const AppIcon(
                      asset: AppIcons.info,
                      size: 20,
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
