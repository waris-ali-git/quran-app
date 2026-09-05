import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    // flutter_local_notifications is only supported on Android/iOS/macOS.
    // Windows and Linux are unsupported — skip silently.
    if (!_isSupportedPlatform) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(initSettings);

      // Request permissions on Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      debugPrint('⚠️ NotificationService.init failed: $e');
    }
  }

  /// True only on platforms that support flutter_local_notifications
  bool get _isSupportedPlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool enabled = prefs.getBool('enable_adhan_notifications') ?? true;
      if (!enabled) {
        await _notificationsPlugin.cancel(id);
        return;
      }

      // If the time has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(DateTime.now())) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'azaan_channel_v1',
            'Adhan Prayer Notifications',
            channelDescription: 'Notifications for daily prayers with custom Azaan audio',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('azaan'),
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('⚠️ schedulePrayerNotification failed: $e');
    }
  }

  Future<void> cancelPrayerNotifications() async {
    if (!_initialized) return;
    try {
      for (int i = 0; i < 6; i++) {
        await _notificationsPlugin.cancel(i);
      }
    } catch (e) {
      debugPrint('⚠️ cancelPrayerNotifications failed: $e');
    }
  }

  Future<void> scheduleInactivityReminder() async {
    if (!_initialized) return;

    try {
      // Cancel any existing 20-hour reminder
      await _notificationsPlugin.cancel(999);

      final scheduledTime = DateTime.now().add(const Duration(hours: 20));

      await _notificationsPlugin.zonedSchedule(
        999,
        'Time for Worship',
        'It has been 20 hours since you last opened the app. Take a moment to remember Allah.',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'App Reminders',
            channelDescription: 'Reminders when the app is inactive',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('⚠️ scheduleInactivityReminder failed: $e');
    }
  }

  Future<void> showTestNotification() async {
    if (!_initialized) return;
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'For testing purposes',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        888,
        'Test Notification',
        'Mubarak ho! Notifications theek se kaam kar rahi hain. ✨',
        details,
      );
    } catch (e) {
      debugPrint('⚠️ showTestNotification failed: $e');
    }
  }
}
