import 'package:flutter/material.dart';

ThemeData buildAppTheme(Color seedColor, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  final isLight = brightness == Brightness.light;
  final fillColor = isLight
      ? Colors.white.withOpacity(0.9)
      : colorScheme.surface.withOpacity(0.5);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Sora',
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: colorScheme.surface,
    ),
  );
}
