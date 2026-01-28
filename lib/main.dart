import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TimeCounterApp());
}

class TimeCounterApp extends StatelessWidget {
  const TimeCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF168377),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Compteur d'heures",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: 'Sora',
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      locale: const Locale('fr', 'FR'),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  static const _prefTargetKey = 'targetHours';
  static const _prefStartKey = 'startTime';
  static const _prefBreaksKey = 'breaks';

  final TextEditingController _targetController = TextEditingController();
  final FocusNode _targetFocus = FocusNode();

  SharedPreferences? _prefs;
  bool _loadingPrefs = true;

  TimeOfDay? _startTime;
  List<BreakInterval> _breaks = <BreakInterval>[];

  DateTime? _startDateTime;
  DateTime? _finishDateTime;
  Duration? _targetWorkDuration;
  Duration? _totalBreakDuration;
  Duration? _remaining;
  int _dayOffset = 0;
  String? _errorMessage;

  Timer? _ticker;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _targetController.addListener(_onInputChanged);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });
    _loadPrefs();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _introController.dispose();
    _targetController.removeListener(_onInputChanged);
    _targetController.dispose();
    _targetFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final target = prefs.getString(_prefTargetKey) ?? '';
    final start = _timeFromStorage(prefs.getString(_prefStartKey));
    final breaks = _breaksFromStorage(prefs.getStringList(_prefBreaksKey));

    _loadingPrefs = true;
    _targetController.text = target;
    if (!mounted) {
      return;
    }
    setState(() {
      _prefs = prefs;
      _startTime = start;
      _breaks = breaks;
      _loadingPrefs = false;
    });
    _recalculate();
  }

  void _onInputChanged() {
    if (_loadingPrefs) {
      return;
    }
    _queueSavePrefs();
    _recalculate();
  }

  void _queueSavePrefs() {
    if (_prefs == null) {
      return;
    }
    unawaited(_savePrefs());
  }

  Future<void> _savePrefs() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setString(_prefTargetKey, _targetController.text.trim());
    if (_startTime != null) {
      await prefs.setString(_prefStartKey, _timeToStorage(_startTime!));
    } else {
      await prefs.remove(_prefStartKey);
    }
    final breakStrings = _breaks
        .map((breakItem) =>
            '${_timeToStorage(breakItem.start)}|${_timeToStorage(breakItem.end)}')
        .toList();
    await prefs.setStringList(_prefBreaksKey, breakStrings);
  }

  void _clearResults([String? message]) {
    setState(() {
      _errorMessage = message;
      _startDateTime = null;
      _finishDateTime = null;
      _targetWorkDuration = null;
      _totalBreakDuration = null;
      _remaining = null;
      _dayOffset = 0;
    });
  }

  void _recalculate() {
    final workMinutes = _parseTargetMinutes();
    if (workMinutes == null) {
      final hasInput = _targetController.text.trim().isNotEmpty;
      _clearResults(
        hasInput ? "L'objectif doit être un nombre comme 8,4." : null,
      );
      return;
    }
    if (_startTime == null) {
      _clearResults("Renseigne l'heure de début.");
      return;
    }

    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);
    final start = _dateTimeFromTimeOfDay(baseDate, _startTime!);

    final breakIntervals = _normalizeBreaks(baseDate, start, _breaks);
    DateTime finish = start.add(Duration(minutes: workMinutes));
    Duration totalBreak = Duration.zero;

    for (final interval in breakIntervals) {
      if (interval.start.isBefore(finish)) {
        final duration = interval.end.difference(interval.start);
        totalBreak += duration;
        finish = finish.add(duration);
      }
    }

    final remaining = finish.difference(DateTime.now());
    setState(() {
      _errorMessage = null;
      _startDateTime = start;
      _finishDateTime = finish;
      _targetWorkDuration = Duration(minutes: workMinutes);
      _totalBreakDuration = totalBreak;
      _remaining = remaining;
      _dayOffset = finish
          .difference(DateTime(start.year, start.month, start.day))
          .inDays;
    });
  }

  void _updateCountdown() {
    if (!mounted) {
      return;
    }
    final finish = _finishDateTime;
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

  int? _parseTargetMinutes() {
    final raw = _targetController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    final normalized = raw.replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) {
      return null;
    }
    final minutes = (value * 60).round();
    if (minutes <= 0) {
      return null;
    }
    return minutes;
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

  Future<void> _editBreakTime(int index, {required bool isStart}) async {
    final current =
        isStart ? _breaks[index].start : _breaks[index].end;
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

  List<BreakInterval> _breaksFromStorage(List<String>? raw) {
    if (raw == null) {
      return <BreakInterval>[];
    }
    final items = <BreakInterval>[];
    for (final entry in raw) {
      final parts = entry.split('|');
      if (parts.length != 2) {
        continue;
      }
      final start = _timeFromStorage(parts[0]);
      final end = _timeFromStorage(parts[1]);
      if (start == null || end == null) {
        continue;
      }
      items.add(BreakInterval(start: start, end: end));
    }
    return items;
  }

  List<_BreakIntervalDateTime> _normalizeBreaks(
    DateTime baseDate,
    DateTime start,
    List<BreakInterval> breaks,
  ) {
    final normalized = <_BreakIntervalDateTime>[];
    DateTime cursor = start;
    for (final breakItem in breaks) {
      DateTime breakStart =
          _dateTimeFromTimeOfDay(baseDate, breakItem.start);
      while (breakStart.isBefore(cursor)) {
        breakStart = breakStart.add(const Duration(days: 1));
      }
      DateTime breakEnd =
          _dateTimeFromTimeOfDay(baseDate, breakItem.end);
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

  TimeOfDay? _timeFromStorage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeToStorage(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) {
      return '--:--';
    }
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes.abs();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }

  String _formatRemaining(Duration? remaining) {
    if (remaining == null) {
      return '--';
    }
    final abs = remaining.abs();
    if (abs.inMinutes == 0) {
      return remaining.isNegative ? "À l'instant" : "Moins d'une minute";
    }
    final formatted = _formatDuration(abs);
    return remaining.isNegative
        ? 'Terminé depuis $formatted'
        : '$formatted restant';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF8F1E7),
                Color(0xFFE2F0EE),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -80,
                top: -30,
                child: _GlowBlob(
                  size: 220,
                  color: Color(0xFFFE6D73),
                ),
              ),
              const Positioned(
                left: -60,
                bottom: 60,
                child: _GlowBlob(
                  size: 180,
                  color: Color(0xFF3CB371),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _staggeredSection(
                            index: 0,
                            child: _header(theme),
                          ),
                          _staggeredSection(
                            index: 1,
                            child: _objectiveCard(theme),
                          ),
                          _staggeredSection(
                            index: 2,
                            child: _startCard(theme),
                          ),
                          _staggeredSection(
                            index: 3,
                            child: _breaksCard(theme),
                          ),
                          _staggeredSection(
                            index: 4,
                            child: _resultCard(theme),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Compteur d'heures",
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Calcule l'heure de fin en tenant compte de toutes tes pauses.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _objectiveCard(ThemeData theme) {
    return _sectionCard(
      theme: theme,
      title: 'Objectif',
      subtitle: "Heures décimales (ex: 8,4 = 8h24).",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _targetController,
            focusNode: _targetFocus,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
            ],
            decoration: const InputDecoration(
              labelText: "Durée cible",
              hintText: '8,4',
              suffixText: 'h',
            ),
          ),
        ],
      ),
    );
  }

  Widget _startCard(ThemeData theme) {
    return _sectionCard(
      theme: theme,
      title: 'Pointage',
      subtitle: "Heure de début (format 24h).",
      child: Row(
        children: [
          Expanded(
            child: _timeButton(
              label: 'Début',
              value: _formatTimeOfDay(_startTime),
              onTap: _pickStartTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _breaksCard(ThemeData theme) {
    final breakWidgets = <Widget>[];
    for (var i = 0; i < _breaks.length; i++) {
      breakWidgets.add(_breakItem(theme, i));
    }

    return _sectionCard(
      theme: theme,
      title: 'Pauses',
      subtitle: "Les pauses sont interprétées dans l'ordre de la liste.",
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
            label: const Text('Ajouter une pause'),
          ),
        ],
      ),
    );
  }

  Widget _breakItem(ThemeData theme, int index) {
    final breakItem = _breaks[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
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
                  'Pause ${index + 1}',
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
                      label: 'Début',
                      value: _formatTimeOfDay(breakItem.start),
                      onTap: () => _editBreakTime(index, isStart: true),
                    ),
                    const Icon(Icons.arrow_forward),
                    _timeButton(
                      label: 'Fin',
                      value: _formatTimeOfDay(breakItem.end),
                      onTap: () => _editBreakTime(index, isStart: false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Supprimer',
            onPressed: () => _removeBreak(index),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(ThemeData theme) {
    final finish = _finishDateTime;
    if (finish == null) {
      return _sectionCard(
        theme: theme,
        title: 'Résultat',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              "Renseigne l'objectif et l'heure de début pour obtenir l'heure de fin.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final dayLabel = _dayOffset > 0 ? 'J+$_dayOffset' : null;
    final totalDuration = _startDateTime == null
        ? Duration.zero
        : finish.difference(_startDateTime!);

    return _sectionCard(
      theme: theme,
      title: 'Résultat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Heure de fin",
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                _formatTime(finish),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (dayLabel != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    dayLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(
            theme,
            'Objectif',
            Text(_formatDuration(_targetWorkDuration!)),
          ),
          _infoRow(
            theme,
            'Pauses',
            Text(_formatDuration(_totalBreakDuration!)),
          ),
          _infoRow(
            theme,
            'Durée totale',
            Text(_formatDuration(totalDuration)),
          ),
          _infoRow(
            theme,
            'Compteur',
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _formatRemaining(_remaining),
                key: ValueKey(_remaining?.inSeconds ?? 0),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          value,
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
          color: theme.colorScheme.surface.withOpacity(0.7),
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

  Widget _sectionCard({
    required ThemeData theme,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class BreakInterval {
  BreakInterval({required this.start, required this.end});

  TimeOfDay start;
  TimeOfDay end;
}

class _BreakIntervalDateTime {
  const _BreakIntervalDateTime(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
