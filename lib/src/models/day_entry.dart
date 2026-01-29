import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';

enum DayType {
  work,
  conge,
  maladie,
  pont,
  recup,
}

DayType dayTypeFromString(String? raw) {
  switch (raw) {
    case 'conge':
      return DayType.conge;
    case 'maladie':
      return DayType.maladie;
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
    case DayType.maladie:
      return 'maladie';
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
    case DayType.maladie:
      return l10n.dayTypeMaladie;
    case DayType.pont:
      return l10n.dayTypePont;
    case DayType.recup:
      return l10n.dayTypeRecup;
    case DayType.work:
    default:
      return l10n.dayTypeWork;
  }
}

bool isWorkDayType(DayType type) => type == DayType.work;

Color colorForDayType(DayType type, ThemeData theme) {
  switch (type) {
    case DayType.conge:
      return Colors.orange;
    case DayType.maladie:
      return Colors.redAccent;
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
  const DayEntry({required this.minutes, required this.type});

  final int minutes;
  final DayType type;

  DayEntry copyWith({int? minutes, DayType? type}) {
    return DayEntry(
      minutes: minutes ?? this.minutes,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minutes': minutes,
      'type': dayTypeToString(type),
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
    return DayEntry(minutes: minutes, type: type);
  }
  return null;
}
