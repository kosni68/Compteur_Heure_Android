import 'package:flutter/material.dart';

ThemeMode themeModeFromString(String? raw) {
  switch (raw) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    case 'light':
    default:
      return ThemeMode.light;
  }
}

String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
    case ThemeMode.light:
    default:
      return 'light';
  }
}
