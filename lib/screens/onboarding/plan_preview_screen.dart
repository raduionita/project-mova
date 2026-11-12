import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/constants.dart';
import '../../common/goal_display.dart';
import '../../models/experience_level.dart';
import '../../models/exercise.dart';
import '../../models/goal.dart';
import '../../models/onboarding_draft.dart';
import '../../models/plan_day.dart';
import '../../models/training_plan.dart';
import '../../navigation/onboarding_flow.dart';
import '../../navigation/routes.dart';
import '../../app_coordinator.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/clock.dart';
import '../../services/plan_generator_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import 'onboarding_scaffold.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_tag.dart';

/// Shows the generated week before onboarding is committed.
class PlanPreviewScreen extends StatefulWidget {
  const PlanPreviewScreen({
    super.key,
    this.onRoute,
    this.previewBuilder,
    this.exercises,
    this.clock,
  });

  final ValueChanged<String>? onRoute;

  /// Optional preview factory for tests. When null the real plan generator
  /// runs against the loaded exercise library.
  final TrainingPlan Function(OnboardingDraft draft)? previewBuilder;

  /// Optional exercise library override for tests.
  final List<Exercise>? exercises;

  final Clock? clock;

  @override
  State<PlanPreviewScreen> createState() => _PlanPreviewScreenState();
}

class _PlanPreviewScreenState extends State<PlanPreviewScreen> {
  static const Map<ExperienceLevel, String> _experienceLabels =
      <ExperienceLevel, String>{
        ExperienceLevel.beginner: 'Beginner',
        ExperienceLevel.regular: 'Regular',
        ExperienceLevel.gymRat: 'Gym rat',
        ExperienceLevel.veteran: 'Veteran',
      };

  TrainingPlan? _plan;
  bool _loading = true;
  bool _confirming = false;
  String? _failure;
  String? _confirmError;
  String? _warning;

  OnboardingDraft get _draft => context.read<OnboardingProvider>().draft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generatePreview());
  }

  Future<void> _generatePreview() async {
    final draft = _draft;
    if (!draft.planEnabled) {
      if (mounted) {
        setState(() {
          _plan = null;
          _loading = false;
          _failure = null;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final plan =
          widget.previewBuilder?.call(draft) ?? await _generatePlan(draft);
      if (!mounted) {
        return;
      }
      setState(() {
        _plan = plan;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _failure = error.toString();
        _loading = false;
      });
    }
  }

  Future<TrainingPlan> _generatePlan(OnboardingDraft draft) async {
    final clock = widget.clock ?? const SystemClock();
    var exercises = widget.exercises;
    if (exercises == null) {
      final provider = context.read<ExerciseProvider>();
      if (provider.exercises.isEmpty) {
        await provider.load();
      }
      exercises = provider.exercises;
    }
    final generator = PlanGeneratorService(
      exercises: exercises,
      now: clock.now,
      sessionMinutes: kDefaultSessionMinutes,
    );
    final plan = generator.generate(
      goals: draft.goals,
      experienceLevel: draft.experienceLevel ?? ExperienceLevel.beginner,
      daysPerWeek: draft.daysPerWeek ?? 3,
      availableEquipment: draft.availableEquipment,
    );
    _warning = generator.lastWarning;
    return plan;
  }

  void _go(String route) {
    final handler = widget.onRoute;
    if (handler != null) {
      handler(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _confirm() async {
    setState(() {
      _confirming = true;
      _confirmError = null;
    });
    final coordinator = context.read<AppCoordinator>();
    final saved = await coordinator.completeOnboarding(_draft);
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() {
        _confirming = false;
        _confirmError = 'Could not finish setup. Try again.';
      });
      return;
    }
    setState(() => _confirming = false);
    _go(Routes.today);
  }

  void _editSchedule() {
    final onboarding = context.read<OnboardingProvider>();
    onboarding.beginPlanEdit();
    onboarding.syncStep(OnboardingFlow.stepFor(Routes.onboardingSchedule));
    _go(Routes.onboardingSchedule);
  }

  void _back() {
    final previous =
        OnboardingFlow.previousRoute(Routes.onboardingPlan) ?? Routes.welcome;
    context.read<OnboardingProvider>().syncStep(
      OnboardingFlow.stepFor(previous),
    );
    _go(previous);
  }

  String _subtitle(OnboardingDraft draft) {
    final goal = draft.goals.isEmpty
        ? goalLabel(Goal.buildMuscle)
        : goalLabel(draft.goals.first);
    final level =
        _experienceLabels[draft.experienceLevel ?? ExperienceLevel.beginner]!;
    if (!draft.planEnabled) {
      return '$goal · $level';
    }
    final days = draft.daysPerWeek ?? 3;
    return '$goal · $days days · $level';
  }

  String _dayDetail(PlanDay day) {
    final parts = <String>[
      if (day.muscleGroups.isNotEmpty) day.muscleGroups.join(' · '),
      '${day.exercises.length} ${day.exercises.length == 1 ? 'exercise' : 'exercises'}',
      '~${day.estimatedMinutes} min',
    ];
    return parts.join(' · ');
  }

  Widget _buildDayCard(PlanDay day) {
    final label = 'DAY ${day.order + 1}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(
                label,
                style: AppTypography.micro.copyWith(color: AppColors.lime),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    day.name,
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    _dayDetail(day),
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
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.x6l),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.lime,
          ),
        ),
      ),
    );
  }

  Widget _buildFailure() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Could not build your plan.',
            style: AppTypography.bodyStrong.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'The starter plan is still available. Try again to build your rotation.',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Retry',
            onPressed: _generatePreview,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanList(TrainingPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_warning != null && _warning!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              _warning!,
              style: AppTypography.caption.copyWith(color: AppColors.orange),
            ),
          ),
        if (plan.isFallback)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppTag(label: 'Starter plan', variant: AppTagVariant.gold),
            ),
          ),
        for (final day in plan.days) _buildDayCard(day),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Text(
            'Sessions run in order and repeat as a rotation. Start on any '
            'day. Days you do not train count as rest, and rest never '
            'blocks your next session.',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ),
        if (_confirmError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              _confirmError!,
              style: AppTypography.caption.copyWith(color: AppColors.orange),
            ),
          ),
      ],
    );
  }

  Widget _buildTrackingSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          key: const Key('onboarding-tracking-summary'),
          featured: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Start with any workout',
                style: AppTypography.h2.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Empty workouts, saved workouts, walks, and runs all live in '
                'Today. Pick a focus and Mova suggests exercises as you go.',
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Text(
            'History, streaks, steps, and progress still work without a '
            'rotation. You can create one from Plan whenever you want.',
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ),
        if (_confirmError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              _confirmError!,
              style: AppTypography.caption.copyWith(color: AppColors.orange),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final plan = _plan;
    final tracking = !draft.planEnabled;
    final busy = _loading || _confirming;
    return OnboardingScaffold(
      title: tracking ? 'Your Mova' : 'Your plan',
      subtitle: _subtitle(draft),
      currentStep: 11,
      onBack: _back,
      onContinue: _confirm,
      continueEnabled: tracking || (plan != null && !_loading),
      continueLabel: tracking ? 'Begin your Mova' : 'Start using Mova',
      isBusy: busy,
      onSkip: _editSchedule,
      skipLabel: 'Edit schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (tracking)
            _buildTrackingSummary()
          else if (_loading)
            _buildLoading()
          else if (_failure != null)
            _buildFailure()
          else if (plan != null)
            _buildPlanList(plan),
        ],
      ),
    );
  }
}
