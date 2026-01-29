
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TimeCounterApp());
}

class TimeCounterApp extends StatefulWidget {
  const TimeCounterApp({super.key});

  @override
  State<TimeCounterApp> createState() => _TimeCounterAppState();
}

class _TimeCounterAppState extends State<TimeCounterApp> {
  AppController? _controller;
  late final AppStorage _storage;

  @override
  void initState() {
    super.initState();
    _storage = AppStorage();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _storage.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _controller = AppController(_storage, data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Compteur d'heures",
        home: const _SplashScreen(),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final seedColor = Color(controller.data.seedColor);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Compteur d'heures",
          theme: _buildTheme(seedColor, Brightness.light),
          darkTheme: _buildTheme(seedColor, Brightness.dark),
          themeMode: controller.data.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
          ],
          locale: const Locale('fr', 'FR'),
          home: HomeShell(controller: controller),
        );
      },
    );
  }
}

ThemeData _buildTheme(Color seedColor, Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  final isLight = brightness == Brightness.light;
  final fillColor = isLight
      ? Colors.white.withOpacity(0.9)
      : colorScheme.surface.withOpacity(0.5);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Sora',
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
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
    drawerTheme: DrawerThemeData(
      backgroundColor: colorScheme.surface,
    ),
  );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppBackground(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

enum HomeSection {
  settings,
  theme,
  pointage,
  calendar,
  stats,
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HomeSection _section = HomeSection.pointage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(_titleForSection(_section)),
        ),
        drawer: _buildDrawer(context),
        body: AppBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(20, 16 + kToolbarHeight, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _buildSectionPage(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionPage() {
    switch (_section) {
      case HomeSection.settings:
        return SettingsPage(controller: widget.controller);
      case HomeSection.theme:
        return ThemePage(controller: widget.controller);
      case HomeSection.pointage:
        return PointagePage(controller: widget.controller);
      case HomeSection.calendar:
        return CalendarPage(controller: widget.controller);
      case HomeSection.stats:
        return StatsPage(controller: widget.controller);
    }
  }

  Drawer _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.85),
                  theme.colorScheme.secondary.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Compteur d'heures",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Suivi simple, clair, et local.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(
            context,
            section: HomeSection.settings,
            label: 'Parametres',
            icon: Icons.tune,
          ),
          _drawerItem(
            context,
            section: HomeSection.theme,
            label: 'Theme',
            icon: Icons.palette_outlined,
          ),
          _drawerItem(
            context,
            section: HomeSection.pointage,
            label: 'Pointage du jour',
            icon: Icons.timer_outlined,
          ),
          _drawerItem(
            context,
            section: HomeSection.calendar,
            label: 'Calendrier',
            icon: Icons.calendar_month_outlined,
          ),
          _drawerItem(
            context,
            section: HomeSection.stats,
            label: 'Compteur tampon',
            icon: Icons.stacked_line_chart,
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required HomeSection section,
    required String label,
    required IconData icon,
  }) {
    final selected = _section == section;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: () {
        Navigator.of(context).pop();
        setState(() {
          _section = section;
        });
      },
    );
  }

  String _titleForSection(HomeSection section) {
    switch (section) {
      case HomeSection.settings:
        return 'Parametres';
      case HomeSection.theme:
        return 'Theme';
      case HomeSection.pointage:
        return 'Pointage du jour';
      case HomeSection.calendar:
        return 'Calendrier';
      case HomeSection.stats:
        return 'Compteur tampon';
    }
  }
}

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = brightness == Brightness.light
        ? const [
            Color(0xFFF8F1E7),
            Color(0xFFE2F0EE),
          ]
        : const [
            Color(0xFF0F172A),
            Color(0xFF111827),
          ];
    final glowA = brightness == Brightness.light
        ? const Color(0xFFFE6D73)
        : const Color(0xFF64748B);
    final glowB = brightness == Brightness.light
        ? const Color(0xFF3CB371)
        : const Color(0xFF0EA5E9);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -30,
            child: _GlowBlob(
              size: 220,
              color: glowA,
            ),
          ),
          Positioned(
            left: -60,
            bottom: 60,
            child: _GlowBlob(
              size: 180,
              color: glowB,
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

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

  DateTime? _endDateTime;
  Duration? _presenceDuration;
  Duration? _workedDuration;
  Duration? _totalBreakDuration;
  int _dayOffset = 0;
  String? _errorMessage;

  late final AnimationController _introController;
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
    _syncFromController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
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
    final updated = data.copyWith(
      startTime: _startTime,
      breaks: cloneBreaks(_breaks),
    );
    unawaited(widget.controller.update(updated));
  }

  void _clearResults([String? message]) {
    setState(() {
      _errorMessage = message;
      _endDateTime = null;
      _presenceDuration = null;
      _workedDuration = null;
      _totalBreakDuration = null;
      _dayOffset = 0;
    });
  }

  void _recalculate() {
    if (_startTime == null) {
      _clearResults("Renseigne l'heure de debut.");
      return;
    }
    if (_endTime == null) {
      _clearResults("Renseigne l'heure de fin.");
      return;
    }

    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);
    final start = _dateTimeFromTimeOfDay(baseDate, _startTime!);
    DateTime end = _dateTimeFromTimeOfDay(baseDate, _endTime!);
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    final breakIntervals = _normalizeBreaks(baseDate, start, _breaks);
    Duration totalBreak = Duration.zero;

    for (final interval in breakIntervals) {
      if (interval.start.isBefore(end)) {
        final effectiveEnd = interval.end.isAfter(end) ? end : interval.end;
        if (effectiveEnd.isAfter(interval.start)) {
          totalBreak += effectiveEnd.difference(interval.start);
        }
      }
    }

    final presence = end.difference(start);
    final worked = presence - totalBreak;
    if (worked.inMinutes <= 0) {
      _clearResults('Horaires invalides.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _endDateTime = end;
      _presenceDuration = presence;
      _workedDuration = worked;
      _totalBreakDuration = totalBreak;
      _dayOffset = end
          .difference(DateTime(start.year, start.month, start.day))
          .inDays;
    });

    _maybeSaveTodayEntry(worked);
  }

  void _maybeSaveTodayEntry(Duration worked) {
    if (_savingEntry) {
      return;
    }
    final minutes = worked.inMinutes;
    if (minutes <= 0) {
      return;
    }

    final key = dateKey(dateOnly(DateTime.now()));
    final data = widget.controller.data;
    if (data.entries[key] == minutes) {
      return;
    }

    _savingEntry = true;
    final updatedEntries = Map<String, int>.from(data.entries);
    updatedEntries[key] = minutes;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Compteur d'heures",
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Calcule le total de ta journee en tenant compte des pauses.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _timeCard(ThemeData theme) {
    return SectionCard(
      title: 'Pointage du jour',
      subtitle: 'Heure de debut et de fin (format 24h).',
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _timeButton(
            label: 'Debut',
            value: formatTimeOfDay(_startTime),
            onTap: _pickStartTime,
          ),
          const Icon(Icons.arrow_forward),
          _timeButton(
            label: 'Fin',
            value: formatTimeOfDay(_endTime),
            onTap: _pickEndTime,
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

    return SectionCard(
      title: 'Pauses',
      subtitle: "Les pauses sont interpretees dans l'ordre de la liste.",
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
                      label: 'Debut',
                      value: formatTimeOfDay(breakItem.start),
                      onTap: () => _editBreakTime(index, isStart: true),
                    ),
                    const Icon(Icons.arrow_forward),
                    _timeButton(
                      label: 'Fin',
                      value: formatTimeOfDay(breakItem.end),
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
    final end = _endDateTime;
    final worked = _workedDuration;
    final presence = _presenceDuration;
    final breaks = _totalBreakDuration;

    if (end == null || worked == null || presence == null || breaks == null) {
      return SectionCard(
        title: 'Resultat',
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
              "Renseigne l'heure de debut et l'heure de fin pour calculer la journee.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final dayLabel = _dayOffset > 0 ? 'J+$_dayOffset' : null;
    final key = dateKey(dateOnly(DateTime.now()));
    final saved = widget.controller.data.entries[key] == worked.inMinutes;

    return SectionCard(
      title: 'Resultat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heure de fin',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                formatTime(end),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (dayLabel != null) ...[
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
          InfoRow(
            label: 'Duree travail',
            value: Text(formatDuration(worked)),
          ),
          InfoRow(
            label: 'Pauses',
            value: Text(formatDuration(breaks)),
          ),
          InfoRow(
            label: 'Presence',
            value: Text(formatDuration(presence)),
          ),
          InfoRow(
            label: 'Calendrier',
            value: Text(saved ? 'Enregistre' : 'Non'),
          ),
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _objectiveController = TextEditingController();
  final FocusNode _objectiveFocus = FocusNode();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
    _syncFromController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _objectiveController.dispose();
    _objectiveFocus.dispose();
    super.dispose();
  }

  void _syncFromController() {
    if (!mounted) {
      return;
    }
    if (_objectiveFocus.hasFocus) {
      return;
    }
    _objectiveController.text = formatDecimalHoursFromMinutes(
      widget.controller.data.targetMinutes,
    );
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _saveObjective() {
    final minutes =
        parseDecimalHoursToMinutes(_objectiveController.text, allowZero: false);
    if (minutes == null) {
      setState(() {
        _errorMessage = "Objectif invalide. Exemple: 8,4";
      });
      return;
    }

    final data = widget.controller.data;
    final updated = data.copyWith(targetMinutes: minutes);
    unawaited(widget.controller.update(updated));
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Objectif journalier',
          subtitle: 'Par jour, en heures decimales (8,4 = 8h24).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _objectiveController,
                focusNode: _objectiveFocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Objectif',
                  hintText: '8,4',
                  suffixText: 'h',
                ),
                onSubmitted: (_) => _saveObjective(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _saveObjective,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ThemePage extends StatelessWidget {
  const ThemePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final selectedMode = data.themeMode;
    final selectedSeed = data.seedColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Mode',
          subtitle: 'Clair, sombre, ou automatique.',
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Clair'),
                icon: Icon(Icons.wb_sunny_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Sombre'),
                icon: Icon(Icons.nightlight_round),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Auto'),
                icon: Icon(Icons.settings_suggest_outlined),
              ),
            ],
            selected: {selectedMode},
            onSelectionChanged: (newSelection) {
              if (newSelection.isEmpty) {
                return;
              }
              final updated = data.copyWith(themeMode: newSelection.first);
              unawaited(controller.update(updated));
            },
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Couleur',
          subtitle: 'Choisis la teinte principale de l\'application.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _seedOptions
                .map(
                  (option) => _ThemeSeedChip(
                    option: option,
                    isSelected: option.color.value == selectedSeed,
                    onTap: () {
                      final updated = data.copyWith(
                        seedColor: option.color.value,
                      );
                      unawaited(controller.update(updated));
                    },
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Astuce: le mode sombre utilise la meme couleur mais sur un fond plus contraste.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

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
    final minutes = widget.controller.data.entries[dateKey(_selectedDay)];
    final next = minutes == null ? '' : formatDecimalHoursFromMinutes(minutes);
    if (_hoursController.text != next) {
      _hoursController.text = next;
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
    final minutes =
        parseDecimalHoursToMinutes(_hoursController.text, allowZero: true);
    if (minutes == null) {
      setState(() {
        _errorMessage = 'Valeur invalide. Exemple: 7,5';
      });
      return;
    }
    final data = widget.controller.data;
    final updatedEntries = Map<String, int>.from(data.entries);
    updatedEntries[dateKey(_selectedDay)] = minutes;
    unawaited(
      widget.controller.update(data.copyWith(entries: updatedEntries)),
    );
  }

  void _clearEntry() {
    final data = widget.controller.data;
    final updatedEntries = Map<String, int>.from(data.entries);
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
    final isFuture = _isFuture(_selectedDay);

    final periodRange = _format == CalendarFormat.week
        ? _weekRange(_focusedDay)
        : _monthRange(_focusedDay);
    final periodMinutes =
        sumEntriesInRange(entries, periodRange.start, periodRange.end);
    final periodDays =
        countEntriesInRange(entries, periodRange.start, periodRange.end);
    final periodTarget = data.targetMinutes * periodDays;
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
              TableCalendar<int>(
                locale: 'fr_FR',
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
                  final minutes = entries[dateKey(day)];
                  if (minutes == null || minutes == 0) {
                    return const [];
                  }
                  return [minutes];
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
                  markerDecoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
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

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = controller.data;
    final entries = data.entries;

    final totalMinutes = entries.values.fold<int>(0, (sum, value) => sum + value);
    final trackedDays = entries.length;
    final targetTotal = data.targetMinutes * trackedDays;
    final balanceMinutes = totalMinutes - targetTotal;

    final averageMinutes = trackedDays == 0
        ? null
        : (totalMinutes / trackedDays).round();

    final bestEntry = _bestEntry(entries);
    final bestDate = bestEntry == null ? null : dateFromKey(bestEntry.key);

    final today = dateOnly(DateTime.now());
    final weekStart = startOfWeek(today);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);
    final last7Start = today.subtract(const Duration(days: 6));

    final weekMinutes = sumEntriesInRange(entries, weekStart, weekEnd);
    final monthMinutes = sumEntriesInRange(entries, monthStart, monthEnd);
    final last7Minutes = sumEntriesInRange(entries, last7Start, today);

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
                      : '${formatDateShort(bestDate)} · ${formatDuration(Duration(minutes: bestEntry.value))}',
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
      ],
    );
  }

  MapEntry<String, int>? _bestEntry(Map<String, int> entries) {
    if (entries.isEmpty) {
      return null;
    }
    return entries.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final cardColor = theme.colorScheme.surface.withOpacity(isLight ? 0.92 : 0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          if (isLight)
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
              subtitle!,
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

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
}

class _ThemeSeedOption {
  const _ThemeSeedOption(this.label, this.color);

  final String label;
  final Color color;
}

const List<_ThemeSeedOption> _seedOptions = [
  _ThemeSeedOption('Menthe', Color(0xFF168377)),
  _ThemeSeedOption('Corail', Color(0xFFFE6D73)),
  _ThemeSeedOption('Ocean', Color(0xFF0EA5E9)),
  _ThemeSeedOption('Ambre', Color(0xFFF59E0B)),
  _ThemeSeedOption('Indigo', Color(0xFF4F46E5)),
  _ThemeSeedOption('Sable', Color(0xFFB08968)),
];

class _ThemeSeedChip extends StatelessWidget {
  const _ThemeSeedChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _ThemeSeedOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: option.color,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: option.color.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: isSelected
                ? Icon(Icons.check, color: theme.colorScheme.onPrimary)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            option.label,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class AppController extends ChangeNotifier {
  AppController(this._storage, this._data);

  final AppStorage _storage;
  AppData _data;

  AppData get data => _data;

  Future<void> update(AppData data) async {
    _data = data;
    notifyListeners();
    await _storage.save(_data);
  }
}

class AppStorage {
  static const String _fileName = 'compteur_data.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<AppData> load() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        if (raw.trim().isNotEmpty) {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          return AppData.fromJson(json);
        }
      }
    } catch (_) {}

    final migrated = await _loadFromPrefs();
    await save(migrated);
    return migrated;
  }

  Future<AppData> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetRaw = prefs.getString('targetHours');
      final startRaw = prefs.getString('startTime');
      final breaksRaw = prefs.getStringList('breaks');

      final targetMinutes =
          parseDecimalHoursToMinutes(targetRaw ?? '', allowZero: false) ??
              AppData.defaultTargetMinutes;

      return AppData(
        targetMinutes: targetMinutes,
        startTime: timeFromStorage(startRaw),
        breaks: breaksFromStorage(breaksRaw),
        entries: <String, int>{},
        themeMode: ThemeMode.light,
        seedColor: AppData.defaultSeedColor,
      );
    } catch (_) {
      return AppData.initial();
    }
  }

  Future<void> save(AppData data) async {
    final file = await _getFile();
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data.toJson()));
  }
}

const Object _unset = Object();

class AppData {
  AppData({
    required this.targetMinutes,
    required this.startTime,
    required this.breaks,
    required this.entries,
    required this.themeMode,
    required this.seedColor,
  });

  static const int defaultSeedColor = 0xFF168377;
  static final int defaultTargetMinutes =
      parseDecimalHoursToMinutes('8.4', allowZero: false) ?? 504;

  final int targetMinutes;
  final TimeOfDay? startTime;
  final List<BreakInterval> breaks;
  final Map<String, int> entries;
  final ThemeMode themeMode;
  final int seedColor;

  factory AppData.initial() {
    return AppData(
      targetMinutes: defaultTargetMinutes,
      startTime: null,
      breaks: const <BreakInterval>[],
      entries: <String, int>{},
      themeMode: ThemeMode.light,
      seedColor: defaultSeedColor,
    );
  }

  AppData copyWith({
    int? targetMinutes,
    Object? startTime = _unset,
    List<BreakInterval>? breaks,
    Map<String, int>? entries,
    ThemeMode? themeMode,
    int? seedColor,
  }) {
    return AppData(
      targetMinutes: targetMinutes ?? this.targetMinutes,
      startTime: startTime == _unset ? this.startTime : startTime as TimeOfDay?,
      breaks: breaks ?? cloneBreaks(this.breaks),
      entries: entries ?? Map<String, int>.from(this.entries),
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
    );
  }

  factory AppData.fromJson(Map<String, dynamic> json) {
    final rawTarget = json['targetMinutes'];
    int targetMinutes;
    if (rawTarget is int) {
      targetMinutes = rawTarget;
    } else if (rawTarget is double) {
      targetMinutes = rawTarget.round();
    } else {
      final legacy = json['targetHours'];
      targetMinutes = parseDecimalHoursToMinutes(
            legacy?.toString() ?? '',
            allowZero: false,
          ) ??
          defaultTargetMinutes;
    }

    final rawStart = json['startTime'];
    final startTime = rawStart is String ? timeFromStorage(rawStart) : null;

    final rawBreaks = json['breaks'];
    final breaks = breaksFromJson(rawBreaks);

    final rawEntries = json['entries'];
    final entries = <String, int>{};
    if (rawEntries is Map) {
      rawEntries.forEach((key, value) {
        if (key is! String) {
          return;
        }
        int? minutes;
        if (value is int) {
          minutes = value;
        } else if (value is double) {
          minutes = value.round();
        } else if (value is String) {
          minutes = int.tryParse(value);
        }
        if (minutes != null) {
          entries[key] = minutes;
        }
      });
    }

    final themeMode = themeModeFromString(json['themeMode'] as String?);
    final rawSeed = json['seedColor'];
    final seedColor = rawSeed is int ? rawSeed : defaultSeedColor;

    return AppData(
      targetMinutes: targetMinutes,
      startTime: startTime,
      breaks: breaks,
      entries: entries,
      themeMode: themeMode,
      seedColor: seedColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetMinutes': targetMinutes,
      'startTime': startTime == null ? null : timeToStorage(startTime!),
      'breaks': breaks
          .map(
            (breakItem) => {
              'start': timeToStorage(breakItem.start),
              'end': timeToStorage(breakItem.end),
            },
          )
          .toList(),
      'entries': entries,
      'themeMode': themeModeToString(themeMode),
      'seedColor': seedColor,
    };
  }
}

class BreakInterval {
  BreakInterval({required this.start, required this.end});

  TimeOfDay start;
  TimeOfDay end;

  BreakInterval copy() => BreakInterval(start: start, end: end);
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

class _DateRange {
  const _DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

List<BreakInterval> cloneBreaks(List<BreakInterval> source) {
  return source.map((item) => item.copy()).toList();
}

List<BreakInterval> breaksFromStorage(List<String>? raw) {
  if (raw == null) {
    return <BreakInterval>[];
  }
  final items = <BreakInterval>[];
  for (final entry in raw) {
    final parts = entry.split('|');
    if (parts.length != 2) {
      continue;
    }
    final start = timeFromStorage(parts[0]);
    final end = timeFromStorage(parts[1]);
    if (start == null || end == null) {
      continue;
    }
    items.add(BreakInterval(start: start, end: end));
  }
  return items;
}

List<BreakInterval> breaksFromJson(dynamic raw) {
  if (raw is List) {
    final items = <BreakInterval>[];
    for (final entry in raw) {
      if (entry is Map) {
        final startRaw = entry['start'];
        final endRaw = entry['end'];
        if (startRaw is String && endRaw is String) {
          final start = timeFromStorage(startRaw);
          final end = timeFromStorage(endRaw);
          if (start != null && end != null) {
            items.add(BreakInterval(start: start, end: end));
          }
        }
      } else if (entry is String) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final start = timeFromStorage(parts[0]);
          final end = timeFromStorage(parts[1]);
          if (start != null && end != null) {
            items.add(BreakInterval(start: start, end: end));
          }
        }
      }
    }
    return items;
  }
  return <BreakInterval>[];
}

TimeOfDay? timeFromStorage(String? value) {
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

String timeToStorage(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatTimeOfDay(TimeOfDay? time) {
  if (time == null) {
    return '--:--';
  }
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes.abs();
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h${minutes.toString().padLeft(2, '0')}';
}

String formatRemaining(Duration? remaining) {
  if (remaining == null) {
    return '--';
  }
  final abs = remaining.abs();
  if (abs.inMinutes == 0) {
    return remaining.isNegative ? 'A l\'instant' : "Moins d'une minute";
  }
  final formatted = formatDuration(abs);
  return remaining.isNegative ? 'Termine depuis $formatted' : '$formatted restant';
}

String formatDecimalHoursFromMinutes(int minutes) {
  final hours = minutes / 60.0;
  var value = hours.toStringAsFixed(2);
  value = value.replaceAll(RegExp(r'0+$'), '');
  value = value.replaceAll(RegExp(r'\.$'), '');
  return value.replaceAll('.', ',');
}

int? parseDecimalHoursToMinutes(String raw, {required bool allowZero}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final normalized = trimmed.replaceAll(',', '.');
  final value = double.tryParse(normalized);
  if (value == null) {
    return null;
  }
  if (allowZero) {
    if (value < 0) {
      return null;
    }
  } else {
    if (value <= 0) {
      return null;
    }
  }
  final minutes = (value * 60).round();
  if (!allowZero && minutes <= 0) {
    return null;
  }
  return minutes;
}

String formatSignedDuration(int minutes) {
  final absMinutes = minutes.abs();
  final formatted = formatDuration(Duration(minutes: absMinutes));
  return minutes >= 0 ? '+$formatted' : '-$formatted';
}

String formatDateShort(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime? dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

ThemeMode themeModeFromString(String? raw) {
  switch (raw) {
    case 'dark':
      return ThemeMode.dark;
    case 'system':
      return ThemeMode.system;
    case 'light':
    default:
      return ThemeMode.light;
  }
}

String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
    case ThemeMode.light:
    default:
      return 'light';
  }
}

DateTime startOfWeek(DateTime date) {
  final weekday = date.weekday; // 1 = Monday
  return dateOnly(date.subtract(Duration(days: weekday - 1)));
}

int sumEntriesInRange(
  Map<String, int> entries,
  DateTime start,
  DateTime end,
) {
  final rangeStart = dateOnly(start);
  final rangeEnd = dateOnly(end);
  int total = 0;
  for (final entry in entries.entries) {
    final date = dateFromKey(entry.key);
    if (date == null) {
      continue;
    }
    if (!date.isBefore(rangeStart) && !date.isAfter(rangeEnd)) {
      total += entry.value;
    }
  }
  return total;
}

int countEntriesInRange(
  Map<String, int> entries,
  DateTime start,
  DateTime end,
) {
  final rangeStart = dateOnly(start);
  final rangeEnd = dateOnly(end);
  int count = 0;
  for (final entry in entries.entries) {
    final date = dateFromKey(entry.key);
    if (date == null) {
      continue;
    }
    if (!date.isBefore(rangeStart) && !date.isAfter(rangeEnd)) {
      count++;
    }
  }
  return count;
}

