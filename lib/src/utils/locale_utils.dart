import 'package:flutter/material.dart';

const List<Locale> kSupportedLocales = [
  Locale('fr', 'FR'),
  Locale('en', 'US'),
  Locale('it', 'IT'),
  Locale('de', 'DE'),
];

Locale? localeFromCode(String code) {
  switch (code) {
    case 'system':
      return null;
    case 'en':
      return const Locale('en', 'US');
    case 'it':
      return const Locale('it', 'IT');
    case 'de':
      return const Locale('de', 'DE');
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
    case 'it':
      return 'it_IT';
    case 'de':
      return 'de_DE';
    case 'fr':
    default:
      return 'fr_FR';
  }
}
