import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../controller/app_controller.dart';
import '../localization/app_localizations.dart';
import '../models/day_entry.dart';
import '../utils/break_utils.dart';
import '../utils/date_utils.dart';
import '../utils/format_utils.dart';
import '../utils/locale_utils.dart';
import '../utils/time_utils.dart';
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    final l10n = context.l10n;
    final entry = widget.controller.data.entries[dateKey(_selectedDay)];
    final next = entry == null || !isWorkDayType(entry.type)
        ? ''
        : formatDecimalHoursFromMinutes(
            entry.minutes,
            decimalSeparator: l10n.decimalSeparator,
          );
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
        SnackBar(content: Text(context.l10n.calendarFutureSnack)),
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

  void _jumpToToday() {
    final today = dateOnly(DateTime.now());
    setState(() {
      _selectedDay = today;
      _focusedDay = today;
      _errorMessage = null;
    });
    _syncForSelectedDay();
  }

  void _saveEntry() {
    final raw = _hoursController.text.trim();
    int? minutes;
    if (!isWorkDayType(_selectedType)) {
      minutes = 0;
    } else if (raw.isEmpty) {
      setState(() {
        _errorMessage = context.l10n.calendarInvalidValue;
      });
      return;
    } else {
      minutes = parseDecimalHoursToMinutes(raw, allowZero: true);
    }
    if (minutes == null) {
      setState(() {
        _errorMessage = context.l10n.calendarInvalidValue;
      });
      return;
    }
    final data = widget.controller.data;
    final updatedEntries = Map<String, DayEntry>.from(data.entries);
    final key = dateKey(_selectedDay);
    final existing = updatedEntries[key];
    if (existing != null &&
        isWorkDayType(existing.type) &&
        isWorkDayType(_selectedType)) {
      updatedEntries[key] = DayEntry(
        minutes: minutes,
        type: _selectedType,
        startTime: existing.startTime,
        endTime: existing.endTime,
        breaks: cloneBreaks(existing.breaks),
      );
    } else {
      updatedEntries[key] = DayEntry(
        minutes: minutes,
        type: _selectedType,
      );
    }
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

  Future<void> _exportData() async {
    final l10n = context.l10n;
    final entries = widget.controller.data.entries;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportEmpty)),
      );
      return;
    }
    final keys = entries.keys.toList()..sort();
    final buffer = StringBuffer();
    buffer.writeln('date;type;minutes;start;end;breaks');
    for (final key in keys) {
      final entry = entries[key];
      if (entry == null) {
        continue;
      }
      final start = entry.startTime == null ? '' : timeToStorage(entry.startTime!);
      final end = entry.endTime == null ? '' : timeToStorage(entry.endTime!);
      final breaks = entry.breaks.isEmpty
          ? ''
          : entry.breaks
              .map(
                (item) =>
                    '${timeToStorage(item.start)}-${timeToStorage(item.end)}',
              )
              .join('|');
      buffer.writeln(
        '$key;${dayTypeToString(entry.type)};${entry.minutes};$start;$end;$breaks',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final file = File('${dir.path}/compteur_export_$stamp.csv');
    await file.writeAsString(buffer.toString());

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.exportSaved(file.path))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.controller.data;
    final entries = data.entries;
    final localeCode = data.localeCode;
    final l10n = context.l10n;
    final isFuture = _isFuture(_selectedDay);

    final periodRange = _format == CalendarFormat.week
        ? _weekRange(_focusedDay)
        : _monthRange(_focusedDay);
    final periodWorkMinutes = sumEntriesInRange(
      entries,
      periodRange.start,
      periodRange.end,
      typeFilter: DayType.work,
    );
    final periodRecupMinutes = sumEntriesInRange(
      entries,
      periodRange.start,
      periodRange.end,
      typeFilter: DayType.recup,
    );
    final periodMinutes = periodWorkMinutes + periodRecupMinutes;
    final periodWorkDays = countEntriesInRange(
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
    final periodDays = periodWorkDays + periodRecupDays;
    final periodTarget = data.targetMinutes * periodWorkDays;
    final periodBalance = periodMinutes - periodTarget;

    final selectedEntry = entries[dateKey(_selectedDay)];
    final hasHistory = selectedEntry != null &&
        (selectedEntry.startTime != null ||
            selectedEntry.endTime != null ||
            selectedEntry.breaks.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: l10n.calendarTitle,
          subtitle: l10n.calendarSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _jumpToToday,
                    icon: const Icon(Icons.today),
                    label: Text(l10n.todayLabel),
                  ),
                  SegmentedButton<CalendarFormat>(
                    segments: [
                      ButtonSegment(
                        value: CalendarFormat.month,
                        label: Text(l10n.calendarMonth),
                      ),
                      ButtonSegment(
                        value: CalendarFormat.week,
                        label: Text(l10n.calendarWeek),
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
                  OutlinedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.download),
                    label: Text(l10n.exportLabel),
                  ),
                ],
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
                label: l10n.calendarTotalPeriod,
                value: Text(
                  formatDuration(Duration(minutes: periodMinutes)),
                ),
              ),
              InfoRow(
                label: l10n.calendarDaysEntered,
                value: Text('$periodDays'),
              ),
              InfoRow(
                label: l10n.calendarPeriodTarget,
                value: Text(
                  formatDuration(Duration(minutes: periodTarget)),
                ),
              ),
              InfoRow(
                label: l10n.calendarPeriodBalance,
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
          title: l10n.dayEntryTitle,
          subtitle:
              isFuture ? l10n.dayEntryFutureNotAllowed : l10n.dayEntrySubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dayEntryDateLabel(formatDateShort(_selectedDay)),
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
                    label: Text(dayTypeLabel(type, l10n)),
                    selected: _selectedType == type,
                    onSelected: isFuture
                        ? null
                        : (_) {
                            setState(() {
                              _selectedType = type;
                              _errorMessage = null;
                              if (!isWorkDayType(type)) {
                                _hoursController.text = '';
                              }
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _hoursController,
                enabled: !isFuture && isWorkDayType(_selectedType),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                ],
                decoration: InputDecoration(
                  labelText: l10n.dayEntryHoursLabel,
                  hintText: l10n.dayEntryHoursHint,
                  suffixText: 'h',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: isFuture ? null : _saveEntry,
                    icon: const Icon(Icons.save),
                    label: Text(l10n.settingsSave),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed:
                        isFuture || !entries.containsKey(dateKey(_selectedDay))
                            ? null
                            : _clearEntry,
                    child: Text(l10n.dayEntryClear),
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
        if (hasHistory) ...[
          const SizedBox(height: 16),
          _historyCard(theme, l10n, selectedEntry!),
        ],
      ],
    );
  }

  Widget _historyCard(ThemeData theme, AppLocalizations l10n, DayEntry entry) {
    final totalBreakMinutes = breakMinutes(entry.breaks);
    return SectionCard(
      title: l10n.historyTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.startTime != null)
            InfoRow(
              label: l10n.historyStart,
              value: Text(formatTimeOfDay(entry.startTime)),
            ),
          if (entry.endTime != null)
            InfoRow(
              label: l10n.historyEnd,
              value: Text(formatTimeOfDay(entry.endTime)),
            ),
          InfoRow(
            label: l10n.historyWorked,
            value: Text(formatDuration(Duration(minutes: entry.minutes))),
          ),
          InfoRow(
            label: l10n.historyBreaksTotal,
            value: Text(formatDuration(Duration(minutes: totalBreakMinutes))),
          ),
          if (entry.breaks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...entry.breaks.asMap().entries.map(
              (entryItem) {
                final index = entryItem.key + 1;
                final item = entryItem.value;
                final duration = breakDuration(item);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${l10n.breakLabel(index)} · ${formatTimeOfDay(item.start)} - ${formatTimeOfDay(item.end)} (${formatDuration(duration)})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
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
