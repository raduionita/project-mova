import 'dart:async';

import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake during an active workout without making widget tests
/// depend on platform channels.
///
/// Platform calls are best effort and never block the caller: a missing plugin
/// or a test binding that never answers must not stall workout navigation.
class KeepAwakeService {
  const KeepAwakeService();

  Future<void> enable() {
    _dispatch(WakelockPlus.enable);
    return Future<void>.value();
  }

  Future<void> disable() {
    _dispatch(WakelockPlus.disable);
    return Future<void>.value();
  }

  void _dispatch(Future<void> Function() action) {
    try {
      unawaited(action().catchError((Object _) {}));
    } catch (_) {
      // Unsupported platforms and tests simply keep their normal sleep policy.
    }
  }
}
