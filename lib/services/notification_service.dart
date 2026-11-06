import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';

/// Notification platform wrapper for local workout reminders.
///
/// The plugin is created lazily so widget tests and web builds never touch a
/// platform channel unless reminders are actually used. Every call fails soft:
/// an unavailable plugin simply leaves reminders off.
class NotificationService {
  const NotificationService({this.available = true});

  final bool available;

  static const String _channelId = 'mova_workout_reminders';
  static const String _channelName = 'Workout reminders';
  static const String _channelDescription =
      'A short nudge before your planned workout.';

  Future<bool> isAvailable() async {
    if (!available || kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Requests system permission. Returns true when reminders may be enabled.
  Future<bool> requestPermission() async {
    if (!await isAvailable()) {
      return false;
    }
    try {
      final plugin = await _ensureInitialized();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.requestNotificationsPermission() ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> scheduleReminders(AppSettings settings) async {
    await reschedule(settings);
  }

  Future<void> cancelAll() async {
    if (!await isAvailable()) {
      return;
    }
    try {
      final plugin = await _ensureInitialized();
      await plugin.cancelAll();
    } catch (_) {
      // Reminders are optional and must never block app startup.
    }
  }

  /// Replaces every scheduled reminder with the current settings.
  Future<void> reschedule(AppSettings settings) async {
    if (!await isAvailable()) {
      return;
    }
    try {
      final plugin = await _ensureInitialized();
      await plugin.cancelAll();
      if (!settings.remindersEnabled || settings.reminderWeekdays.isEmpty) {
        return;
      }
      await _initializeTimezone();
      final now = tz.TZDateTime.now(tz.local);
      for (final weekday in settings.reminderWeekdays) {
        if (weekday < DateTime.monday || weekday > DateTime.sunday) {
          continue;
        }
        var scheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          settings.reminderHour,
          settings.reminderMinute,
        );
        while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        await plugin.zonedSchedule(
          id: _notificationId(weekday),
          title: 'Time to train',
          body: 'Your Mova workout is ready when you are.',
          scheduledDate: scheduled,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'workout-reminder',
        );
      }
    } catch (_) {
      // A denied or missing permission leaves reminders off.
    }
  }

  int _notificationId(int weekday) => 100 + weekday;

  Future<FlutterLocalNotificationsPlugin> _ensureInitialized() async {
    final existing = _plugin;
    if (existing != null && _initialized) {
      return existing;
    }
    final plugin = existing ?? FlutterLocalNotificationsPlugin();
    _plugin = plugin;
    if (!_initialized) {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    }
    return plugin;
  }

  Future<void> _initializeTimezone() async {
    if (_timezoneReady) {
      return;
    }
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // The default timezone is still usable for local schedule arithmetic.
    }
    _timezoneReady = true;
  }

  static FlutterLocalNotificationsPlugin? _plugin;
  static bool _initialized = false;
  static bool _timezoneReady = false;
}
