import 'package:flutter/services.dart';

/// Platform haptics for workout feedback.
///
/// Haptics are supplementary: unsupported platforms fail silently, and
/// reduced-motion users get no vibration while keeping every visual cue.
class HapticsService {
  const HapticsService();

  /// Light tap when a set is completed.
  Future<void> setCompleted({bool reduceMotion = false}) =>
      _run(HapticFeedback.lightImpact, reduceMotion: reduceMotion);

  /// Medium tap when the rest countdown reaches zero.
  Future<void> restFinished({bool reduceMotion = false}) =>
      _run(HapticFeedback.mediumImpact, reduceMotion: reduceMotion);

  /// Medium tap when the summary shows at least one new personal record.
  Future<void> personalRecord({bool reduceMotion = false}) =>
      _run(HapticFeedback.mediumImpact, reduceMotion: reduceMotion);

  Future<void> _run(
    Future<void> Function() feedback, {
    required bool reduceMotion,
  }) async {
    if (reduceMotion) {
      return;
    }
    try {
      await feedback();
    } catch (_) {
      // Haptics are best effort on every platform.
    }
  }
}
