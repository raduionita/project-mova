import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/formatters.dart';
import '../../app_coordinator.dart';
import '../../models/unit_preferences.dart';
import '../../models/workout_session.dart';
import '../../navigation/routes.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/clock.dart';
import '../../services/unit_conversion_service.dart';
import '../../services/workout_calculator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_back_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_tag.dart';
import '../../widgets/numeric_input_sheet.dart';
import '../summary/summary_screen.dart';

/// Timer-based run with an optional manually entered distance.
class RunScreen extends StatefulWidget {
  const RunScreen({super.key, this.clock});

  final Clock? clock;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  static const UnitConversionService _units = UnitConversionService();

  Timer? _ticker;
  bool _finishing = false;

  DateTime get _now => (widget.clock ?? const SystemClock()).now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final workout = context.read<WorkoutProvider>();
    final started = await workout.startRun();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(workout.error ?? 'Could not start the run.')),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePause(WorkoutSession session) async {
    final workout = context.read<WorkoutProvider>();
    final paused = session.status == SessionStatus.paused;
    final changed = paused ? await workout.resume() : await workout.pause();
    if (!changed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(workout.error ?? 'Could not update the run.'),
        ),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _finish(WorkoutSession session) async {
    if (_finishing) {
      return;
    }
    final preferences = context
        .read<SettingsProvider>()
        .settings
        .unitPreferences;
    final distanceUnit = preferences.distanceUnit;
    final currentMeters = session.distanceMeters ?? 0.0;
    final value = await showNumericInputSheet(
      context,
      title: 'Distance',
      label: 'Distance (${_units.distanceLabel(distanceUnit)})',
      initialValue: currentMeters <= 0
          ? 0
          : (distanceUnit == DistanceUnit.km
                ? currentMeters / 1000
                : _units.kmToMi(currentMeters / 1000)),
      allowDecimal: true,
      max: 1000,
      helperText: 'Optional. Leave at 0 if you did not track distance.',
    );
    if (value == null || !mounted) {
      return;
    }
    setState(() => _finishing = true);
    final workout = context.read<WorkoutProvider>();
    final km = distanceUnit == DistanceUnit.km
        ? value
        : _units.miToKm(value);
    await workout.setDistance(km <= 0 ? null : km * 1000);
    if (!mounted) {
      return;
    }
    final coordinator = context.read<AppCoordinator>();
    final result = await coordinator.finishWorkout();
    if (!mounted) {
      return;
    }
    setState(() => _finishing = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not finish the run.')),
      );
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      Routes.summary,
      arguments: SummaryArgs(session: result.session, records: result.records),
    );
  }

  Widget _buildHeader() {
    return const AppBackBar(label: 'Today');
  }

  Widget _buildTimer(WorkoutSession session) {
    final seconds = WorkoutCalculator.sessionDurationSeconds(session, _now);
    final paused = session.status == SessionStatus.paused;
    return AppCard(
      featured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Run',
                style: AppTypography.h2.copyWith(color: AppColors.text),
              ),
              const Spacer(),
              AppTag(
                label: paused ? 'Paused' : 'Running',
                variant: paused ? AppTagVariant.gold : AppTagVariant.lime,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2l),
          Text(
            formatDuration(seconds),
            key: const Key('run-timer'),
            textAlign: TextAlign.center,
            style: AppTypography.metric.copyWith(
              color: AppColors.text,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            paused
                ? 'Timer paused. Resume when you are ready.'
                : 'Keep the phone with you. Distance is added when you finish.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildDistance(WorkoutSession session) {
    final distance = session.distanceMeters;
    final unit = context
        .watch<SettingsProvider>()
        .settings
        .unitPreferences
        .distanceUnit;
    return Row(
      children: <Widget>[
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppIcon(
                  asset: AppIcons.run,
                  color: AppColors.blue,
                  size: 20,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Distance',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  distance == null || distance <= 0
                      ? '--'
                      : _units.displayDistance(distance / 1000, unit),
                  key: const Key('run-distance'),
                  style: AppTypography.title.copyWith(color: AppColors.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(WorkoutSession session) {
    final paused = session.status == SessionStatus.paused;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(
          key: const Key('run-toggle-pause'),
          label: paused ? 'Resume run' : 'Pause run',
          assetIcon: paused ? AppIcons.play : AppIcons.pause,
          variant: AppButtonVariant.ghost,
          onPressed: _finishing ? null : () => _togglePause(session),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const Key('run-finish'),
          label: _finishing ? 'Finishing...' : 'Finish run',
          assetIcon: AppIcons.check,
          onPressed: _finishing ? null : () => _finish(session),
        ),
      ],
    );
  }

  Widget _buildActive(WorkoutSession session) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildTimer(session),
          const SizedBox(height: AppSpacing.md),
          _buildDistance(session),
          const SizedBox(height: AppSpacing.x2l),
          _buildActions(session),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const AppIcon(
                  asset: AppIcons.run,
                  color: AppColors.blue,
                  size: 24,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ready for a run?',
                  style: AppTypography.h2.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Start the timer, then add distance when you finish. '
                  'No GPS is used.',
                  style: AppTypography.body.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x2l),
          AppButton(
            key: const Key('run-start'),
            label: 'Start run',
            assetIcon: AppIcons.play,
            onPressed: _start,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkoutProvider>().activeSession;
    final activeRun = session != null && session.source == SessionSource.run;
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
              _buildHeader(),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: activeRun ? _buildActive(session) : _buildEmpty(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
