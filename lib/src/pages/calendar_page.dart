import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';

import '../controller/app_controller.dart';
import '../models/day_entry.dart';
import '../utils/date_utils.dart';
import '../utils/format_utils.dart';
import '../utils/locale_utils.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _format = CalendarFormat.month;
  final TextEditingController _hoursController = TextEditingController();
  DayType _selectedType = DayType.work;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _focusedDay = today;
    _selectedDay = today;
    widget.controller.addListener(_onControllerChanged);
    _syncForSelectedDay();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _hoursController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    _syncForSelectedDay();
  }

  void _syncForSelectedDay() {
    final entry = widget.controller.data.entries[dateKey(_selectedDay)];
    final next =
        entry == null ? '' : formatDecimalHoursFromMinutes(entry.minutes);
    if (_hoursController.text != next) {
      _hoursController.text = next;
    }
    final nextType = entry?.type ?? DayType.work;
    if (_selectedType != nextType) {
      setState(() {
        _selectedType = nextType;
      });
    }
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  bool _isFuture(DateTime day) {
    final today = dateOnly(DateTime.now());
    return day.isAfter(today);
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    if (_isFuture(selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pas de saisie dans le futur.')),
      );
      return;
    }
    setState(() {
      _selectedDay = dateOnly(selected);
      _focusedDay = dateOnly(focused);
      _errorMessage = null;
    });
    _syncForSelectedDay();
  }

  void _saveEntry() {
    final raw = _hoursController.text.trim();
    int? minutes;
    if (raw.isEmpty) {
      if (_selectedType == DayType.work) {
        setState(() {
          _errorMessage = 'Valeur invalide. Exemple: 7,5';
        });
        return;
      }
      minutes = 0;
    } else {
      minutes = parseDecimalHoursToMinutes(raw, allowZero: true);
    }
    if (minutes == null) {
      setState(() {
        _errorMessage = 'Valeur invalide. Exemple: 7,5';
      });
      return;
    }
    final data = widget.controller.data;
    final updatedEntries = Map<String, DayEntry>.from(data.entries);
    updatedEntries[dateKey(_selectedDay)] = DayEntry(
      minutes: minutes,
      type: _selectedType,
    );
    unawaited(
      widget.controller.update(data.copyWith(entries: updatedEntries)),
    );
  }

  void _clearEntry() {
    final data = widget.controller.data;
    final updatedEntries = Map<String, DayEntry>.from(data.entries);
    updatedEntries.remove(dateKey(_selectedDay));
    unawaited(
      widget.controller.update(data.copyWith(entries: updatedEntries)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.controller.data;
    final entries = data.entries;
    final localeCode = data.localeCode;
    final isFuture = _isFuture(_selectedDay);

    final periodRange = _format == CalendarFormat.week
        ? _weekRange(_focusedDay)
        : _monthRange(_focusedDay);
    final periodMinutes = sumEntriesInRange(
      entries,
      periodRange.start,
      periodRange.end,
      typeFilter: DayType.work,
    );
    final periodDays = countEntriesInRange(
      entries,
      periodRange.start,
      periodRange.end,
      typeFilter: DayType.work,
    );
    final periodRecupDays = countEntriesInRange(
      entries,
      periodRange.start,
      periodRange.end,
      typeFilter: DayType.recup,
    );
    final periodTarget = data.targetMinutes * (periodDays + periodRecupDays);
    final periodBalance = periodMinutes - periodTarget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Calendrier',
          subtitle: 'Selectionne un jour pour saisir tes heures.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton<CalendarFormat>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarFormat.month,
                      label: Text('Mois'),
                    ),
                    ButtonSegment(
                      value: CalendarFormat.week,
                      label: Text('Semaine'),
                    ),
                  ],
                  selected: {_format},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) {
                      return;
                    }
                    setState(() {
                      _format = selection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              TableCalendar<DayEntry>(
                locale: calendarLocaleFromCode(localeCode),
                focusedDay: _focusedDay,
                firstDay: DateTime(2020),
                lastDay: DateTime(2100),
                calendarFormat: _format,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: _onDaySelected,
                onPageChanged: (day) {
                  setState(() {
                    _focusedDay = dateOnly(day);
                  });
                },
                eventLoader: (day) {
                  final entry = entries[dateKey(day)];
                  if (entry == null) {
                    return const <DayEntry>[];
                  }
                  return <DayEntry>[entry];
                },
                enabledDayPredicate: (day) => !_isFuture(day),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) {
                      return null;
                    }
                    final entry = events.first;
                    final color = colorForDayType(entry.type, theme);
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              InfoRow(
                label: 'Total periode',
                value: Text(
                  formatDuration(Duration(minutes: periodMinutes)),
                ),
              ),
              InfoRow(
                label: 'Jours renseignes',
                value: Text('$periodDays'),
              ),
              InfoRow(
                label: 'Objectif periode',
                value: Text(
                  formatDuration(Duration(minutes: periodTarget)),
                ),
              ),
              InfoRow(
                label: 'Solde periode',
                value: Text(
                  formatSignedDuration(periodBalance),
                  style: TextStyle(
                    color: periodBalance >= 0
                        ? Colors.green
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Saisie du jour',
          subtitle: isFuture
              ? 'Pas de saisie autorisee dans le futur.'
              : 'Saisis le total d\'heures pour la date selectionnee.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${formatDateShort(_selectedDay)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DayType.values.map((type) {
                  return ChoiceChip(
                    label: Text(dayTypeLabel(type)),
                    selected: _selectedType == type,
                    onSelected: isFuture
                        ? null
                        : (_) {
                            setState(() {
                              _selectedType = type;
                              _errorMessage = null;
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _hoursController,
                enabled: !isFuture,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Heures du jour',
                  hintText: '7,5',
                  suffixText: 'h',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: isFuture ? null : _saveEntry,
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed:
                        isFuture || !entries.containsKey(dateKey(_selectedDay))
                            ? null
                            : _clearEntry,
                    child: const Text('Effacer'),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  _DateRange _weekRange(DateTime day) {
    final start = startOfWeek(day);
    final end = start.add(const Duration(days: 6));
    return _DateRange(start, end);
  }

  _DateRange _monthRange(DateTime day) {
    final start = DateTime(day.year, day.month, 1);
    final end = DateTime(day.year, day.month + 1, 0);
    return _DateRange(start, end);
  }
}

class _DateRange {
  const _DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}
