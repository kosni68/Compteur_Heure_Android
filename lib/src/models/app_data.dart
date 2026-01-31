import 'package:flutter/material.dart';

import 'break_interval.dart';
import 'day_entry.dart';
import 'pause_reminder_type.dart';
import '../utils/break_utils.dart';
import '../utils/format_utils.dart';
import '../utils/theme_utils.dart';
import '../utils/time_utils.dart';

const Object _unset = Object();

class AppData {
  AppData({
    required this.targetMinutes,
    required this.startTime,
    required this.endTime,
    required this.breaks,
    required this.entries,
    required this.trackingDayKey,
    required this.pauseStartTime,
    required this.pauseReminderMinutes,
    required this.pauseReminderType,
    required this.localeCode,
    required this.backgroundId,
    required this.notifyEnabled,
    required this.notifyMinutesBefore,
    required this.themeMode,
    required this.seedColor,
  });

  static const int defaultSeedColor = 0xFF168377;
  static const int defaultPauseReminderMinutes = 30;
  static final int defaultTargetMinutes =
      parseDecimalHoursToMinutes('8.4', allowZero: false) ?? 504;

  final int targetMinutes;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<BreakInterval> breaks;
  final Map<String, DayEntry> entries;
  final String? trackingDayKey;
  final TimeOfDay? pauseStartTime;
  final int pauseReminderMinutes;
  final PauseReminderType pauseReminderType;
  final String localeCode;
  final String backgroundId;
  final bool notifyEnabled;
  final int notifyMinutesBefore;
  final ThemeMode themeMode;
  final int seedColor;

  factory AppData.initial() {
    return AppData(
      targetMinutes: defaultTargetMinutes,
      startTime: null,
      endTime: null,
      breaks: const <BreakInterval>[],
      entries: <String, DayEntry>{},
      trackingDayKey: null,
      pauseStartTime: null,
      pauseReminderMinutes: defaultPauseReminderMinutes,
      pauseReminderType: PauseReminderType.notification,
      localeCode: 'fr',
      backgroundId: 'none',
      notifyEnabled: false,
      notifyMinutesBefore: 15,
      themeMode: ThemeMode.light,
      seedColor: defaultSeedColor,
    );
  }

  AppData copyWith({
    int? targetMinutes,
    Object? startTime = _unset,
    Object? endTime = _unset,
    List<BreakInterval>? breaks,
    Map<String, DayEntry>? entries,
    Object? trackingDayKey = _unset,
    Object? pauseStartTime = _unset,
    int? pauseReminderMinutes,
    PauseReminderType? pauseReminderType,
    String? localeCode,
    String? backgroundId,
    bool? notifyEnabled,
    int? notifyMinutesBefore,
    ThemeMode? themeMode,
    int? seedColor,
  }) {
    return AppData(
      targetMinutes: targetMinutes ?? this.targetMinutes,
      startTime: startTime == _unset ? this.startTime : startTime as TimeOfDay?,
      endTime: endTime == _unset ? this.endTime : endTime as TimeOfDay?,
      breaks: breaks ?? cloneBreaks(this.breaks),
      entries: entries ?? Map<String, DayEntry>.from(this.entries),
      trackingDayKey: trackingDayKey == _unset
          ? this.trackingDayKey
          : trackingDayKey as String?,
      pauseStartTime: pauseStartTime == _unset
          ? this.pauseStartTime
          : pauseStartTime as TimeOfDay?,
      pauseReminderMinutes: pauseReminderMinutes ?? this.pauseReminderMinutes,
      pauseReminderType: pauseReminderType ?? this.pauseReminderType,
      localeCode: localeCode ?? this.localeCode,
      backgroundId: backgroundId ?? this.backgroundId,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      notifyMinutesBefore: notifyMinutesBefore ?? this.notifyMinutesBefore,
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    final rawTarget = json['targetMinutes'];
    int targetMinutes;
    if (rawTarget is int) {
      targetMinutes = rawTarget;
    } else if (rawTarget is double) {
      targetMinutes = rawTarget.round();
    } else {
      final legacy = json['targetHours'];
      targetMinutes = parseDecimalHoursToMinutes(
            legacy?.toString() ?? '',
            allowZero: false,
          ) ??
          defaultTargetMinutes;
    }

    final rawStart = json['startTime'];
    final startTime = rawStart is String ? timeFromStorage(rawStart) : null;
    final rawEnd = json['endTime'];
    final endTime = rawEnd is String ? timeFromStorage(rawEnd) : null;

    final rawBreaks = json['breaks'];
    final breaks = breaksFromJson(rawBreaks);

    final rawEntries = json['entries'];
    final entries = <String, DayEntry>{};
    if (rawEntries is Map) {
      rawEntries.forEach((key, value) {
        if (key is! String) {
          return;
        }
        final entry = dayEntryFromJson(value);
        if (entry != null) {
          entries[key] = entry;
        }
      });
    }

    final localeCode = (json['localeCode'] as String?) ?? 'fr';
    final backgroundId = (json['backgroundId'] as String?) ?? 'none';
    final trackingDayKey = json['trackingDayKey'] as String?;
    final rawPauseStart = json['pauseStartTime'];
    final pauseStartTime =
        rawPauseStart is String ? timeFromStorage(rawPauseStart) : null;
    final pauseReminderMinutes = (json['pauseReminderMinutes'] is int)
        ? json['pauseReminderMinutes'] as int
        : defaultPauseReminderMinutes;
    final pauseReminderType =
        pauseReminderTypeFromString(json['pauseReminderType'] as String?);
    final notifyEnabled = (json['notifyEnabled'] as bool?) ?? false;
    final notifyMinutesBefore = (json['notifyMinutesBefore'] is int)
        ? json['notifyMinutesBefore'] as int
        : 15;
    final themeMode = themeModeFromString(json['themeMode'] as String?);
    final rawSeed = json['seedColor'];
    final seedColor = rawSeed is int ? rawSeed : defaultSeedColor;

    return AppData(
      targetMinutes: targetMinutes,
      startTime: startTime,
      endTime: endTime,
      breaks: breaks,
      entries: entries,
      trackingDayKey: trackingDayKey,
      pauseStartTime: pauseStartTime,
      pauseReminderMinutes: pauseReminderMinutes,
      pauseReminderType: pauseReminderType,
      localeCode: localeCode,
      backgroundId: backgroundId,
      notifyEnabled: notifyEnabled,
      notifyMinutesBefore: notifyMinutesBefore,
      themeMode: themeMode,
      seedColor: seedColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetMinutes': targetMinutes,
      'startTime': startTime == null ? null : timeToStorage(startTime!),
      'endTime': endTime == null ? null : timeToStorage(endTime!),
      'breaks': breaks
          .map(
            (breakItem) => {
              'start': timeToStorage(breakItem.start),
              'end': timeToStorage(breakItem.end),
            },
          )
          .toList(),
      'entries': entries.map(
        (key, value) => MapEntry<String, dynamic>(key, value.toJson()),
      ),
      'trackingDayKey': trackingDayKey,
      'pauseStartTime':
          pauseStartTime == null ? null : timeToStorage(pauseStartTime!),
      'pauseReminderMinutes': pauseReminderMinutes,
      'pauseReminderType': pauseReminderTypeToString(pauseReminderType),
      'localeCode': localeCode,
      'backgroundId': backgroundId,
      'notifyEnabled': notifyEnabled,
      'notifyMinutesBefore': notifyMinutesBefore,
      'themeMode': themeModeToString(themeMode),
      'seedColor': seedColor,
    };
  }
}
