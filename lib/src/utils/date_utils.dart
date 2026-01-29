import '../models/day_entry.dart';

String formatDateShort(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime? dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

DateTime startOfWeek(DateTime date) {
  final weekday = date.weekday; // 1 = Monday
  return dateOnly(date.subtract(Duration(days: weekday - 1)));
}

int sumEntriesInRange(
  Map<String, DayEntry> entries,
  DateTime start,
  DateTime end, {
  DayType? typeFilter,
}) {
  final rangeStart = dateOnly(start);
  final rangeEnd = dateOnly(end);
  int total = 0;
  for (final entry in entries.entries) {
    final date = dateFromKey(entry.key);
    if (date == null) {
      continue;
    }
    if (!date.isBefore(rangeStart) && !date.isAfter(rangeEnd)) {
      if (typeFilter != null && entry.value.type != typeFilter) {
        continue;
      }
      total += entry.value.minutes;
    }
  }
  return total;
}

int countEntriesInRange(
  Map<String, DayEntry> entries,
  DateTime start,
  DateTime end, {
  DayType? typeFilter,
}) {
  final rangeStart = dateOnly(start);
  final rangeEnd = dateOnly(end);
  int count = 0;
  for (final entry in entries.entries) {
    final date = dateFromKey(entry.key);
    if (date == null) {
      continue;
    }
    if (!date.isBefore(rangeStart) && !date.isAfter(rangeEnd)) {
      if (typeFilter != null && entry.value.type != typeFilter) {
        continue;
      }
      count++;
    }
  }
  return count;
}
