import '../models/app_settings.dart';

/// Health platform access. Web builds use this implementation and report an
/// unavailable integration.
class HealthService {
  const HealthService();

  HealthProvider get provider => HealthProvider.unavailable;

  Future<bool> isAvailable() async => false;

  Future<bool> requestPermission() async => false;

  Future<bool> hasPermission() async => false;

  Future<int?> readSteps(DateTime start, DateTime end) async => null;
}
