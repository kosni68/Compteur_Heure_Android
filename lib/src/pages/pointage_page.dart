import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../localization/app_localizations.dart';
import '../models/break_interval.dart';
import '../models/day_entry.dart';
import '../notifications/notification_service.dart';
import '../utils/break_utils.dart';
import '../utils/date_utils.dart';
import '../utils/format_utils.dart';
import '../utils/time_utils.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';

class PointagePage extends StatefulWidget {
  const PointagePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<PointagePage> createState() => _PointagePageState();
}

class _PointagePageState extends State<PointagePage>
    with TickerProviderStateMixin {
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<BreakInterval> _breaks = <BreakInterval>[];

  DateTime? _estimatedEndDateTime;
  Duration? _remaining;
  Duration? _targetWorkDuration;
  Duration? _estimatedBreakDuration;
  int _estimateDayOffset = 0;

  DateTime? _endDateTime;
  Duration? _presenceDuration;
  Duration? _workedDuration;
  Duration? _totalBreakDuration;
  int _actualDayOffset = 0;
  String? _estimateErrorMessage;
  String? _pointageErrorMessage;
  String? _currentDayKey;

  late final AnimationController _introController;
  Timer? _ticker;
  bool _syncing = false;
  bool _savingEntry = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    widget.controller.addListener(_onControllerChanged);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFromController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _ticker?.cancel();
    _introController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    _syncFromController();
  }

  void _syncFromController() {
    final data = widget.controller.data;
    _syncing = true;
    _startTime = data.startTime;
    _endTime = data.endTime;
    _breaks = cloneBreaks(data.breaks);
    _syncing = false;
    _recalculate();
  }

  void _onInputChanged() {
    if (_syncing) {
      return;
    }
    _updateControllerData();
    _recalculate();
  }

  void _updateControllerData() {
    final data = widget.controller.data;
    final trackingDayKey = _startTime == null
        ? data.trackingDayKey
        : dateKey(dateOnly(DateTime.now()));
    final updated = data.copyWith(
      startTime: _startTime,
      endTime: _endTime,
      breaks: cloneBreaks(_breaks),
      trackingDayKey: trackingDayKey,
    );
    unawaited(widget.controller.update(updated));
  }

  void _recalculate() {
    final l10n = context.l10n;
    final targetMinutes = widget.controller.data.targetMinutes;
    final targetDuration = Duration(minutes: targetMinutes);

    DateTime? estimatedEnd;
    Duration? remaining;
    Duration? estimatedBreak;
    int estimateOffset = 0;
    String? estimateError;

    DateTime? actualEnd;
    Duration? presence;
    Duration? worked;
    Duration? actualBreak;
    int actualOffset = 0;
    String? pointageError;
    DateTime? startBaseDate;

    if (_startTime == null) {
      estimateError = l10n.errorStartRequired;
      pointageError = l10n.errorStartRequired;
    } else {
      final now = DateTime.now();
      final baseDate = DateTime(now.year, now.month, now.day);
      startBaseDate = baseDate;
      final start = _dateTimeFromTimeOfDay(baseDate, _startTime!);

      final breakIntervals = _normalizeBreaks(baseDate, start, _breaks);

      if (targetMinutes > 0) {
        DateTime estimated = start.add(Duration(minutes: targetMinutes));
        Duration totalEstimatedBreak = Duration.zero;
        for (final interval in breakIntervals) {
          if (interval.start.isBefore(estimated)) {
            final duration = interval.end.difference(interval.start);
            totalEstimatedBreak += duration;
            estimated = estimated.add(duration);
          }
        }
        estimatedEnd = estimated;
        estimatedBreak = totalEstimatedBreak;
        estimateOffset = estimated
            .difference(DateTime(start.year, start.month, start.day))
            .inDays;
        remaining = estimated.difference(DateTime.now());
      }

      if (_endTime != null) {
        DateTime end = _dateTimeFromTimeOfDay(baseDate, _endTime!);
        if (end.isBefore(start)) {
          end = end.add(const Duration(days: 1));
        }
        actualEnd = end;
        actualOffset = end
            .difference(DateTime(start.year, start.month, start.day))
            .inDays;

        Duration totalBreak = Duration.zero;
        for (final interval in breakIntervals) {
          if (interval.start.isBefore(end)) {
            final effectiveEnd = interval.end.isAfter(end) ? end : interval.end;
            if (effectiveEnd.isAfter(interval.start)) {
              totalBreak += effectiveEnd.difference(interval.start);
            }
          }
        }

        presence = end.difference(start);
        worked = presence - totalBreak;
        if (worked.inMinutes <= 0) {
          pointageError = l10n.errorInvalidTimes;
          actualEnd = null;
          presence = null;
          worked = null;
          actualBreak = null;
          actualOffset = 0;
        } else {
          actualBreak = totalBreak;
        }
      }
    }

    setState(() {
      _targetWorkDuration = targetDuration;
      _estimatedEndDateTime = estimatedEnd;
      _estimatedBreakDuration = estimatedBreak;
      _estimateDayOffset = estimateOffset;
      _remaining = remaining;
      _estimateErrorMessage = estimateError;

      _endDateTime = actualEnd;
      _presenceDuration = presence;
      _workedDuration = worked;
      _totalBreakDuration = actualBreak;
      _actualDayOffset = actualOffset;
      _pointageErrorMessage = pointageError;
    });

    if (worked != null && startBaseDate != null) {
      _maybeSaveEntryForDate(worked, startBaseDate);
    }

    _updateNotificationSchedule(estimatedEnd);
  }

  void _updateCountdown() {
    if (!mounted) {
      return;
    }
    _checkDayRollover();
    final finish = _estimatedEndDateTime;
    if (finish == null) {
      if (_remaining != null) {
        setState(() {
          _remaining = null;
        });
      }
      return;
    }

    final remaining = finish.difference(DateTime.now());
    if (_remaining == null || remaining.inSeconds != _remaining!.inSeconds) {
      setState(() {
        _remaining = remaining;
      });
    }
  }

  void _checkDayRollover() {
    final todayKey = dateKey(dateOnly(DateTime.now()));
    if (_currentDayKey == null) {
      _currentDayKey = todayKey;
      return;
    }
    if (_currentDayKey == todayKey) {
      return;
    }
    _currentDayKey = todayKey;
    final data = widget.controller.data;
    if (data.trackingDayKey != todayKey &&
        data.endTime != null &&
        data.startTime != null) {
      final updated = data.copyWith(endTime: null, pauseStartTime: null);
      unawaited(widget.controller.update(updated));
    } else {
      _endTime = null;
      _endDateTime = null;
      _presenceDuration = null;
      _workedDuration = null;
      _totalBreakDuration = null;
      _actualDayOffset = 0;
      _pointageErrorMessage = null;
      _recalculate();
    }
  }

  void _updateNotificationSchedule(DateTime? estimatedEnd) {
    final data = widget.controller.data;
    if (!data.notifyEnabled || estimatedEnd == null || _endTime != null) {
      unawaited(NotificationService.cancelEndReminder());
      return;
    }
    unawaited(
      NotificationService.scheduleEndReminder(
        estimatedEnd: estimatedEnd,
        minutesBefore: data.notifyMinutesBefore,
        l10n: context.l10n,
      ),
    );
  }

  void _maybeSaveEntryForDate(Duration worked, DateTime startDate) {
    if (_savingEntry) {
      return;
    }
    final minutes = worked.inMinutes;
    if (minutes <= 0) {
      return;
    }

    final key = dateKey(dateOnly(startDate));
    final data = widget.controller.data;
    final existing = data.entries[key];
    if (existing != null &&
        existing.minutes == minutes &&
        existing.type == DayType.work) {
      return;
    }

    _savingEntry = true;
    final updatedEntries = Map<String, DayEntry>.from(data.entries);
    updatedEntries[key] = DayEntry(
      minutes: minutes,
      type: DayType.work,
      startTime: _startTime,
      endTime: _endTime,
      breaks: cloneBreaks(_breaks),
    );
    unawaited(
      widget.controller
          .update(data.copyWith(entries: updatedEntries))
          .whenComplete(() {
        _savingEntry = false;
      }),
    );
  }

  Future<void> _pickStartTime() async {
    final initial = _startTime ?? TimeOfDay.now();
    final picked = await _pickTime(initial);
    if (picked == null) {
      return;
    }
    setState(() {
      _startTime = picked;
    });
    _onInputChanged();
  }

  Future<void> _pickEndTime() async {
    final initial = _endTime ?? TimeOfDay.now();
    final picked = await _pickTime(initial);
    if (picked == null) {
      return;
    }
    setState(() {
      _endTime = picked;
    });
    _onInputChanged();
  }

  Future<void> _editBreakTime(int index, {required bool isStart}) async {
    final current = isStart ? _breaks[index].start : _breaks[index].end;
    final picked = await _pickTime(current);
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _breaks[index].start = picked;
      } else {
        _breaks[index].end = picked;
      }
    });
    _onInputChanged();
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  void _addBreak() {
    final fallback = _startTime ?? TimeOfDay.now();
    setState(() {
      _breaks.add(BreakInterval(start: fallback, end: fallback));
    });
    _onInputChanged();
  }

  void _removeBreak(int index) {
    setState(() {
      _breaks.removeAt(index);
    });
    _onInputChanged();
  }

  List<_BreakIntervalDateTime> _normalizeBreaks(
    DateTime baseDate,
    DateTime start,
    List<BreakInterval> breaks,
  ) {
    final normalized = <_BreakIntervalDateTime>[];
    DateTime cursor = start;
    for (final breakItem in breaks) {
      DateTime breakStart = _dateTimeFromTimeOfDay(baseDate, breakItem.start);
      while (breakStart.isBefore(cursor)) {
        breakStart = breakStart.add(const Duration(days: 1));
      }
      DateTime breakEnd = _dateTimeFromTimeOfDay(baseDate, breakItem.end);
      while (breakEnd.isBefore(breakStart)) {
        breakEnd = breakEnd.add(const Duration(days: 1));
      }
      normalized.add(_BreakIntervalDateTime(breakStart, breakEnd));
      cursor = breakEnd;
    }
    return normalized;
  }

  DateTime _dateTimeFromTimeOfDay(DateTime base, TimeOfDay time) {
    return DateTime(base.year, base.month, base.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggeredSection(
          index: 0,
          child: _header(theme),
        ),
        _staggeredSection(
          index: 1,
          child: _timeCard(theme),
        ),
        _staggeredSection(
          index: 2,
          child: _breaksCard(theme),
        ),
        _staggeredSection(
          index: 3,
          child: _resultCard(theme),
        ),
      ],
    );
  }

  Widget _staggeredSection({required int index, required Widget child}) {
    final animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(
        (index * 0.1).clamp(0.0, 0.9),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: child,
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appTitle,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.headerSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _timeCard(ThemeData theme) {
    final l10n = context.l10n;
    return SectionCard(
      title: l10n.sectionPointage,
      subtitle: l10n.timeCardSubtitle,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _timeButton(
            label: l10n.labelStart,
            value: formatTimeOfDay(_startTime),
            onTap: _pickStartTime,
          ),
          const Icon(Icons.arrow_forward),
          _timeButton(
            label: l10n.labelEnd,
            value: formatTimeOfDay(_endTime),
            onTap: _pickEndTime,
          ),
        ],
      ),
    );
  }

  Widget _breaksCard(ThemeData theme) {
    final l10n = context.l10n;
    final breakWidgets = <Widget>[];
    for (var i = 0; i < _breaks.length; i++) {
      breakWidgets.add(_breakItem(theme, i));
    }

    return SectionCard(
      title: l10n.breaksTitle,
      subtitle: l10n.breaksSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: Column(
              children: breakWidgets,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addBreak,
            icon: const Icon(Icons.add),
            label: Text(l10n.addBreak),
          ),
        ],
      ),
    );
  }

  Widget _breakItem(ThemeData theme, int index) {
    final l10n = context.l10n;
    final breakItem = _breaks[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.light ? 0.9 : 0.65,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.breakLabel(index + 1),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _timeButton(
                      label: l10n.labelStart,
                      value: formatTimeOfDay(breakItem.start),
                      onTap: () => _editBreakTime(index, isStart: true),
                    ),
                    const Icon(Icons.arrow_forward),
                    _timeButton(
                      label: l10n.labelEnd,
                      value: formatTimeOfDay(breakItem.end),
                      onTap: () => _editBreakTime(index, isStart: false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.deleteLabel,
            onPressed: () => _removeBreak(index),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(ThemeData theme) {
    final l10n = context.l10n;
    final estimatedEnd = _estimatedEndDateTime;
    final estimateDayLabel =
        _estimateDayOffset > 0 ? l10n.dayOffset(_estimateDayOffset) : null;
    final target = _targetWorkDuration;
    final estimatedBreaks = _estimatedBreakDuration;
    final remaining = _remaining;

    final end = _endDateTime;
    final worked = _workedDuration;
    final presence = _presenceDuration;
    final breaks = _totalBreakDuration;
    final actualDayLabel =
        _actualDayOffset > 0 ? l10n.dayOffset(_actualDayOffset) : null;

    final targetMinutes = widget.controller.data.targetMinutes;
    final balanceMinutes =
        worked == null ? null : worked.inMinutes - targetMinutes;
    final key = dateKey(dateOnly(DateTime.now()));
    final saved = worked == null
        ? false
        : (widget.controller.data.entries[key]?.minutes == worked.inMinutes &&
            widget.controller.data.entries[key]?.type == DayType.work);

    final hasPointage =
        end != null && worked != null && presence != null && breaks != null;
    late final DateTime endValue;
    late final Duration workedValue;
    late final Duration presenceValue;
    late final Duration breaksValue;
    if (hasPointage) {
      endValue = end!;
      workedValue = worked!;
      presenceValue = presence!;
      breaksValue = breaks!;
    }

    return SectionCard(
      title: l10n.resultTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.estimationTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          if (estimatedEnd == null) ...[
            if (_estimateErrorMessage != null) ...[
              Text(
                _estimateErrorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              l10n.estimateNeedStart,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ] else ...[
            Text(
              l10n.estimatedEndLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  formatTime(estimatedEnd),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (estimateDayLabel != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      estimateDayLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            if (target != null)
              InfoRow(
                label: l10n.targetLabel,
                value: Text(formatDuration(target)),
              ),
            if (estimatedBreaks != null)
              InfoRow(
                label: l10n.plannedBreaksLabel,
                value: Text(formatDuration(estimatedBreaks)),
              ),
            InfoRow(
              label: l10n.countdownLabel,
              value: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  formatRemaining(remaining, l10n),
                  key: ValueKey(remaining?.inSeconds ?? 0),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.pointageTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          if (_pointageErrorMessage != null) ...[
            Text(
              _pointageErrorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (_pointageErrorMessage == null &&
              (end == null ||
                  worked == null ||
                  presence == null ||
                  breaks == null))
            Text(
              l10n.pointageNeedEnd,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          else if (hasPointage) ...[
            Text(
              l10n.loggedEndLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  formatTime(endValue),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actualDayLabel != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      actualDayLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            InfoRow(
              label: l10n.workedDurationLabel,
              value: Text(formatDuration(workedValue)),
            ),
            InfoRow(
              label: l10n.breaksLabel,
              value: Text(formatDuration(breaksValue)),
            ),
            InfoRow(
              label: l10n.presenceLabel,
              value: Text(formatDuration(presenceValue)),
            ),
            if (balanceMinutes != null)
              InfoRow(
                label: l10n.balanceLabel,
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
            InfoRow(
              label: l10n.calendarStatusLabel,
              value: Text(saved ? l10n.savedYes : l10n.savedNo),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(
            theme.brightness == Brightness.light ? 0.7 : 0.45,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreakIntervalDateTime {
  const _BreakIntervalDateTime(this.start, this.end);

  final DateTime start;
  final DateTime end;
}
