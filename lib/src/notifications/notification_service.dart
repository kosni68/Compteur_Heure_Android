import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../controller/app_controller.dart';
import '../data/app_storage.dart';
import '../localization/app_localizations.dart';
import '../models/app_data.dart';
import '../models/break_interval.dart';
import '../models/day_entry.dart';
import '../utils/break_utils.dart';
import '../utils/date_utils.dart';
import '../utils/locale_utils.dart';
import '../utils/time_utils.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.handleBackgroundNotificationResponse(response);
}

enum _PointageAction { start, end, pause }

class NotificationService {
  static const int _endReminderId = 1001;
  static const int _pauseReminderId = 1002;
  static const int _pointageForegroundId = 2001;
  static const String _pointageChannelId = 'pointage_foreground';
  static const String _pauseChannelId = 'pause_reminder';
  static const String _actionStartId = 'action_pointage_start';
  static const String _actionEndId = 'action_pointage_end';
  static const String _actionPauseId = 'action_pointage_pause';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static AppController? _controller;
  static bool _initialized = false;
  static Future<void>? _initFuture;
  static bool _permissionRequested = false;
  static bool _timezoneReady = false;

  static void bindController(AppController controller) {
    _controller = controller;
  }

  static Future<void> init() {
    if (_initialized) {
      return Future.value();
    }
    _initFuture ??= _initInternal();
    return _initFuture!;
  }

