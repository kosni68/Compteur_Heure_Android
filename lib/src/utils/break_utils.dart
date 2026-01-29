import '../models/break_interval.dart';
import 'time_utils.dart';

List<BreakInterval> cloneBreaks(List<BreakInterval> source) {
  return source.map((item) => item.copy()).toList();
}

List<BreakInterval> breaksFromStorage(List<String>? raw) {
  if (raw == null) {
    return <BreakInterval>[];
  }
  final items = <BreakInterval>[];
  for (final entry in raw) {
    final parts = entry.split('|');
    if (parts.length != 2) {
      continue;
    }
    final start = timeFromStorage(parts[0]);
    final end = timeFromStorage(parts[1]);
    if (start == null || end == null) {
      continue;
    }
    items.add(BreakInterval(start: start, end: end));
  }
  return items;
}

List<BreakInterval> breaksFromJson(dynamic raw) {
  if (raw is List) {
    final items = <BreakInterval>[];
    for (final entry in raw) {
      if (entry is Map) {
        final startRaw = entry['start'];
        final endRaw = entry['end'];
        if (startRaw is String && endRaw is String) {
          final start = timeFromStorage(startRaw);
          final end = timeFromStorage(endRaw);
          if (start != null && end != null) {
            items.add(BreakInterval(start: start, end: end));
          }
        }
      } else if (entry is String) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final start = timeFromStorage(parts[0]);
          final end = timeFromStorage(parts[1]);
          if (start != null && end != null) {
            items.add(BreakInterval(start: start, end: end));
          }
        }
      }
    }
    return items;
  }
  return <BreakInterval>[];
}
