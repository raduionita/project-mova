import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../models/app_settings.dart';

/// Callback used to read the step total for a local day.
typedef StepReader = Future<int?> Function(DateTime start, DateTime end);

/// Health platform access for Apple Health and Health Connect.
///
/// The package is isolated behind this service so widget tests, web builds,
/// and unsupported devices never touch a platform channel. Every call fails
/// soft and returns an unavailable or empty result instead of throwing.
class HealthService {
  HealthService({
    TargetPlatform? platform,
    this.availabilityCheck,
    this.permissionRequester,
    this.permissionCheck,
    this.stepReader,
  }) : _platform = platform ?? defaultTargetPlatform;

  final TargetPlatform _platform;
  final Future<bool> Function()? availabilityCheck;
  final Future<bool> Function()? permissionRequester;
  final Future<bool?> Function()? permissionCheck;
  final StepReader? stepReader;

  Health? _client;
  bool _configured = false;

  HealthProvider get provider {
    switch (_platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return HealthProvider.appleHealth;
      case TargetPlatform.android:
        return HealthProvider.healthConnect;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return HealthProvider.unavailable;
    }
  }

  Future<bool> isAvailable() async {
    final check = availabilityCheck;
    if (check != null) {
      try {
        return await check();
      } catch (_) {
        return false;
      }
    }
    if (kIsWeb) {
      return false;
    }
    if (_platform == TargetPlatform.iOS) {
      return _health.isDataTypeAvailable(HealthDataType.STEPS);
    }
    if (_platform == TargetPlatform.android) {
      try {
        return await _health.isHealthConnectAvailable();
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<bool> requestPermission() async {
    if (!await isAvailable()) {
      return false;
    }
    final requester = permissionRequester;
    if (requester != null) {
      try {
        return await requester();
      } catch (_) {
        return false;
      }
    }
    try {
      await _configure();
      return await _health.requestAuthorization(
        <HealthDataType>[HealthDataType.STEPS],
        permissions: <HealthDataAccess>[HealthDataAccess.READ],
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    final check = permissionCheck;
    if (check != null) {
      try {
        return await check() ?? false;
      } catch (_) {
        return false;
      }
    }
    try {
      final result = await _health.hasPermissions(
        <HealthDataType>[HealthDataType.STEPS],
        permissions: <HealthDataAccess>[HealthDataAccess.READ],
      );
      // Apple Health cannot disclose read authorization, so a null result
      // means the user must be treated as connected once they granted it.
      return result ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<int?> readSteps(DateTime start, DateTime end) async {
    if (end.isBefore(start)) {
      return null;
    }
    final reader = stepReader;
    if (reader != null) {
      try {
        return await reader(start, end);
      } catch (_) {
        return null;
      }
    }
    try {
      await _configure();
      return await _health.getTotalStepsInInterval(start, end);
    } catch (_) {
      return null;
    }
  }

  Health get _health => _client ??= Health();

  Future<void> _configure() async {
    if (_configured) {
      return;
    }
    await _health.configure();
    _configured = true;
  }
}
