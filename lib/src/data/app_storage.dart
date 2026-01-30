import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_data.dart';
import '../models/day_entry.dart';
import '../utils/break_utils.dart';
import '../utils/format_utils.dart';
import '../utils/time_utils.dart';

class AppStorage {
  static const String _fileName = 'compteur_data.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<AppData> load() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        if (raw.trim().isNotEmpty) {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          return AppData.fromJson(json);
        }
      }
    } catch (_) {}

    final migrated = await _loadFromPrefs();
    await save(migrated);
    return migrated;
  }

  Future<AppData> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetRaw = prefs.getString('targetHours');
      final startRaw = prefs.getString('startTime');
      final breaksRaw = prefs.getStringList('breaks');

      final targetMinutes =
          parseDecimalHoursToMinutes(targetRaw ?? '', allowZero: false) ??
              AppData.defaultTargetMinutes;

      return AppData(
        targetMinutes: targetMinutes,
        startTime: timeFromStorage(startRaw),
        breaks: breaksFromStorage(breaksRaw),
        entries: <String, DayEntry>{},
        localeCode: 'fr',
        backgroundId: 'none',
        notifyEnabled: false,
        notifyMinutesBefore: 15,
        themeMode: ThemeMode.light,
        seedColor: AppData.defaultSeedColor,
      );
    } catch (_) {
      return AppData.initial();
    }
  }

  Future<void> save(AppData data) async {
    final file = await _getFile();
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data.toJson()));
  }
}
