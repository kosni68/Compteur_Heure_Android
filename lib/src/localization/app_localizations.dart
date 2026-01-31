import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  String get _lang => locale.languageCode;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _select(Map<String, String> values) {
    return values[_lang] ?? values['en'] ?? values.values.first;
  }

  String get appTitle => _select({
        'fr': "Compteur d'heures",
        'en': 'Time Counter',
        'it': 'Contatore ore',
        'de': 'Stundenzaehler',
      });

  String get tagline => _select({
        'fr': 'Suivi simple, clair, et local.',
        'en': 'Simple, clear, and local tracking.',
        'it': 'Monitoraggio semplice, chiaro e locale.',
        'de': 'Einfaches, klares und lokales Tracking.',
      });

  String get sectionSettings => _select({
        'fr': 'Parametres',
        'en': 'Settings',
        'it': 'Impostazioni',
        'de': 'Einstellungen',
      });

  String get sectionTheme => _select({
        'fr': 'Theme',
        'en': 'Theme',
        'it': 'Tema',
        'de': 'Thema',
      });

  String get sectionPointage => _select({
        'fr': 'Pointage du jour',
        'en': "Today's time",
        'it': 'Timbratura del giorno',
        'de': 'Heutige Erfassung',
      });

  String get sectionCalendar => _select({
        'fr': 'Calendrier',
        'en': 'Calendar',
        'it': 'Calendario',
        'de': 'Kalender',
      });

  String get sectionStats => _select({
        'fr': 'Statistiques',
        'en': 'Statistics',
        'it': 'Statistiche',
        'de': 'Statistiken',
      });

  String get settingsDailyTargetTitle => _select({
        'fr': 'Objectif journalier',
        'en': 'Daily target',
        'it': 'Obiettivo giornaliero',
        'de': 'Tagesziel',
      });

  String get settingsDailyTargetSubtitle => _select({
        'fr': 'Par jour, en heures decimales (8,4 = 8h24).',
        'en': 'Per day, in decimal hours (8.4 = 8h24).',
        'it': 'Per giorno, in ore decimali (8,4 = 8h24).',
        'de': 'Pro Tag, in Dezimalstunden (8,4 = 8h24).',
      });

  String get settingsTargetLabel => _select({
        'fr': 'Objectif',
        'en': 'Target',
        'it': 'Obiettivo',
        'de': 'Ziel',
      });

  String get settingsTargetHint => _select({
        'fr': '8,4',
        'en': '8.4',
        'it': '8,4',
        'de': '8,4',
      });

  String get settingsSave => _select({
        'fr': 'Enregistrer',
        'en': 'Save',
        'it': 'Salva',
        'de': 'Speichern',
      });

  String get settingsInvalidTarget => _select({
        'fr': 'Objectif invalide. Exemple: 8,4',
        'en': 'Invalid target. Example: 8.4',
        'it': 'Obiettivo non valido. Esempio: 8,4',
        'de': 'Ungueltiges Ziel. Beispiel: 8,4',
      });

  String get settingsLanguageTitle => _select({
        'fr': 'Langue',
        'en': 'Language',
        'it': 'Lingua',
        'de': 'Sprache',
      });

  String get settingsLanguageSubtitle => _select({
        'fr': "Choisis la langue de l'application.",
        'en': 'Choose the app language.',
        'it': "Scegli la lingua dell'app.",
        'de': 'Waehle die App-Sprache.',
      });

  String get settingsLanguageSystem => _select({
        'fr': 'Systeme',
        'en': 'System',
        'it': 'Sistema',
        'de': 'System',
      });

  String get settingsLanguageFrench => _select({
        'fr': 'Francais',
        'en': 'French',
        'it': 'Francese',
        'de': 'Franzoesisch',
      });

  String get settingsLanguageEnglish => _select({
        'fr': 'Anglais',
        'en': 'English',
        'it': 'Inglese',
        'de': 'Englisch',
      });

  String get settingsLanguageItalian => _select({
        'fr': 'Italien',
        'en': 'Italian',
        'it': 'Italiano',
        'de': 'Italienisch',
      });

  String get settingsLanguageGerman => _select({
        'fr': 'Allemand',
        'en': 'German',
        'it': 'Tedesco',
        'de': 'Deutsch',
      });

  String get settingsBackgroundTitle => _select({
        'fr': 'Image de fond',
        'en': 'Background image',
        'it': 'Immagine di sfondo',
        'de': 'Hintergrundbild',
      });

  String get settingsBackgroundSubtitle => _select({
        'fr': "Choisis un visuel pour l'application.",
        'en': 'Choose a background for the app.',
        'it': "Scegli uno sfondo per l'app.",
        'de': 'Waehle ein Hintergrundbild fuer die App.',
      });

  String get backgroundNone => _select({
        'fr': 'Aucun',
        'en': 'None',
        'it': 'Nessuno',
        'de': 'Keins',
      });

  String get backgroundAurora => _select({
        'fr': 'Aurore',
        'en': 'Aurora',
        'it': 'Aurora',
        'de': 'Aurora',
      });

  String get backgroundDunes => _select({
        'fr': 'Dunes',
        'en': 'Dunes',
        'it': 'Dune',
        'de': 'Duenen',
      });

  String get backgroundPaper => _select({
        'fr': 'Papier',
        'en': 'Paper',
        'it': 'Carta',
        'de': 'Papier',
      });

  String get themeModeTitle => _select({
        'fr': 'Mode',
        'en': 'Mode',
        'it': 'Modalita',
        'de': 'Modus',
      });

  String get themeModeSubtitle => _select({
        'fr': 'Clair, sombre, ou automatique.',
        'en': 'Light, dark, or automatic.',
        'it': 'Chiaro, scuro o automatico.',
        'de': 'Hell, dunkel oder automatisch.',
      });

  String get themeModeLight => _select({
        'fr': 'Clair',
        'en': 'Light',
        'it': 'Chiaro',
        'de': 'Hell',
      });

  String get themeModeDark => _select({
        'fr': 'Sombre',
        'en': 'Dark',
        'it': 'Scuro',
        'de': 'Dunkel',
      });

  String get themeModeSystem => _select({
        'fr': 'Auto',
        'en': 'Auto',
        'it': 'Auto',
        'de': 'Auto',
      });

  String get themeColorTitle => _select({
        'fr': 'Couleur',
        'en': 'Color',
        'it': 'Colore',
        'de': 'Farbe',
      });

  String get themeColorSubtitle => _select({
        'fr': "Choisis la teinte principale de l'application.",
        'en': 'Choose the main app color.',
        'it': "Scegli il colore principale dell'app.",
        'de': 'Waehle die Hauptfarbe der App.',
      });

  String get themeTip => _select({
        'fr':
            'Astuce: le mode sombre utilise la meme couleur mais sur un fond plus contraste.',
        'en': 'Tip: dark mode uses the same color on a higher-contrast background.',
        'it':
            'Suggerimento: la modalita scura usa lo stesso colore su uno sfondo piu contrastato.',
        'de':
            'Tipp: Der Dunkelmodus verwendet die gleiche Farbe auf einem kontrastreicheren Hintergrund.',
      });

  String get colorMint => _select({
        'fr': 'Menthe',
        'en': 'Mint',
        'it': 'Menta',
        'de': 'Minze',
      });

  String get colorCoral => _select({
        'fr': 'Corail',
        'en': 'Coral',
        'it': 'Corallo',
        'de': 'Koralle',
      });

  String get colorOcean => _select({
        'fr': 'Ocean',
        'en': 'Ocean',
        'it': 'Oceano',
        'de': 'Ozean',
      });

  String get colorAmber => _select({
        'fr': 'Ambre',
        'en': 'Amber',
        'it': 'Ambra',
        'de': 'Bernstein',
      });

  String get colorIndigo => _select({
        'fr': 'Indigo',
        'en': 'Indigo',
        'it': 'Indaco',
        'de': 'Indigo',
      });

  String get colorSand => _select({
        'fr': 'Sable',
        'en': 'Sand',
        'it': 'Sabbia',
        'de': 'Sand',
      });

  String get headerSubtitle => _select({
        'fr': 'Calcule le total de ta journee en tenant compte des pauses.',
        'en': 'Calculate your day total including breaks.',
        'it': 'Calcola il totale della giornata includendo le pause.',
        'de': 'Berechne den Tagesgesamtwert inklusive Pausen.',
      });

  String get timeCardSubtitle => _select({
        'fr': 'Heure de debut et de fin (format 24h).',
        'en': 'Start and end time (24h format).',
        'it': 'Ora di inizio e fine (formato 24h).',
        'de': 'Start- und Endzeit (24h-Format).',
      });

  String get labelStart => _select({
        'fr': 'Debut',
        'en': 'Start',
        'it': 'Inizio',
        'de': 'Start',
      });

  String get labelEnd => _select({
        'fr': 'Fin',
        'en': 'End',
        'it': 'Fine',
        'de': 'Ende',
      });

  String get breaksTitle => _select({
        'fr': 'Pauses',
        'en': 'Breaks',
        'it': 'Pause',
        'de': 'Pausen',
      });

  String get breaksSubtitle => _select({
        'fr': "Les pauses sont interpretees dans l'ordre de la liste.",
        'en': 'Breaks are interpreted in list order.',
        'it': "Le pause sono interpretate nell'ordine della lista.",
        'de': 'Pausen werden in Listenreihenfolge interpretiert.',
      });

  String get addBreak => _select({
        'fr': 'Ajouter une pause',
        'en': 'Add break',
        'it': 'Aggiungi pausa',
        'de': 'Pause hinzufuegen',
      });

  String breakLabel(int index) => _select({
        'fr': 'Pause $index',
        'en': 'Break $index',
        'it': 'Pausa $index',
        'de': 'Pause $index',
      });

  String get deleteLabel => _select({
        'fr': 'Supprimer',
        'en': 'Delete',
        'it': 'Elimina',
        'de': 'Loeschen',
      });

  String get resultTitle => _select({
        'fr': 'Resultat',
        'en': 'Result',
        'it': 'Risultato',
        'de': 'Ergebnis',
      });

  String get estimationTitle => _select({
        'fr': 'Estimation',
        'en': 'Estimate',
        'it': 'Stima',
        'de': 'Schaetzung',
      });

  String get estimateNeedStart => _select({
        'fr': "Renseigne l'heure de debut pour estimer la fin.",
        'en': 'Enter a start time to estimate the end.',
        'it': "Inserisci l'ora di inizio per stimare la fine.",
        'de': 'Startzeit eingeben, um das Ende zu schaetzen.',
      });

  String get estimatedEndLabel => _select({
        'fr': 'Heure de fin estimee',
        'en': 'Estimated end time',
        'it': 'Ora di fine stimata',
        'de': 'Geschaetzte Endzeit',
      });

  String get targetLabel => _select({
        'fr': 'Objectif',
        'en': 'Target',
        'it': 'Obiettivo',
        'de': 'Ziel',
      });

  String get plannedBreaksLabel => _select({
        'fr': 'Pauses prevues',
        'en': 'Planned breaks',
        'it': 'Pause previste',
        'de': 'Geplante Pausen',
      });

  String get countdownLabel => _select({
        'fr': 'Compteur',
        'en': 'Countdown',
        'it': 'Contatore',
        'de': 'Countdown',
      });

  String get pointageTitle => _select({
        'fr': 'Pointage',
        'en': 'Check-in',
        'it': 'Timbratura',
        'de': 'Erfassung',
      });

  String get pointageNeedEnd => _select({
        'fr': "Renseigne l'heure de fin pour calculer le solde.",
        'en': 'Enter an end time to calculate the balance.',
        'it': "Inserisci l'ora di fine per calcolare il saldo.",
        'de': 'Endzeit eingeben, um den Saldo zu berechnen.',
      });

  String get loggedEndLabel => _select({
        'fr': 'Heure de fin pointee',
        'en': 'Logged end time',
        'it': 'Ora di fine registrata',
        'de': 'Erfasste Endzeit',
      });

  String get workedDurationLabel => _select({
        'fr': 'Duree travail',
        'en': 'Work duration',
        'it': 'Durata lavoro',
        'de': 'Arbeitsdauer',
      });

  String get breaksLabel => _select({
        'fr': 'Pauses',
        'en': 'Breaks',
        'it': 'Pause',
        'de': 'Pausen',
      });

  String get presenceLabel => _select({
        'fr': 'Presence',
        'en': 'Presence',
        'it': 'Presenza',
        'de': 'Anwesenheit',
      });

  String get balanceLabel => _select({
        'fr': 'Solde vs objectif',
        'en': 'Balance vs target',
        'it': 'Saldo vs obiettivo',
        'de': 'Saldo vs Ziel',
      });

  String get calendarStatusLabel => _select({
        'fr': 'Calendrier',
        'en': 'Calendar',
        'it': 'Calendario',
        'de': 'Kalender',
      });

  String get savedYes => _select({
        'fr': 'Enregistre',
        'en': 'Saved',
        'it': 'Salvato',
        'de': 'Gespeichert',
      });

  String get savedNo => _select({
        'fr': 'Non',
        'en': 'No',
        'it': 'No',
        'de': 'Nein',
      });

  String get errorStartRequired => _select({
        'fr': "Renseigne l'heure de debut.",
        'en': 'Enter a start time.',
        'it': "Inserisci l'ora di inizio.",
        'de': 'Startzeit eingeben.',
      });

  String get errorInvalidTimes => _select({
        'fr': 'Horaires invalides.',
        'en': 'Invalid times.',
        'it': 'Orari non validi.',
        'de': 'Ungueltige Zeiten.',
      });

  String dayOffset(int offset) => _select({
        'fr': 'J+$offset',
        'en': 'D+$offset',
        'it': 'G+$offset',
        'de': 'T+$offset',
      });

  String remainingNow() => _select({
        'fr': "A l'instant",
        'en': 'Right now',
        'it': 'Proprio ora',
        'de': 'Jetzt',
      });

  String remainingLessThanMinute() => _select({
        'fr': "Moins d'une minute",
        'en': 'Less than a minute',
        'it': 'Meno di un minuto',
        'de': 'Weniger als eine Minute',
      });

  String remainingSince(String duration) => _select({
        'fr': 'Termine depuis $duration',
        'en': 'Finished $duration ago',
        'it': 'Finito da $duration',
        'de': 'Seit $duration beendet',
      });

  String remainingLeft(String duration) => _select({
        'fr': '$duration restant',
        'en': '$duration remaining',
        'it': '$duration rimanenti',
        'de': '$duration verbleibend',
      });

  String get calendarTitle => _select({
        'fr': 'Calendrier',
        'en': 'Calendar',
        'it': 'Calendario',
        'de': 'Kalender',
      });

  String get calendarSubtitle => _select({
        'fr': 'Selectionne un jour pour saisir tes heures.',
        'en': 'Select a day to enter your hours.',
        'it': 'Seleziona un giorno per inserire le ore.',
        'de': 'Waehle einen Tag, um Stunden einzutragen.',
      });

  String get calendarMonth => _select({
        'fr': 'Mois',
        'en': 'Month',
        'it': 'Mese',
        'de': 'Monat',
      });

  String get calendarWeek => _select({
        'fr': 'Semaine',
        'en': 'Week',
        'it': 'Settimana',
        'de': 'Woche',
      });

  String get calendarTotalPeriod => _select({
        'fr': 'Total periode',
        'en': 'Total period',
        'it': 'Totale periodo',
        'de': 'Gesamtzeitraum',
      });

  String get calendarDaysEntered => _select({
        'fr': 'Jours renseignes',
        'en': 'Days entered',
        'it': 'Giorni inseriti',
        'de': 'Eingetragene Tage',
      });

  String get calendarPeriodTarget => _select({
        'fr': 'Objectif periode',
        'en': 'Period target',
        'it': 'Obiettivo periodo',
        'de': 'Zielzeitraum',
      });

  String get calendarPeriodBalance => _select({
        'fr': 'Solde periode',
        'en': 'Period balance',
        'it': 'Saldo periodo',
        'de': 'Saldo Zeitraum',
      });

  String get dayEntryTitle => _select({
        'fr': 'Saisie du jour',
        'en': 'Day entry',
        'it': 'Inserimento del giorno',
        'de': 'Tageserfassung',
      });

  String get dayEntryFutureNotAllowed => _select({
        'fr': 'Pas de saisie autorisee dans le futur.',
        'en': 'No entry allowed in the future.',
        'it': 'Nessuna voce consentita nel futuro.',
        'de': 'Keine Eingaben in der Zukunft erlaubt.',
      });

  String get dayEntrySubtitle => _select({
        'fr': "Saisis le total d'heures pour la date selectionnee.",
        'en': 'Enter total hours for the selected date.',
        'it': 'Inserisci il totale ore per la data selezionata.',
        'de': 'Gesamtstunden fuer das gewaehlte Datum eingeben.',
      });

  String dayEntryDateLabel(String date) => _select({
        'fr': 'Date: $date',
        'en': 'Date: $date',
        'it': 'Data: $date',
        'de': 'Datum: $date',
      });

  String get dayEntryHoursLabel => _select({
        'fr': 'Heures du jour',
        'en': 'Hours for the day',
        'it': 'Ore del giorno',
        'de': 'Stunden des Tages',
      });

  String get dayEntryHoursHint => _select({
        'fr': '7,5',
        'en': '7.5',
        'it': '7,5',
        'de': '7,5',
      });

  String get dayEntryClear => _select({
        'fr': 'Effacer',
        'en': 'Clear',
        'it': 'Cancella',
        'de': 'Loeschen',
      });

  String get calendarFutureSnack => _select({
        'fr': 'Pas de saisie dans le futur.',
        'en': 'No entries in the future.',
        'it': 'Nessuna voce nel futuro.',
        'de': 'Keine Eingaben in der Zukunft.',
      });

  String get calendarInvalidValue => _select({
        'fr': 'Valeur invalide. Exemple: 7,5',
        'en': 'Invalid value. Example: 7.5',
        'it': 'Valore non valido. Esempio: 7,5',
        'de': 'Ungueltiger Wert. Beispiel: 7,5',
      });

  String get statsGlobalTitle => _select({
        'fr': 'Compteur global',
        'en': 'Overall totals',
        'it': 'Totale globale',
        'de': 'Gesamtsumme',
      });

  String get statsTotalHours => _select({
        'fr': 'Total heures',
        'en': 'Total hours',
        'it': 'Ore totali',
        'de': 'Gesamtstunden',
      });

  String get statsDaysTracked => _select({
        'fr': 'Jours renseignes',
        'en': 'Days entered',
        'it': 'Giorni inseriti',
        'de': 'Eingetragene Tage',
      });

  String get statsTargetTotal => _select({
        'fr': 'Objectif cumule',
        'en': 'Cumulative target',
        'it': 'Obiettivo cumulato',
        'de': 'Kumuliertes Ziel',
      });

  String get statsBalance => _select({
        'fr': 'Solde',
        'en': 'Balance',
        'it': 'Saldo',
        'de': 'Saldo',
      });

  String get statsTitle => _select({
        'fr': 'Statistiques',
        'en': 'Statistics',
        'it': 'Statistiche',
        'de': 'Statistiken',
      });

  String get statsAverage => _select({
        'fr': 'Moyenne / jour',
        'en': 'Average / day',
        'it': 'Media / giorno',
        'de': 'Durchschnitt / Tag',
      });

  String get statsBestDay => _select({
        'fr': 'Meilleure journee',
        'en': 'Best day',
        'it': 'Miglior giorno',
        'de': 'Bester Tag',
      });

  String get statsWeek => _select({
        'fr': 'Semaine en cours',
        'en': 'Current week',
        'it': 'Settimana corrente',
        'de': 'Aktuelle Woche',
      });

  String get statsMonth => _select({
        'fr': 'Mois en cours',
        'en': 'Current month',
        'it': 'Mese corrente',
        'de': 'Aktueller Monat',
      });

  String get statsLast7 => _select({
        'fr': '7 derniers jours',
        'en': 'Last 7 days',
        'it': 'Ultimi 7 giorni',
        'de': 'Letzte 7 Tage',
      });

  String get statsSpecialDays => _select({
        'fr': 'Jours speciaux',
        'en': 'Special days',
        'it': 'Giorni speciali',
        'de': 'Spezielle Tage',
      });

  String get statsTotalBreaks => _select({
        'fr': 'Total pauses',
        'en': 'Total breaks',
        'it': 'Totale pause',
        'de': 'Gesamtpausen',
      });

  String get historyTitle => _select({
        'fr': 'Historique de la journee',
        'en': 'Day history',
        'it': 'Storico della giornata',
        'de': 'Tagesverlauf',
      });

  String get historyStart => _select({
        'fr': 'Heure de debut',
        'en': 'Start time',
        'it': 'Ora di inizio',
        'de': 'Startzeit',
      });

  String get historyEnd => _select({
        'fr': 'Heure de fin',
        'en': 'End time',
        'it': 'Ora di fine',
        'de': 'Endzeit',
      });

  String get historyWorked => _select({
        'fr': 'Travail effectif',
        'en': 'Worked time',
        'it': 'Tempo lavorato',
        'de': 'Arbeitszeit',
      });

  String get historyBreaksTotal => _select({
        'fr': 'Total pauses',
        'en': 'Total breaks',
        'it': 'Totale pause',
        'de': 'Gesamtpausen',
      });

  String get todayLabel => _select({
        'fr': "Aujourd'hui",
        'en': 'Today',
        'it': 'Oggi',
        'de': 'Heute',
      });

  String get exportLabel => _select({
        'fr': 'Exporter',
        'en': 'Export',
        'it': 'Esporta',
        'de': 'Exportieren',
      });

  String get exportEmpty => _select({
        'fr': 'Rien a exporter.',
        'en': 'Nothing to export.',
        'it': 'Niente da esportare.',
        'de': 'Nichts zu exportieren.',
      });

  String exportSaved(String path) => _select({
        'fr': 'Export enregistre: $path',
        'en': 'Export saved: $path',
        'it': 'Export salvato: $path',
        'de': 'Export gespeichert: $path',
      });

  String get notificationsTitle => _select({
        'fr': 'Notification fin de journee',
        'en': 'End-of-day notification',
        'it': 'Notifica fine giornata',
        'de': 'Benachrichtigung Tagesende',
      });

  String get notificationsSubtitle => _select({
        'fr': 'Alerte avant la fin estimee.',
        'en': 'Alert before the estimated end.',
        'it': 'Avviso prima della fine stimata.',
        'de': 'Hinweis vor dem geschaetzten Ende.',
      });

  String get notificationsEnable => _select({
        'fr': 'Activer la notification',
        'en': 'Enable notification',
        'it': 'Abilita notifica',
        'de': 'Benachrichtigung aktivieren',
      });

  String get notificationsMinutesLabel => _select({
        'fr': 'Minutes avant',
        'en': 'Minutes before',
        'it': 'Minuti prima',
        'de': 'Minuten vorher',
      });

  String get notificationsMinutesHint => _select({
        'fr': '15',
        'en': '15',
        'it': '15',
        'de': '15',
      });

  String get notificationsInvalid => _select({
        'fr': 'Valeur invalide. Exemple: 15',
        'en': 'Invalid value. Example: 15',
        'it': 'Valore non valido. Esempio: 15',
        'de': 'Ungueltiger Wert. Beispiel: 15',
      });

  String get pauseReminderTitle => _select({
        'fr': 'Rappel de reprise',
        'en': 'Break reminder',
        'it': 'Promemoria ripresa',
        'de': 'Pausen-Erinnerung',
      });

  String get pauseReminderSubtitle => _select({
        'fr': 'Alerte apres une pause.',
        'en': 'Alert after a break.',
        'it': 'Avviso dopo una pausa.',
        'de': 'Hinweis nach einer Pause.',
      });

  String get pauseReminderMinutesLabel => _select({
        'fr': 'Minutes de pause',
        'en': 'Break minutes',
        'it': 'Minuti di pausa',
        'de': 'Pausenminuten',
      });

  String get pauseReminderMinutesHint => _select({
        'fr': '30',
        'en': '30',
        'it': '30',
        'de': '30',
      });

  String get pauseReminderInvalid => _select({
        'fr': 'Valeur invalide. Exemple: 30',
        'en': 'Invalid value. Example: 30',
        'it': 'Valore non valido. Esempio: 30',
        'de': 'Ungueltiger Wert. Beispiel: 30',
      });

  String get pauseReminderNotificationTitle => _select({
        'fr': 'Reprise du pointage',
        'en': 'Resume tracking',
        'it': 'Riprendi la timbratura',
        'de': 'Erfassung fortsetzen',
      });

  String get pauseReminderNotificationBody => _select({
        'fr': 'Ta pause est terminee. Reprends le pointage.',
        'en': 'Your break is over. Resume tracking.',
        'it': 'La pausa e finita. Riprendi la timbratura.',
        'de': 'Deine Pause ist vorbei. Erfassung fortsetzen.',
      });

  String get notificationTitle => _select({
        'fr': 'Fin de journee proche',
        'en': 'End of day soon',
        'it': 'Fine giornata vicina',
        'de': 'Tagesende naht',
      });

  String notificationBody(String time) => _select({
        'fr': 'Fin estimee vers $time.',
        'en': 'Estimated end around $time.',
        'it': 'Fine stimata verso le $time.',
        'de': 'Geschaetztes Ende gegen $time.',
      });

  String get pointageActionStart => _select({
        'fr': 'Debut de pointage',
        'en': 'Start tracking',
        'it': 'Inizia timbratura',
        'de': 'Erfassung starten',
      });

  String get pointageActionEnd => _select({
        'fr': 'Fin de pointage',
        'en': 'End tracking',
        'it': 'Fine timbratura',
        'de': 'Erfassung beenden',
      });

  String get pointageActionPause => _select({
        'fr': 'Pause',
        'en': 'Pause',
        'it': 'Pausa',
        'de': 'Pause',
      });

  String get pointageNotificationChannelName => _select({
        'fr': 'Pointage',
        'en': 'Tracking',
        'it': 'Timbratura',
        'de': 'Erfassung',
      });

  String get pointageNotificationChannelDescription => _select({
        'fr': 'Notification persistante du pointage.',
        'en': 'Persistent tracking notification.',
        'it': 'Notifica persistente della timbratura.',
        'de': 'Persistente Erfassungsbenachrichtigung.',
      });

  String get pauseReminderChannelName => _select({
        'fr': 'Rappel de pause',
        'en': 'Break reminder',
        'it': 'Promemoria pausa',
        'de': 'Pausen-Erinnerung',
      });

  String get pauseReminderChannelDescription => _select({
        'fr': 'Rappel pour reprendre apres une pause.',
        'en': 'Reminder to resume after a break.',
        'it': 'Promemoria per riprendere dopo una pausa.',
        'de': 'Erinnerung zum Fortsetzen nach einer Pause.',
      });

  String get pointageNotificationTitleIdle => _select({
        'fr': 'Pointage',
        'en': 'Tracking',
        'it': 'Timbratura',
        'de': 'Erfassung',
      });

  String get pointageNotificationTitleRunning => _select({
        'fr': 'Pointage en cours',
        'en': 'Tracking in progress',
        'it': 'Timbratura in corso',
        'de': 'Erfassung laeuft',
      });

  String get pointageNotificationTitlePaused => _select({
        'fr': 'Pause en cours',
        'en': 'Paused',
        'it': 'Pausa in corso',
        'de': 'Pausiert',
      });

  String get pointageNotificationTitleEnded => _select({
        'fr': 'Pointage termine',
        'en': 'Tracking ended',
        'it': 'Timbratura terminata',
        'de': 'Erfassung beendet',
      });

  String get pointageNotificationBodyIdle => _select({
        'fr': 'Appuie pour commencer.',
        'en': 'Tap to start.',
        'it': 'Tocca per iniziare.',
        'de': 'Tippen zum Starten.',
      });

  String pointageNotificationBodyRunning(String time) => _select({
        'fr': 'Debut a $time.',
        'en': 'Started at $time.',
        'it': 'Inizio alle $time.',
        'de': 'Gestartet um $time.',
      });

  String pointageNotificationBodyPaused(String time) => _select({
        'fr': 'Pause depuis $time.',
        'en': 'Paused since $time.',
        'it': 'Pausa dalle $time.',
        'de': 'Pause seit $time.',
      });

  String pointageNotificationBodyEnded(String time) => _select({
        'fr': 'Fin a $time.',
        'en': 'Ended at $time.',
        'it': 'Fine alle $time.',
        'de': 'Beendet um $time.',
      });

  String get dayTypeWork => _select({
        'fr': 'Travail',
        'en': 'Work',
        'it': 'Lavoro',
        'de': 'Arbeit',
      });

  String get dayTypeConge => _select({
        'fr': 'Conge',
        'en': 'Leave',
        'it': 'Ferie',
        'de': 'Urlaub',
      });

  String get dayTypeMaladie => _select({
        'fr': 'Maladie',
        'en': 'Sick',
        'it': 'Malattia',
        'de': 'Krank',
      });

  String get dayTypeMaladieEnfant => _select({
        'fr': 'Maladie (enfant)',
        'en': 'Sick (child)',
        'it': 'Malattia (bambino)',
        'de': 'Krank (Kind)',
      });

  String get dayTypePont => _select({
        'fr': 'Pont',
        'en': 'Bridge day',
        'it': 'Ponte',
        'de': 'Brueckentag',
      });

  String get dayTypeRecup => _select({
        'fr': 'Recup',
        'en': 'Comp time',
        'it': 'Recupero',
        'de': 'Ausgleich',
      });

  String get decimalSeparator => _select({
        'fr': ',',
        'en': '.',
        'it': ',',
        'de': ',',
      });
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['fr', 'en', 'it', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
