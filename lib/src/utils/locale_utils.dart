import 'package:flutter/material.dart';

const List<Locale> kSupportedLocales = [
  Locale('fr', 'FR'),
  Locale('en', 'US'),
];

Locale? localeFromCode(String code) {
  switch (code) {
    case 'system':
      return null;
    case 'en':
      return const Locale('en', 'US');
    case 'fr':
    default:
      return const Locale('fr', 'FR');
  }
}

String? calendarLocaleFromCode(String code) {
  switch (code) {
    case 'system':
      return null;
    case 'en':
      return 'en_US';
    case 'fr':
    default:
      return 'fr_FR';
  }
}
