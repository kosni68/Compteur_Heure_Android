import 'package:flutter/material.dart';

TimeOfDay? timeFromStorage(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final parts = value.split(':');
  if (parts.length != 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}

String timeToStorage(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatTimeOfDay(TimeOfDay? time) {
  if (time == null) {
    return '--:--';
  }
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
