import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../localization/app_localizations.dart';
import '../models/day_entry.dart';
import '../utils/break_utils.dart';
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
    final l10n = context.l10n;

    final hourEntries =
        entries.values.where((entry) => isWorkDayType(entry.type));
    final totalMinutes =
        hourEntries.fold<int>(0, (sum, entry) => sum + entry.minutes);
    final totalBreakMinutes = hourEntries.fold<int>(
      0,
      (sum, entry) => sum + breakMinutes(entry.breaks),
    );
    final trackedDays = hourEntries.length;
    final workDays =
        entries.values.where((entry) => isTargetDayType(entry.type)).length;
    final recupCount =
        entries.values.where((entry) => entry.type == DayType.recup).length;
    final targetTotal = data.targetMinutes * workDays;
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
    final maladieEnfantCount =
        entries.values.where((entry) => entry.type == DayType.maladieEnfant).length;
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
        ) +
        sumEntriesInRange(
          entries,
          weekStart,
          weekEnd,
          typeFilter: DayType.recup,
        );
    final monthMinutes = sumEntriesInRange(
          entries,
          monthStart,
          monthEnd,
          typeFilter: DayType.work,
        ) +
        sumEntriesInRange(
          entries,
          monthStart,
          monthEnd,
          typeFilter: DayType.recup,
        );
    final last7Minutes = sumEntriesInRange(
          entries,
          last7Start,
          today,
          typeFilter: DayType.work,
        ) +
        sumEntriesInRange(
          entries,
          last7Start,
          today,
          typeFilter: DayType.recup,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: l10n.statsGlobalTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                label: l10n.statsTotalHours,
                value: Text(formatDuration(Duration(minutes: totalMinutes))),
              ),
              InfoRow(
                label: l10n.statsTotalBreaks,
                value:
                    Text(formatDuration(Duration(minutes: totalBreakMinutes))),
              ),
              InfoRow(
                label: l10n.statsDaysTracked,
                value: Text('$trackedDays'),
              ),
              InfoRow(
                label: l10n.statsTargetTotal,
                value: Text(formatDuration(Duration(minutes: targetTotal))),
              ),
              InfoRow(
                label: l10n.statsBalance,
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
          title: l10n.statsTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(
                label: l10n.statsAverage,
                value: Text(
                  averageMinutes == null
                      ? '--'
                      : formatDuration(Duration(minutes: averageMinutes)),
                ),
              ),
              InfoRow(
                label: l10n.statsBestDay,
                value: Text(
                  bestEntry == null || bestDate == null
                      ? '--'
                      : '${formatDateShort(bestDate)} · ${formatDuration(Duration(minutes: bestEntry.value.minutes))}',
                ),
              ),
              InfoRow(
                label: l10n.statsWeek,
                value: Text(
                  formatDuration(Duration(minutes: weekMinutes)),
                ),
              ),
              InfoRow(
                label: l10n.statsMonth,
                value: Text(
                  formatDuration(Duration(minutes: monthMinutes)),
                ),
              ),
              InfoRow(
                label: l10n.statsLast7,
                value: Text(
                  formatDuration(Duration(minutes: last7Minutes)),
                ),
              ),
            ],
          ),
        ),
        if (congeCount + maladieCount + maladieEnfantCount + pontCount + recupCount > 0) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.statsSpecialDays,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  label: l10n.dayTypeConge,
                  value: Text('$congeCount'),
                ),
                InfoRow(
                  label: l10n.dayTypeMaladie,
                  value: Text('$maladieCount'),
                ),
                InfoRow(
                  label: l10n.dayTypeMaladieEnfant,
                  value: Text('$maladieEnfantCount'),
                ),
                InfoRow(
                  label: l10n.dayTypePont,
                  value: Text('$pontCount'),
                ),
                InfoRow(
                  label: l10n.dayTypeRecup,
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
