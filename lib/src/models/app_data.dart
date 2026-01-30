import 'package:flutter/material.dart';

import 'break_interval.dart';
import 'day_entry.dart';
import '../utils/break_utils.dart';
import '../utils/format_utils.dart';
import '../utils/theme_utils.dart';
import '../utils/time_utils.dart';

const Object _unset = Object();

class AppData {
  AppData({
    required this.targetMinutes,
    required this.startTime,
    required this.breaks,
    required this.entries,
    required this.localeCode,
    required this.backgroundId,
    required this.notifyEnabled,
    required this.notifyMinutesBefore,
    required this.themeMode,
    required this.seedColor,
  });

  static const int defaultSeedColor = 0xFF168377;
  static final int defaultTargetMinutes =
      parseDecimalHoursToMinutes('8.4', allowZero: false) ?? 504;

  final int targetMinutes;
  final TimeOfDay? startTime;
  final List<BreakInterval> breaks;
  final Map<String, DayEntry> entries;
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
      breaks: const <BreakInterval>[],
      entries: <String, DayEntry>{},
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
    List<BreakInterval>? breaks,
    Map<String, DayEntry>? entries,
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
      breaks: breaks ?? cloneBreaks(this.breaks),
      entries: entries ?? Map<String, DayEntry>.from(this.entries),
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
      breaks: breaks,
      entries: entries,
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
      'localeCode': localeCode,
      'backgroundId': backgroundId,
      'notifyEnabled': notifyEnabled,
      'notifyMinutesBefore': notifyMinutesBefore,
      'themeMode': themeModeToString(themeMode),
      'seedColor': seedColor,
    };
  }
}
