import 'dart:async';

import 'package:flutter/material.dart';

import '../services/clock.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Rest countdown driven by an absolute end time so background time is
/// accounted for when the app resumes.
class RestTimerBanner extends StatefulWidget {
  const RestTimerBanner({
    super.key,
    required this.endsAt,
    required this.totalSeconds,
    required this.onSkip,
    this.onFinished,
    this.clock,
  });

  final DateTime endsAt;
  final int totalSeconds;
  final VoidCallback onSkip;
  final VoidCallback? onFinished;
  final Clock? clock;

  @override
  State<RestTimerBanner> createState() => _RestTimerBannerState();
}

class _RestTimerBannerState extends State<RestTimerBanner>
    with WidgetsBindingObserver {
  late final Clock _clock = widget.clock ?? const SystemClock();
  Timer? _ticker;
  int _remaining = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remaining = _remainingSeconds();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant RestTimerBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt ||
        oldWidget.totalSeconds != widget.totalSeconds) {
      _finished = false;
      _remaining = _remainingSeconds();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  int _remainingSeconds() {
    final milliseconds = widget.endsAt.difference(_clock.now()).inMilliseconds;
    return (milliseconds / 1000).ceil().clamp(0, widget.totalSeconds);
  }

  void _tick() {
    if (!mounted || _finished) {
      return;
    }
    final remaining = _remainingSeconds();
    if (remaining <= 0) {
      _ticker?.cancel();
      _finished = true;
      if (_remaining != 0) {
        setState(() => _remaining = 0);
      }
      widget.onFinished?.call();
      return;
    }
    if (remaining != _remaining) {
      setState(() => _remaining = remaining);
    }
  }

  String _formatRemaining() {
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.totalSeconds <= 0 ? 1 : widget.totalSeconds;
    final fraction = (_remaining / total).clamp(0.0, 1.0);
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Rest timer',
      value: '$_remaining seconds remaining',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.restBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Rest · ${_formatRemaining()}',
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    minimumSize: const Size(0, AppSpacing.x5l),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    textStyle: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.xs),
              child: SizedBox(
                height: AppSpacing.xs,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    const ColoredBox(color: AppColors.restTrack),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: const ColoredBox(color: AppColors.blue),
                    ),
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
