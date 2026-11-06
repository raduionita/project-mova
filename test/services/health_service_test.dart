import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mova/models/app_settings.dart';
import 'package:mova/services/health_service.dart';

void main() {
  group('HealthService provider', () {
    test('maps Apple platforms to Apple Health', () {
      expect(
        HealthService(platform: TargetPlatform.iOS).provider,
        HealthProvider.appleHealth,
      );
      expect(
        HealthService(platform: TargetPlatform.macOS).provider,
        HealthProvider.appleHealth,
      );
    });

    test('maps Android to Health Connect', () {
      expect(
        HealthService(platform: TargetPlatform.android).provider,
        HealthProvider.healthConnect,
      );
    });

    test('maps desktop platforms to unavailable', () {
      expect(
        HealthService(platform: TargetPlatform.linux).provider,
        HealthProvider.unavailable,
      );
    });
  });

  group('HealthService availability', () {
    test('uses the injected availability callback', () async {
      final service = HealthService(
        platform: TargetPlatform.android,
        availabilityCheck: () async => true,
      );
      expect(await service.isAvailable(), isTrue);
    });

    test('fails soft when the availability callback throws', () async {
      final service = HealthService(
        platform: TargetPlatform.android,
        availabilityCheck: () async => throw StateError('boom'),
      );
      expect(await service.isAvailable(), isFalse);
    });

    test('permission is denied when health is unavailable', () async {
      var requested = false;
      final service = HealthService(
        platform: TargetPlatform.android,
        availabilityCheck: () async => false,
        permissionRequester: () async {
          requested = true;
          return true;
        },
      );
      expect(await service.requestPermission(), isFalse);
      expect(requested, isFalse);
    });

    test('permission uses the injected requester when available', () async {
      final service = HealthService(
        platform: TargetPlatform.android,
        availabilityCheck: () async => true,
        permissionRequester: () async => true,
      );
      expect(await service.requestPermission(), isTrue);
    });

    test('permission fails soft when the requester throws', () async {
      final service = HealthService(
        platform: TargetPlatform.android,
        availabilityCheck: () async => true,
        permissionRequester: () async => throw StateError('denied'),
      );
      expect(await service.requestPermission(), isFalse);
    });

    test('permission check uses the injected callback', () async {
      final service = HealthService(
        permissionCheck: () async => true,
        stepReader: (_, _) async => 100,
      );
      expect(await service.hasPermission(), isTrue);
    });

    test('null permission result is treated as denied', () async {
      final service = HealthService(permissionCheck: () async => null);
      expect(await service.hasPermission(), isFalse);
    });
  });

  group('HealthService step reads', () {
    test('rejects an inverted interval without calling the reader', () async {
      var called = false;
      final service = HealthService(
        stepReader: (_, _) async {
          called = true;
          return 100;
        },
      );
      final start = DateTime(2026, 11, 6);
      final result = await service.readSteps(
        start,
        start.subtract(const Duration(days: 1)),
      );
      expect(result, isNull);
      expect(called, isFalse);
    });

    test('passes the local day boundaries to the reader', () async {
      final start = DateTime(2026, 11, 6);
      final end = DateTime(2026, 11, 6, 12);
      final service = HealthService(
        stepReader: (from, to) async {
          expect(from, start);
          expect(to, end);
          return 8123;
        },
      );
      expect(await service.readSteps(start, end), 8123);
    });

    test('returns null when the reader throws', () async {
      final service = HealthService(
        stepReader: (_, _) async => throw StateError('no data'),
      );
      expect(
        await service.readSteps(DateTime(2026, 11, 6), DateTime(2026, 11, 7)),
        isNull,
      );
    });
  });
}
