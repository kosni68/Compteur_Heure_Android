import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../localization/app_localizations.dart';
import '../utils/time_utils.dart';

class NotificationService {
  static const int _endReminderId = 1001;
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _timezoneReady = false;

  static Future<void> init() async {
    if (_initialized) {
      return;
    }
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await _ensureTimeZone();
    _initialized = true;
  }

  static Future<void> _ensureTimeZone() async {
    if (_timezoneReady) {
      return;
    }
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      // Keep default tz.local if lookup fails.
    }
    _timezoneReady = true;
  }

  static Future<void> scheduleEndReminder({
    required DateTime estimatedEnd,
    required int minutesBefore,
    required AppLocalizations l10n,
  }) async {
    await init();
    await cancelEndReminder();
    if (minutesBefore <= 0) {
      return;
    }
    final scheduledTime =
        estimatedEnd.subtract(Duration(minutes: minutesBefore));
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'end_reminder',
      'Rappel fin de journee',
      channelDescription: 'Notification avant la fin estimee',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    final timeLabel = formatTime(estimatedEnd);
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidPlugin?.canScheduleExactNotifications();
    final scheduleMode = canExact == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;
    await _plugin.zonedSchedule(
      _endReminderId,
      l10n.notificationTitle,
      l10n.notificationBody(timeLabel),
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelEndReminder() async {
    await init();
    await _plugin.cancel(_endReminderId);
  }
}
