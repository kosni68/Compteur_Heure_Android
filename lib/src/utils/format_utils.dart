String formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes.abs();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h${minutes.toString().padLeft(2, '0')}';
}

String formatRemaining(Duration? remaining) {
  if (remaining == null) {
    return '--';
  }
  final abs = remaining.abs();
  if (abs.inMinutes == 0) {
    return remaining.isNegative ? 'A l\'instant' : "Moins d'une minute";
  }
  final formatted = formatDuration(abs);
  return remaining.isNegative ? 'Termine depuis $formatted' : '$formatted restant';
}

String formatDecimalHoursFromMinutes(int minutes) {
  final hours = minutes / 60.0;
  var value = hours.toStringAsFixed(2);
  value = value.replaceAll(RegExp(r'0+$'), '');
  value = value.replaceAll(RegExp(r'\.$'), '');
  return value.replaceAll('.', ',');
}

int? parseDecimalHoursToMinutes(String raw, {required bool allowZero}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final normalized = trimmed.replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null) {
    return null;
  }
  if (allowZero) {
    if (value < 0) {
      return null;
    }
  } else {
    if (value <= 0) {
      return null;
    }
  }
  final minutes = (value * 60).round();
  if (!allowZero && minutes <= 0) {
    return null;
  }
  return minutes;
}

String formatSignedDuration(int minutes) {
  final absMinutes = minutes.abs();
  final formatted = formatDuration(Duration(minutes: absMinutes));
  return minutes >= 0 ? '+$formatted' : '-$formatted';
}
