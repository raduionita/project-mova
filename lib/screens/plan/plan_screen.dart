import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_coordinator.dart';
import '../../common/constants.dart';
import '../../models/experience_level.dart';
import '../../models/plan_day.dart';
import '../../models/routine.dart';
import '../../models/routine_exercise.dart';
import '../../models/split_style.dart';
import '../../models/training_plan.dart';
import '../../navigation/routes.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/routine_provider.dart';
import '../../services/id_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_tag.dart';

/// Rotation planner. Schedule changes stay staged until regenerated.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  int? _daysPerWeek;
  SplitStyle? _splitStyle;
  bool _isWorking = false;
  String? _notice;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLibrary());
  }

  Future<void> _ensureLibrary() async {
    if (!mounted) {
      return;
    }
    final exercises = context.read<ExerciseProvider>();
    if (exercises.exercises.isNotEmpty || exercises.isLoading) {
      return;
    }
    await exercises.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final plan = context.watch<PlanProvider>().plan;
    if (plan != null) {
      _daysPerWeek ??= plan.daysPerWeek;
      _splitStyle ??= plan.splitStyle;
    }
  }

  int get _stagedDays {
    final plan = context.read<PlanProvider>().plan;
    return _daysPerWeek ?? plan?.daysPerWeek ?? 3;
  }

  SplitStyle get _stagedSplit {
    final plan = context.read<PlanProvider>().plan;
    return _splitStyle ?? plan?.splitStyle ?? SplitStyle.auto;
  }

  bool _isStaged(TrainingPlan plan) {
    return _stagedDays != plan.daysPerWeek || _stagedSplit != plan.splitStyle;
  }

  Future<void> _regenerate() async {
    final plan = context.read<PlanProvider>().plan;
    if (plan == null) {
      await _createPlan();
      return;
    }
    if (!_isStaged(plan) && !_isWorking) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.x2l),
          ),
          title: Text(
            'Regenerate rotation?',
            style: AppTypography.h2.copyWith(color: AppColors.text),
          ),
          content: Text(
            'Your history, personal records, and streak stay intact. The '
            'rotation restarts at Day 1.',
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
                'Regenerate',
                style: AppTypography.label.copyWith(color: AppColors.lime),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _isWorking = true;
      _error = null;
      _notice = null;
    });
    final provider = context.read<PlanProvider>();
    final regenerated = await provider.updateSchedule(
      daysPerWeek: _stagedDays,
      splitStyle: _stagedSplit,
    );
    if (!mounted) {
      return;
    }
    final updated = provider.plan;
    setState(() {
      _isWorking = false;
      if (regenerated && updated != null) {
        _daysPerWeek = updated.daysPerWeek;
        _splitStyle = updated.splitStyle;
        final warning = provider.lastWarning;
        _notice = warning == null || warning.isEmpty
            ? 'Rotation rebuilt. Day 1 is next.'
            : 'Rotation rebuilt. $warning';
      } else {
        _error = provider.error ?? 'Could not regenerate the plan.';
      }
    });
  }

  Future<void> _moveDay(PlanDay day, int delta) async {
    final plan = context.read<PlanProvider>().plan;
    if (plan == null) {
      return;
    }
    final from = plan.days.indexOf(day);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= plan.days.length) {
      return;
    }
    setState(() {
      _isWorking = true;
      _error = null;
      _notice = null;
    });
    final provider = context.read<PlanProvider>();
    final moved = await provider.reorderPlanDay(fromIndex: from, toIndex: to);
    if (!mounted) {
      return;
    }
    setState(() {
      _isWorking = false;
      if (!moved) {
        _error = provider.error ?? 'Could not reorder that session.';
      }
    });
  }

  Future<void> _startDay(PlanDay day) async {
    final started = await context.read<AppCoordinator>().startPlanDay(day);
    if (!mounted) {
      return;
    }
    if (!started) {
      setState(() => _error = 'Could not start that session.');
      return;
    }
    Navigator.of(context).pushNamed(Routes.logger);
  }

  Future<void> _saveAsSavedWorkout(PlanDay day) async {
    if (_isWorking) {
      return;
    }
    final provider = context.read<RoutineProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final routine = Routine(
      id: IdService().next(),
      name: day.name,
      createdAt: now,
      updatedAt: now,
      exercises: <RoutineExercise>[
        for (var index = 0; index < day.exercises.length; index++)
          RoutineExercise(
            exerciseId: day.exercises[index].exerciseId,
            sets: day.exercises[index].sets,
            repsLow: day.exercises[index].repsLow,
            repsHigh: day.exercises[index].repsHigh,
            restSeconds: day.exercises[index].restSeconds,
            order: index,
          ),
      ],
    );
    final saved = await provider.save(routine);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Saved ${day.name} to saved workouts.'
              : provider.error ?? 'Could not save that workout.',
        ),
      ),
    );
  }

  Future<void> _startRoutine(Routine routine) async {
    final started = await context.read<AppCoordinator>().startRoutine(routine);
    if (!mounted) {
      return;
    }
    if (!started) {
      setState(() => _error = 'Could not start that routine.');
      return;
    }
    Navigator.of(context).pushNamed(Routes.logger);
  }

  Future<void> _createPlan() async {
    if (_isWorking) {
      return;
    }
    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) {
      setState(() => _error = 'Finish your profile before creating a rotation.');
      return;
    }
    setState(() {
      _isWorking = true;
      _error = null;
      _notice = null;
    });
    final provider = context.read<PlanProvider>();
    final created = await provider.generate(
      goals: profile.goals,
      experienceLevel: profile.experienceLevel ?? ExperienceLevel.regular,
      daysPerWeek: _stagedDays,
      splitStyle: _stagedSplit,
      availableEquipment: profile.availableEquipment,
    );
    if (!mounted) {
      return;
    }
    final updated = provider.plan;
    setState(() {
      _isWorking = false;
      if (created && updated != null) {
        _daysPerWeek = updated.daysPerWeek;
        _splitStyle = updated.splitStyle;
        final warning = provider.lastWarning;
        _notice = warning == null || warning.isEmpty
            ? 'Rotation created. Day 1 is next.'
            : 'Rotation created. $warning';
      } else {
        _error = provider.error ?? 'Could not create the rotation.';
      }
    });
  }

  Widget _buildCreateCard() {
    return AppCard(
      key: const Key('plan-create-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Start a rotation',
            style: AppTypography.title.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Optional. Pick an average frequency and Mova builds sessions '
            'you can start from Today.',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (var day = kMinTrainingDays; day <= kMaxTrainingDays; day++)
                AppChip(
                  key: Key('plan-frequency-$day'),
                  label: '$day',
                  selected: _stagedDays == day,
                  onTap: _isWorking
                      ? null
                      : () => setState(() {
                          _daysPerWeek = day;
                          _error = null;
                        }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2l),
          Text(
            'Split style',
            style: AppTypography.label.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final style in SplitStyle.values)
                AppChip(
                  key: Key('plan-split-${style.name}'),
                  label: style.label,
                  selected: _stagedSplit == style,
                  onTap: _isWorking
                      ? null
                      : () => setState(() {
                          _splitStyle = style;
                          _error = null;
                        }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            key: const Key('plan-create'),
            label: 'Create rotation',
            isLoading: _isWorking,
            onPressed: _isWorking ? null : _createPlan,
          ),
          if (_notice != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              _notice!,
              style: AppTypography.caption.copyWith(color: AppColors.lime),
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTypography.caption.copyWith(color: AppColors.orange),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Your rotation',
          style: AppTypography.h1.copyWith(color: AppColors.text),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sessions run in order and repeat. Train on any day, and unlogged '
          'days count as rest.',
          style: AppTypography.body.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildSettings(TrainingPlan plan) {
    final staged = _isStaged(plan);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'How often do you train?',
            style: AppTypography.title.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Average days per week. This is a guide, not a fixed schedule.',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (var day = kMinTrainingDays; day <= kMaxTrainingDays; day++)
                AppChip(
                  key: Key('plan-frequency-$day'),
                  label: '$day',
                  selected: _stagedDays == day,
                  onTap: _isWorking
                      ? null
                      : () => setState(() {
                          _daysPerWeek = day;
                          _notice = null;
                          _error = null;
                        }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2l),
          Text(
            'Split style',
            style: AppTypography.label.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final style in SplitStyle.values)
                AppChip(
                  key: Key('plan-split-${style.name}'),
                  label: style.label,
                  selected: _stagedSplit == style,
                  onTap: _isWorking
                      ? null
                      : () => setState(() {
                          _splitStyle = style;
                          _notice = null;
                          _error = null;
                        }),
                ),
            ],
          ),
          if (staged) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              key: const Key('plan-regenerate'),
              label: 'Regenerate rotation',
              isLoading: _isWorking,
              onPressed: _isWorking ? null : _regenerate,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Changes apply only after you regenerate.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ],
          if (_notice != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              _notice!,
              style: AppTypography.caption.copyWith(color: AppColors.lime),
            ),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTypography.caption.copyWith(color: AppColors.orange),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRotation(List<PlanDay> days) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Rotation',
                style: AppTypography.title.copyWith(color: AppColors.text),
              ),
            ),
            Text(
              days.length == 1 ? '1 session' : '${days.length} sessions',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < days.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          _buildDayCard(days[index], index, days.length),
        ],
      ],
    );
  }

  Widget _buildDayCard(PlanDay day, int index, int total) {
    final exercises = context.watch<ExerciseProvider>();
    final count = day.exercises.length;
    return AppCard(
      key: Key('plan-day-${index + 1}'),
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
                      'DAY ${index + 1}',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.lime,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      day.name,
                      style: AppTypography.title.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    if (day.muscleGroups.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        day.muscleGroups.join(' · '),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: <Widget>[
                  IconButton(
                    key: Key('plan-day-up-${index + 1}'),
                    tooltip: 'Move earlier',
                    visualDensity: VisualDensity.compact,
                    onPressed: index == 0 || _isWorking
                        ? null
                        : () => _moveDay(day, -1),
                    icon: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: AppColors.muted,
                    ),
                  ),
                  IconButton(
                    key: Key('plan-day-down-${index + 1}'),
                    tooltip: 'Move later',
                    visualDensity: VisualDensity.compact,
                    onPressed: index == total - 1 || _isWorking
                        ? null
                        : () => _moveDay(day, 1),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              AppTag(label: '${day.estimatedMinutes} min'),
              const SizedBox(width: AppSpacing.sm),
              AppTag(label: count == 1 ? '1 exercise' : '$count exercises'),
            ],
          ),
          if (count > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
              ),
              child: ExpansionTile(
                key: Key('plan-day-exercises-${index + 1}'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
                iconColor: AppColors.muted,
                collapsedIconColor: AppColors.muted,
                title: Text(
                  'Exercise preview',
                  style: AppTypography.label.copyWith(color: AppColors.muted),
                ),
                children: <Widget>[
                  for (final exercise in day.exercises)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              exercises.byId(exercise.exerciseId)?.name ??
                                  exercise.exerciseId,
                              style: AppTypography.body.copyWith(
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${exercise.sets} x '
                            '${exercise.repsLow}-${exercise.repsHigh}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: Key('plan-day-start-${index + 1}'),
            label: 'Start session',
            assetIcon: AppIcons.play,
            onPressed: _isWorking ? null : () => _startDay(day),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: Key('plan-day-save-${index + 1}'),
            onPressed: _isWorking ? null : () => _saveAsSavedWorkout(day),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.muted,
              minimumSize: const Size(44, 44),
            ),
            child: const Text('Save as saved workout'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutines(List<Routine> routines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Saved workouts',
                style: AppTypography.title.copyWith(color: AppColors.text),
              ),
            ),
            TextButton(
              key: const Key('plan-new-routine'),
              onPressed: () =>
                  Navigator.of(context).pushNamed(Routes.routineNew),
              child: Text(
                'New saved workout',
                style: AppTypography.label.copyWith(color: AppColors.lime),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (routines.isEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Build a reusable session',
                  style: AppTypography.bodyStrong.copyWith(
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Saved workouts are templates. Start one any day without '
                  'changing the rotation.',
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          for (final routine in routines.take(3)) ...<Widget>[
            AppCard(
              key: Key('plan-routine-${routine.id}'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          routine.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyStrong.copyWith(
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          routine.exercises.length == 1
                              ? '1 exercise'
                              : '${routine.exercises.length} exercises',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    key: Key('plan-routine-start-${routine.id}'),
                    onPressed: _isWorking ? null : () => _startRoutine(routine),
                    child: Text(
                      'Start',
                      style: AppTypography.label.copyWith(
                        color: AppColors.lime,
                      ),
                    ),
                  ),
                  IconButton(
                    key: Key('plan-routine-open-${routine.id}'),
                    tooltip: 'View saved workout',
                    onPressed: () =>
                        Navigator.of(context)
                            .pushNamed(Routes.routineDetail(routine.id)),
                    icon: const AppIcon(
                      asset: AppIcons.chevronRight,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        if (routines.length > 3)
          TextButton(
            key: const Key('plan-view-all-routines'),
            onPressed: () => Navigator.of(context).pushNamed(Routes.routines),
            child: Text(
              'View all saved workouts',
              style: AppTypography.label.copyWith(color: AppColors.muted),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<PlanProvider>().plan;
    final routines = context.watch<RoutineProvider>().routines;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const AppBackBar(label: 'Today'),
            Expanded(
              child: plan == null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x2l,
                        0,
                        AppSpacing.x2l,
                        AppSpacing.x4l,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildHeader(),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildCreateCard(),
                          const SizedBox(height: AppSpacing.x3l),
                          _buildRoutines(routines),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.x2l,
                        0,
                        AppSpacing.x2l,
                        AppSpacing.x4l,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildHeader(),
                          const SizedBox(height: AppSpacing.x2l),
                          _buildSettings(plan),
                          const SizedBox(height: AppSpacing.x3l),
                          _buildRotation(plan.days),
                          const SizedBox(height: AppSpacing.x3l),
                          _buildRoutines(routines),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
