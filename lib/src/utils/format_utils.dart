import '../localization/app_localizations.dart';

String formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes.abs();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h${minutes.toString().padLeft(2, '0')}';
}

String formatRemaining(Duration? remaining, AppLocalizations l10n) {
  if (remaining == null) {
    return '--';
  }
  final abs = remaining.abs();
  if (abs.inMinutes == 0) {
    return remaining.isNegative
        ? l10n.remainingNow()
        : l10n.remainingLessThanMinute();
  }
  final formatted = formatDuration(abs);
  return remaining.isNegative
      ? l10n.remainingSince(formatted)
      : l10n.remainingLeft(formatted);
}

String formatDecimalHoursFromMinutes(
  int minutes, {
  required String decimalSeparator,
}) {
  final hours = minutes / 60.0;
  var value = hours.toStringAsFixed(2);
  value = value.replaceAll(RegExp(r'0+$'), '');
  value = value.replaceAll(RegExp(r'\.$'), '');
  return value.replaceAll('.', decimalSeparator);
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
