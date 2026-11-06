import '../models/app_settings.dart';

/// Notification platform wrapper. Scheduling arrives in Phase 5, so the
/// default implementation reports availability and declines permission until
/// the plugin is wired in.
class NotificationService {
  const NotificationService({this.available = true});

  final bool available;

  Future<bool> isAvailable() async => available;

  /// Requests system permission. Returns true when reminders may be enabled.
  Future<bool> requestPermission() async => false;

  Future<void> scheduleReminders(AppSettings settings) async {}

  Future<void> cancelAll() async {}

  Future<void> reschedule(AppSettings settings) async {}
}