  static Future<void> _initInternal() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _initialized = true;
  }

  static Future<void> requestNotificationsPermission() async {
    if (_permissionRequested) {
      return;
    }
    await init();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {
      // Ignore permission request failures (e.g. no activity attached).
    }
    _permissionRequested = true;
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

  static Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
    final action = _actionFromResponse(response);
    if (action == null) {
      return;
    }
    await _handlePointageAction(action, controller: _controller);
  }

  static Future<void> handleBackgroundNotificationResponse(
    NotificationResponse response,
  ) async {
    final action = _actionFromResponse(response);
    if (action == null) {
      return;
    }
    await _handlePointageAction(action);
  }

  static _PointageAction? _actionFromResponse(NotificationResponse response) {
    switch (response.actionId) {
      case _actionStartId:
        return _PointageAction.start;
      case _actionEndId:
        return _PointageAction.end;
      case _actionPauseId:
        return _PointageAction.pause;
      default:
        return null;
    }
  }

  static Future<void> _handlePointageAction(
    _PointageAction action, {
    AppController? controller,
  }) async {
    final now = DateTime.now();
    AppData data;
    if (controller != null) {
      data = controller.data;
    } else {
      data = await AppStorage().load();
    }

    final update = _applyPointageAction(data, action, now);
    if (controller != null) {
      await controller.update(update.data);
    } else {
      await AppStorage().save(update.data);
    }

    final l10n = _l10nForData(update.data);
    if (update.cancelEndReminder) {
      await cancelEndReminder();
    }
    if (update.cancelPauseReminder) {
      await cancelPauseReminder();
    }
    if (update.schedulePauseReminder) {
      await schedulePauseReminder(
        minutes: update.data.pauseReminderMinutes,
        l10n: l10n,
      );
    }
    await updatePointageNotification(update.data, l10n);
  }

  static AppLocalizations _l10nForData(AppData data) {
    Locale locale;
    if (data.localeCode == 'system') {
      locale = PlatformDispatcher.instance.locale;
    } else {
      locale = localeFromCode(data.localeCode) ?? const Locale('fr', 'FR');
    }
    return AppLocalizations(locale);
  }

  static Future<void> updatePointageNotification(
    AppData data,
    AppLocalizations l10n,
  ) async {
    await init();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) {
      return;
    }

    final startTime = data.startTime;
    final endTime = data.endTime;
    final pauseStartTime = data.pauseStartTime;
    final trackingDayKey = data.trackingDayKey;
    final todayKey = dateKey(dateOnly(DateTime.now()));
    final hasTracking = trackingDayKey != null && startTime != null;
    final isTrackingDay = trackingDayKey == todayKey;
    final hasEnded = hasTracking && endTime != null;
    final isActive = hasTracking && isTrackingDay && !hasEnded;
    final isPaused = isActive && pauseStartTime != null;

    final bool showEndAction = isActive && !isPaused;
    final mainActionId = showEndAction ? _actionEndId : _actionStartId;
    final mainActionLabel =
        showEndAction ? l10n.pointageActionEnd : l10n.pointageActionStart;
    final mainActionIcon = showEndAction
        ? const DrawableResourceAndroidBitmap('ic_pointage_end')
        : const DrawableResourceAndroidBitmap('ic_pointage_start');
    const pauseActionIcon =
        DrawableResourceAndroidBitmap('ic_pointage_pause');

    String title;
    String body;
    if (!hasTracking || !isTrackingDay) {
      title = l10n.pointageNotificationTitleIdle;
      body = l10n.pointageNotificationBodyIdle;
    } else if (hasEnded) {
      title = l10n.pointageNotificationTitleEnded;
      body = l10n.pointageNotificationBodyEnded(formatTimeOfDay(endTime));
    } else if (isPaused) {
      title = l10n.pointageNotificationTitlePaused;
      body = l10n.pointageNotificationBodyPaused(
        formatTimeOfDay(pauseStartTime),
      );
    } else {
      title = l10n.pointageNotificationTitleRunning;
      body = l10n.pointageNotificationBodyRunning(
        formatTimeOfDay(startTime),
      );
    }

    final actions = <AndroidNotificationAction>[
      AndroidNotificationAction(
        mainActionId,
        mainActionLabel,
        icon: mainActionIcon,
        showsUserInterface: false,
        cancelNotification: false,
      ),
      if (isActive)
        AndroidNotificationAction(
          _actionPauseId,
          l10n.pointageActionPause,
          icon: pauseActionIcon,
          showsUserInterface: false,
          cancelNotification: false,
        ),
    ];

    final androidDetails = AndroidNotificationDetails(
      _pointageChannelId,
      l10n.pointageNotificationChannelName,
      channelDescription: l10n.pointageNotificationChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.transport,
      styleInformation: const MediaStyleInformation(),
      actions: actions,
    );
    await androidPlugin.startForegroundService(
      _pointageForegroundId,
      title,
      body,
      notificationDetails: androidDetails,
      foregroundServiceTypes: {
        AndroidServiceForegroundType.foregroundServiceTypeDataSync,
      },
    );
  }

  static Future<void> updatePointageNotificationFromData(
    AppData data,
  ) async {
    await updatePointageNotification(data, _l10nForData(data));
  }

  static Future<void> schedulePauseReminder({
    required int minutes,
    required AppLocalizations l10n,
  }) async {
    await init();
    await _ensureTimeZone();
    await cancelPauseReminder();
    if (minutes <= 0) {
      return;
    }
    final scheduledTime = DateTime.now().add(Duration(minutes: minutes));

    final androidDetails = AndroidNotificationDetails(
      _pauseChannelId,
      l10n.pauseReminderChannelName,
      channelDescription: l10n.pauseReminderChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidPlugin?.canScheduleExactNotifications();
    final scheduleMode = canExact == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;
    await _plugin.zonedSchedule(
      _pauseReminderId,
      l10n.pauseReminderNotificationTitle,
      l10n.pauseReminderNotificationBody,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelPauseReminder() async {
    await init();
    await _plugin.cancel(_pauseReminderId);
  }

  static Future<void> scheduleEndReminder({
    required DateTime estimatedEnd,
    required int minutesBefore,
    required AppLocalizations l10n,
  }) async {
    await init();
    await _ensureTimeZone();
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

  static _PointageUpdate _applyPointageAction(
    AppData data,
    _PointageAction action,
    DateTime now,
  ) {
    final nowTime = TimeOfDay.fromDateTime(now);
    final todayKey = dateKey(dateOnly(now));

    var trackingDayKey = data.trackingDayKey;
    var startTime = data.startTime;
    var endTime = data.endTime;
    var pauseStartTime = data.pauseStartTime;
    var breaks = cloneBreaks(data.breaks);
    var entries = Map<String, DayEntry>.from(data.entries);

    if (trackingDayKey == null && startTime != null && endTime == null) {
      trackingDayKey = todayKey;
    }

    final hasStarted = startTime != null;
    final hasEnded = endTime != null;
    final isActive = hasStarted && !hasEnded;
    final isPaused = isActive && pauseStartTime != null;
    final sameDay = trackingDayKey == todayKey;

    var schedulePauseReminder = false;
    var cancelPauseReminder = false;
    var cancelEndReminder = false;
    var removeEntry = false;

    switch (action) {
      case _PointageAction.start:
        if (!hasStarted || (!isActive && !sameDay)) {
          startTime = nowTime;
          endTime = null;
          pauseStartTime = null;
          breaks = <BreakInterval>[];
          trackingDayKey = todayKey;
          cancelPauseReminder = true;
        } else if (hasEnded && sameDay && endTime != null) {
          breaks.add(BreakInterval(start: endTime, end: nowTime));
          endTime = null;
          pauseStartTime = null;
          removeEntry = true;
          cancelPauseReminder = true;
        } else if (isPaused && pauseStartTime != null) {
          breaks.add(BreakInterval(start: pauseStartTime, end: nowTime));
          pauseStartTime = null;
          cancelPauseReminder = true;
        }
        break;
      case _PointageAction.pause:
        if (isActive && !isPaused) {
          pauseStartTime = nowTime;
          schedulePauseReminder = true;
        }
        break;
      case _PointageAction.end:
        if (!hasStarted) {
          break;
        }
        if (pauseStartTime != null) {
          breaks.add(BreakInterval(start: pauseStartTime, end: nowTime));
          pauseStartTime = null;
        }
        endTime = nowTime;
        trackingDayKey ??= todayKey;
        cancelPauseReminder = true;
        cancelEndReminder = true;
        break;
    }

    if (removeEntry && trackingDayKey != null) {
      entries.remove(trackingDayKey);
    }

    if (action == _PointageAction.end &&
        startTime != null &&
        endTime != null &&
        trackingDayKey != null) {
      final baseDate = dateFromKey(trackingDayKey) ?? dateOnly(now);
      final workedMinutes = _computeWorkedMinutes(
        baseDate,
        startTime,
        endTime,
        breaks,
      );
      if (workedMinutes != null) {
        entries[trackingDayKey] = DayEntry(
          minutes: workedMinutes,
          type: DayType.work,
          startTime: startTime,
          endTime: endTime,
          breaks: cloneBreaks(breaks),
        );
      }
    }

    final updated = data.copyWith(
      startTime: startTime,
      endTime: endTime,
      breaks: breaks,
      trackingDayKey: trackingDayKey,
      pauseStartTime: pauseStartTime,
      entries: entries,
    );

    return _PointageUpdate(
      data: updated,
      schedulePauseReminder: schedulePauseReminder,
      cancelPauseReminder: cancelPauseReminder,
      cancelEndReminder: cancelEndReminder,
    );
  }

  static int? _computeWorkedMinutes(
    DateTime baseDate,
    TimeOfDay start,
    TimeOfDay end,
    List<BreakInterval> breaks,
  ) {
    final startDate = _dateTimeFromTimeOfDay(baseDate, start);
    var endDate = _dateTimeFromTimeOfDay(baseDate, end);
    if (endDate.isBefore(startDate)) {
      endDate = endDate.add(const Duration(days: 1));
    }

    final breakIntervals = _normalizeBreaks(baseDate, startDate, breaks);

    Duration totalBreak = Duration.zero;
    for (final interval in breakIntervals) {
      if (interval.start.isBefore(endDate)) {
        final effectiveEnd =
            interval.end.isAfter(endDate) ? endDate : interval.end;
        if (effectiveEnd.isAfter(interval.start)) {
          totalBreak += effectiveEnd.difference(interval.start);
        }
      }
    }

    final presence = endDate.difference(startDate);
    final worked = presence - totalBreak;
    if (worked.inMinutes <= 0) {
      return null;
    }
    return worked.inMinutes;
  }

  static List<_BreakIntervalDateTime> _normalizeBreaks(
    DateTime baseDate,
    DateTime start,
    List<BreakInterval> breaks,
  ) {
    final normalized = <_BreakIntervalDateTime>[];
    DateTime cursor = start;
    for (final breakItem in breaks) {
      DateTime breakStart = _dateTimeFromTimeOfDay(baseDate, breakItem.start);
      while (breakStart.isBefore(cursor)) {
        breakStart = breakStart.add(const Duration(days: 1));
      }
      DateTime breakEnd = _dateTimeFromTimeOfDay(baseDate, breakItem.end);
      while (breakEnd.isBefore(breakStart)) {
        breakEnd = breakEnd.add(const Duration(days: 1));
      }
      normalized.add(_BreakIntervalDateTime(breakStart, breakEnd));
      cursor = breakEnd;
    }
    return normalized;
  }

  static DateTime _dateTimeFromTimeOfDay(DateTime base, TimeOfDay time) {
    return DateTime(base.year, base.month, base.day, time.hour, time.minute);
  }
}

class _PointageUpdate {
  const _PointageUpdate({
    required this.data,
    this.schedulePauseReminder = false,
    this.cancelPauseReminder = false,
    this.cancelEndReminder = false,
  });

  final AppData data;
  final bool schedulePauseReminder;
  final bool cancelPauseReminder;
  final bool cancelEndReminder;
}

class _BreakIntervalDateTime {
  const _BreakIntervalDateTime(this.start, this.end);

  final DateTime start;
  final DateTime end;
}
