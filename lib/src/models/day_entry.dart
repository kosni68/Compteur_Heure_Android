import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import 'break_interval.dart';
import '../utils/break_utils.dart';
import '../utils/time_utils.dart';

enum DayType {
  work,
  pause,
  conge,
  maladie,
  maladieEnfant,
  pont,
  recup,
}

DayType dayTypeFromString(String? raw) {
  switch (raw) {
    case 'conge':
      return DayType.conge;
    case 'pause':
      return DayType.pause;
    case 'maladie':
      return DayType.maladie;
    case 'maladieEnfant':
      return DayType.maladieEnfant;
    case 'pont':
      return DayType.pont;
    case 'recup':
      return DayType.recup;
    case 'work':
    default:
      return DayType.work;
  }
}

String dayTypeToString(DayType type) {
  switch (type) {
    case DayType.conge:
      return 'conge';
    case DayType.pause:
      return 'pause';
    case DayType.maladie:
      return 'maladie';
    case DayType.maladieEnfant:
      return 'maladieEnfant';
    case DayType.pont:
      return 'pont';
    case DayType.recup:
      return 'recup';
    case DayType.work:
    default:
      return 'work';
  }
}

String dayTypeLabel(DayType type, AppLocalizations l10n) {
  switch (type) {
    case DayType.conge:
      return l10n.dayTypeConge;
    case DayType.pause:
      return l10n.dayTypePause;
    case DayType.maladie:
      return l10n.dayTypeMaladie;
    case DayType.maladieEnfant:
      return l10n.dayTypeMaladieEnfant;
    case DayType.pont:
      return l10n.dayTypePont;
    case DayType.recup:
      return l10n.dayTypeRecup;
    case DayType.work:
    default:
      return l10n.dayTypeWork;
  }
}

bool isWorkDayType(DayType type) =>
    type == DayType.work || type == DayType.recup;

bool isTargetDayType(DayType type) => type == DayType.work;

Color colorForDayType(DayType type, ThemeData theme) {
  switch (type) {
    case DayType.conge:
      return Colors.orange;
    case DayType.pause:
      return Colors.amber;
    case DayType.maladie:
      return Colors.redAccent;
    case DayType.maladieEnfant:
      return Colors.purpleAccent;
    case DayType.pont:
      return Colors.indigo;
    case DayType.recup:
      return Colors.green;
    case DayType.work:
    default:
      return theme.colorScheme.primary;
  }
}

class DayEntry {
  DayEntry({
    required this.minutes,
    required this.type,
    this.startTime,
    this.endTime,
    List<BreakInterval>? breaks,
  }) : breaks = breaks ?? <BreakInterval>[];

  final int minutes;
  final DayType type;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final List<BreakInterval> breaks;

  DayEntry copyWith({
    int? minutes,
    DayType? type,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<BreakInterval>? breaks,
  }) {
    return DayEntry(
      minutes: minutes ?? this.minutes,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breaks: breaks ?? cloneBreaks(this.breaks),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minutes': minutes,
      'type': dayTypeToString(type),
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
    };
  }
}

DayEntry? dayEntryFromJson(dynamic raw) {
  if (raw is int) {
    return DayEntry(minutes: raw, type: DayType.work);
  }
  if (raw is double) {
    return DayEntry(minutes: raw.round(), type: DayType.work);
  }
  if (raw is String) {
    final minutes = int.tryParse(raw);
    if (minutes != null) {
      return DayEntry(minutes: minutes, type: DayType.work);
    }
  }
  if (raw is Map) {
    final rawMinutes = raw['minutes'];
    int? minutes;
    if (rawMinutes is int) {
      minutes = rawMinutes;
    } else if (rawMinutes is double) {
      minutes = rawMinutes.round();
    } else if (rawMinutes is String) {
      minutes = int.tryParse(rawMinutes);
    }
    minutes ??= 0;
    final type = dayTypeFromString(raw['type'] as String?);
    final startTime = raw['startTime'] is String
        ? timeFromStorage(raw['startTime'] as String)
        : null;
    final endTime = raw['endTime'] is String
        ? timeFromStorage(raw['endTime'] as String)
        : null;
    final breaks = breaksFromJson(raw['breaks']);
    return DayEntry(
      minutes: minutes,
      type: type,
      startTime: startTime,
      endTime: endTime,
      breaks: breaks,
    );
  }
  return null;
}
