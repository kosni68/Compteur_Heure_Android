import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../models/day_entry.dart';
import '../utils/date_utils.dart';
import '../utils/format_utils.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final entries = data.entries;

    final workEntries =
        entries.values.where((entry) => isWorkDayType(entry.type));
    final totalMinutes =
        workEntries.fold<int>(0, (sum, entry) => sum + entry.minutes);
    final trackedDays =
        entries.values.where((entry) => isWorkDayType(entry.type)).length;
    final recupCount =
        entries.values.where((entry) => entry.type == DayType.recup).length;
    final targetTotal = data.targetMinutes * (trackedDays + recupCount);
    final balanceMinutes = totalMinutes - targetTotal;

    final averageMinutes = trackedDays == 0
        ? null
        : (totalMinutes / trackedDays).round();

    final bestEntry = _bestEntry(entries);
    final bestDate = bestEntry == null ? null : dateFromKey(bestEntry.key);

    final congeCount =
        entries.values.where((entry) => entry.type == DayType.conge).length;
    final maladieCount =
        entries.values.where((entry) => entry.type == DayType.maladie).length;
    final pontCount =
        entries.values.where((entry) => entry.type == DayType.pont).length;
    final today = dateOnly(DateTime.now());
    final weekStart = startOfWeek(today);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);
    final last7Start = today.subtract(const Duration(days: 6));

    final weekMinutes = sumEntriesInRange(
      entries,
      weekStart,
      weekEnd,
      typeFilter: DayType.work,
    );
    final monthMinutes = sumEntriesInRange(
      entries,
      monthStart,
      monthEnd,
      typeFilter: DayType.work,
    );
    final last7Minutes = sumEntriesInRange(
      entries,
      last7Start,
      today,
      typeFilter: DayType.work,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Compteur global',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                label: 'Total heures',
                value: Text(formatDuration(Duration(minutes: totalMinutes))),
              ),
              InfoRow(
                label: 'Jours renseignes',
                value: Text('$trackedDays'),
              ),
              InfoRow(
                label: 'Objectif cumule',
                value: Text(formatDuration(Duration(minutes: targetTotal))),
              ),
              InfoRow(
                label: 'Solde',
                value: Text(
                  formatSignedDuration(balanceMinutes),
                  style: TextStyle(
                    color: balanceMinutes >= 0
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
          title: 'Statistiques',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                label: 'Moyenne / jour',
                value: Text(
                  averageMinutes == null
                      ? '--'
                      : formatDuration(Duration(minutes: averageMinutes)),
                ),
              ),
              InfoRow(
                label: 'Meilleure journee',
                value: Text(
                  bestEntry == null || bestDate == null
                      ? '--'
                      : '${formatDateShort(bestDate)} · ${formatDuration(Duration(minutes: bestEntry.value.minutes))}',
                ),
              ),
              InfoRow(
                label: 'Semaine en cours',
                value: Text(
                  formatDuration(Duration(minutes: weekMinutes)),
                ),
              ),
              InfoRow(
                label: 'Mois en cours',
                value: Text(
                  formatDuration(Duration(minutes: monthMinutes)),
                ),
              ),
              InfoRow(
                label: '7 derniers jours',
                value: Text(
                  formatDuration(Duration(minutes: last7Minutes)),
                ),
              ),
            ],
          ),
        ),
        if (congeCount + maladieCount + pontCount + recupCount > 0) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Jours speciaux',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  label: 'Conge',
                  value: Text('$congeCount'),
                ),
                InfoRow(
                  label: 'Maladie',
                  value: Text('$maladieCount'),
                ),
                InfoRow(
                  label: 'Pont',
                  value: Text('$pontCount'),
                ),
                InfoRow(
                  label: 'Recup',
                  value: Text('$recupCount'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  MapEntry<String, DayEntry>? _bestEntry(Map<String, DayEntry> entries) {
    final workEntries = entries.entries
        .where((entry) => isWorkDayType(entry.value.type))
        .toList();
    if (workEntries.isEmpty) {
      return null;
    }
    return workEntries.reduce(
      (current, next) =>
          next.value.minutes > current.value.minutes ? next : current,
    );
  }
}

