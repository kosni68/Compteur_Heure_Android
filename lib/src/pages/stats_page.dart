import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../localization/app_localizations.dart';
import '../models/day_entry.dart';
import '../utils/break_utils.dart';
import '../utils/date_utils.dart';
import '../utils/format_utils.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';
import '../widgets/stats_charts.dart';

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

    final daily30 = _dailyMinutesInRange(
      entries,
      today.subtract(const Duration(days: 29)),
      today,
    );
    final daily30Avg = _movingAverage(daily30, window: 7);
    final daily90 = _dailyMinutesInRange(
      entries,
      today.subtract(const Duration(days: 89)),
      today,
    );
    final daily90Avg = _movingAverage(daily90, window: 7);

    final weeklyBuckets = _weeklyBuckets(entries, today, weeks: 12);
    final weeklyTotals =
        weeklyBuckets.map((item) => item.workMinutes.toDouble()).toList();
    final weeklyStacks = weeklyBuckets
        .map(
          (item) => StackedBarValue(
            base: item.workMinutes.toDouble(),
            top: item.breakMinutes.toDouble(),
          ),
        )
        .toList();

    final monthlySeries =
        _monthlyCumulative(entries, data.targetMinutes, today);
    final balanceSeries =
        _balanceCumulative(entries, data.targetMinutes, today, days: 90);

    final dayTypeCounts = _dayTypeCounts(entries);
    final donutSegments = _donutSegments(dayTypeCounts, theme, l10n);
    final donutLegend = donutSegments
        .map(
          (segment) => ChartLegendItem(
            color: segment.color,
            label: segment.label,
            value: segment.value.round().toString(),
          ),
        )
        .toList();
    final donutTotal =
        dayTypeCounts.values.fold<int>(0, (sum, item) => sum + item);

    final heatmapWeeks = _heatmapWeeks(entries, today, weeks: 12);
    final breakBuckets = _breakHistogram(entries);
    final scatterPoints = _startEndScatter(entries);

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
        const SizedBox(height: 20),
        Text(
          l10n.statsChartsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: l10n.statsDailyTrend30Title,
          subtitle: l10n.statsDailyTrendSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LineChart(
                series: [
                  ChartSeries(
                    values: daily30.map((value) => value.toDouble()).toList(),
                    color: theme.colorScheme.primary,
                    strokeWidth: 2.2,
                  ),
                  ChartSeries(
                    values:
                        daily30Avg.map((value) => value.toDouble()).toList(),
                    color: theme.colorScheme.secondary,
                    strokeWidth: 2,
                  ),
                ],
                emptyLabel: l10n.statsNoData,
              ),
              const SizedBox(height: 8),
              ChartLegend(
                items: [
                  ChartLegendItem(
                    color: theme.colorScheme.primary,
                    label: l10n.statsLegendDaily,
                  ),
                  ChartLegendItem(
                    color: theme.colorScheme.secondary,
                    label: l10n.statsLegendAverage7,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.statsDailyTrend90Title,
          subtitle: l10n.statsDailyTrendSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LineChart(
                series: [
                  ChartSeries(
                    values: daily90.map((value) => value.toDouble()).toList(),
                    color: theme.colorScheme.primary,
                    strokeWidth: 2.2,
                  ),
                  ChartSeries(
                    values:
                        daily90Avg.map((value) => value.toDouble()).toList(),
                    color: theme.colorScheme.secondary,
                    strokeWidth: 2,
                  ),
                ],
                emptyLabel: l10n.statsNoData,
              ),
              const SizedBox(height: 8),
              ChartLegend(
                items: [
                  ChartLegendItem(
                    color: theme.colorScheme.primary,
                    label: l10n.statsLegendDaily,
                  ),
                  ChartLegendItem(
                    color: theme.colorScheme.secondary,
                    label: l10n.statsLegendAverage7,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.statsWeeklyTotalsTitle,
          subtitle: l10n.statsWeeklyTotalsSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BarChart(
                values: weeklyTotals,
                highlightIndex: weeklyTotals.isEmpty ? null : weeklyTotals.length - 1,
                barColor: theme.colorScheme.primary,
                highlightColor: theme.colorScheme.secondary,
                emptyLabel: l10n.statsNoData,
              ),
              const SizedBox(height: 8),
              ChartLegend(
                items: [
                  ChartLegendItem(
                    color: theme.colorScheme.secondary,
                    label: l10n.statsWeek,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.statsMonthlyCumulativeTitle,
          subtitle: l10n.statsMonthlyCumulativeSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LineChart(
                series: [
                  ChartSeries(
                    values: monthlySeries.actual
                        .map((value) => value.toDouble())
                        .toList(),
                    color: theme.colorScheme.primary,
                    strokeWidth: 2.2,
                  ),
                  ChartSeries(
                    values: monthlySeries.target
                        .map((value) => value.toDouble())
                        .toList(),
                    color: theme.colorScheme.tertiary,
                    strokeWidth: 2,
                  ),
                ],
                emptyLabel: l10n.statsNoData,
              ),
              const SizedBox(height: 8),
              ChartLegend(
                items: [
                  ChartLegendItem(
                    color: theme.colorScheme.primary,
                    label: l10n.statsLegendActual,
                  ),
                  ChartLegendItem(
                    color: theme.colorScheme.tertiary,
                    label: l10n.targetLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.statsBalanceCumulativeTitle,
          subtitle: l10n.statsBalanceCumulativeSubtitle,
          child: LineChart(
            series: [
              ChartSeries(
                values: balanceSeries.map((value) => value.toDouble()).toList(),
                color: theme.colorScheme.primary,
                strokeWidth: 2.2,
              ),
            ],
            baseline: 0,
            emptyLabel: l10n.statsNoData,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.statsDayTypeDistributionTitle,
          subtitle: l10n.statsDayTypeDistributionSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DonutChart(
                segments: donutSegments,
                centerLabel: donutTotal == 0 ? null : '$donutTotal',
                emptyLabel: l10n.statsNoData,
              ),
              const SizedBox(height: 8),
              ChartLegend(items: donutLegend),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.statsWorkBreaksTitle,
          subtitle: l10n.statsWorkBreaksSubtitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StackedBarChart(
                values: weeklyStacks,
                baseColor: theme.colorScheme.primary,
                topColor: theme.colorScheme.secondary,
                emptyLabel: l10n.statsNoData,
              ),
              const SizedBox(height: 8),
              ChartLegend(
                items: [
                  ChartLegendItem(
                    color: theme.colorScheme.primary,
                    label: l10n.dayTypeWork,
                  ),
                  ChartLegendItem(
                    color: theme.colorScheme.secondary,
                    label: l10n.breaksLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.statsHeatmapTitle,
          subtitle: l10n.statsHeatmapSubtitle,
          child: HeatmapCalendar(
            weeks: heatmapWeeks,
            baseColor: theme.colorScheme.primary,
            emptyLabel: l10n.statsNoData,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.statsBreakHistogramTitle,
          subtitle: l10n.statsBreakHistogramSubtitle,
          child: HistogramChart(
            buckets: breakBuckets,
            labels: const ['0-10', '10-20', '20-30', '30+'],
            color: theme.colorScheme.primary,
            emptyLabel: l10n.statsNoData,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.statsStartEndScatterTitle,
          subtitle: l10n.statsStartEndScatterSubtitle,
          child: ScatterChart(
            points: scatterPoints,
            pointColor: theme.colorScheme.secondary,
            emptyLabel: l10n.statsNoData,
          ),
        ),
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

class _WeekBucket {
  _WeekBucket({
    required this.start,
    required this.end,
    required this.workMinutes,
    required this.breakMinutes,
  });

  final DateTime start;
  final DateTime end;
  final int workMinutes;
  final int breakMinutes;
}

class _CumulativeSeries {
  _CumulativeSeries({required this.actual, required this.target});

  final List<int> actual;
  final List<int> target;
}

List<int> _dailyMinutesInRange(
  Map<String, DayEntry> entries,
  DateTime start,
  DateTime end,
) {
  final values = <int>[];
  var current = dateOnly(start);
  final last = dateOnly(end);
  while (!current.isAfter(last)) {
    final entry = entries[dateKey(current)];
    final minutes = entry != null && isWorkDayType(entry.type) ? entry.minutes : 0;
    values.add(minutes);
    current = current.add(const Duration(days: 1));
  }
  return values;
}

List<int> _movingAverage(List<int> values, {required int window}) {
  if (values.isEmpty) {
    return const [];
  }
  final result = <int>[];
  var sum = 0;
  for (var i = 0; i < values.length; i++) {
    sum += values[i];
    if (i >= window) {
      sum -= values[i - window];
    }
    final denom = (i + 1) < window ? (i + 1) : window;
    result.add((sum / denom).round());
  }
  return result;
}

List<_WeekBucket> _weeklyBuckets(
  Map<String, DayEntry> entries,
  DateTime today, {
  required int weeks,
}) {
  final buckets = <_WeekBucket>[];
  var currentStart =
      startOfWeek(today).subtract(Duration(days: 7 * (weeks - 1)));
  for (var i = 0; i < weeks; i++) {
    final weekStart = currentStart.add(Duration(days: 7 * i));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final workMinutes = sumEntriesInRange(
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
    final breakMinutes = _sumBreakMinutesInRange(entries, weekStart, weekEnd);
    buckets.add(
      _WeekBucket(
        start: weekStart,
        end: weekEnd,
        workMinutes: workMinutes,
        breakMinutes: breakMinutes,
      ),
    );
  }
  return buckets;
}

_CumulativeSeries _monthlyCumulative(
  Map<String, DayEntry> entries,
  int targetMinutes,
  DateTime today,
) {
  final start = DateTime(today.year, today.month, 1);
  final values = <int>[];
  final target = <int>[];
  var current = dateOnly(start);
  final last = dateOnly(today);
  var cumulative = 0;
  var targetCumulative = 0;
  while (!current.isAfter(last)) {
    final entry = entries[dateKey(current)];
    if (entry != null && isWorkDayType(entry.type)) {
      cumulative += entry.minutes;
    }
    if (entry != null && entry.type == DayType.work) {
      targetCumulative += targetMinutes;
    }
    values.add(cumulative);
    target.add(targetCumulative);
    current = current.add(const Duration(days: 1));
  }
  return _CumulativeSeries(actual: values, target: target);
}

List<int> _balanceCumulative(
  Map<String, DayEntry> entries,
  int targetMinutes,
  DateTime today, {
  required int days,
}) {
  final values = <int>[];
  var current = dateOnly(today.subtract(Duration(days: days - 1)));
  final last = dateOnly(today);
  var cumulative = 0;
  var targetCumulative = 0;
  while (!current.isAfter(last)) {
    final entry = entries[dateKey(current)];
    if (entry != null && isWorkDayType(entry.type)) {
      cumulative += entry.minutes;
    }
    if (entry != null && entry.type == DayType.work) {
      targetCumulative += targetMinutes;
    }
    values.add(cumulative - targetCumulative);
    current = current.add(const Duration(days: 1));
  }
  return values;
}

int _sumBreakMinutesInRange(
  Map<String, DayEntry> entries,
  DateTime start,
  DateTime end,
) {
  final rangeStart = dateOnly(start);
  final rangeEnd = dateOnly(end);
  var total = 0;
  for (final entry in entries.entries) {
    final date = dateFromKey(entry.key);
    if (date == null) {
      continue;
    }
    if (!date.isBefore(rangeStart) && !date.isAfter(rangeEnd)) {
      if (!isWorkDayType(entry.value.type)) {
        continue;
      }
      total += breakMinutes(entry.value.breaks);
    }
  }
  return total;
}

Map<DayType, int> _dayTypeCounts(Map<String, DayEntry> entries) {
  final counts = <DayType, int>{};
  for (final entry in entries.values) {
    counts.update(entry.type, (value) => value + 1, ifAbsent: () => 1);
  }
  return counts;
}

List<DonutSegment> _donutSegments(
  Map<DayType, int> counts,
  ThemeData theme,
  AppLocalizations l10n,
) {
  const order = [
    DayType.work,
    DayType.recup,
    DayType.pause,
    DayType.conge,
    DayType.maladie,
    DayType.maladieEnfant,
    DayType.pont,
  ];
  final segments = <DonutSegment>[];
  for (final type in order) {
    final count = counts[type] ?? 0;
    if (count <= 0) {
      continue;
    }
    segments.add(
      DonutSegment(
        value: count.toDouble(),
        color: colorForDayType(type, theme),
        label: dayTypeLabel(type, l10n),
      ),
    );
  }
  return segments;
}

List<List<int>> _heatmapWeeks(
  Map<String, DayEntry> entries,
  DateTime today, {
  required int weeks,
}) {
  final columns = <List<int>>[];
  final firstWeekStart =
      startOfWeek(today).subtract(Duration(days: 7 * (weeks - 1)));
  for (var weekIndex = 0; weekIndex < weeks; weekIndex++) {
    final weekStart = firstWeekStart.add(Duration(days: 7 * weekIndex));
    final column = <int>[];
    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final day = weekStart.add(Duration(days: dayIndex));
      final entry = entries[dateKey(day)];
      final minutes =
          entry != null && isWorkDayType(entry.type) ? entry.minutes : 0;
      column.add(minutes);
    }
    columns.add(column);
  }
  return columns;
}

List<int> _breakHistogram(Map<String, DayEntry> entries) {
  final buckets = [0, 0, 0, 0];
  for (final entry in entries.values) {
    if (!isWorkDayType(entry.type)) {
      continue;
    }
    for (final pause in entry.breaks) {
      final minutes = breakDuration(pause).inMinutes;
      if (minutes < 10) {
        buckets[0] += 1;
      } else if (minutes < 20) {
        buckets[1] += 1;
      } else if (minutes < 30) {
        buckets[2] += 1;
      } else {
        buckets[3] += 1;
      }
    }
  }
  return buckets;
}

List<ScatterPoint> _startEndScatter(Map<String, DayEntry> entries) {
  final points = <ScatterPoint>[];
  for (final entry in entries.values) {
    if (!isWorkDayType(entry.type)) {
      continue;
    }
    final start = entry.startTime;
    final end = entry.endTime;
    if (start == null || end == null) {
      continue;
    }
    var startMinutes = start.hour * 60 + start.minute;
    var endMinutes = end.hour * 60 + end.minute;
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }
    points.add(
      ScatterPoint(
        x: startMinutes.toDouble(),
        y: endMinutes.toDouble(),
      ),
    );
  }
  return points;
}
