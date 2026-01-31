import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../localization/app_localizations.dart';
import '../notifications/notification_service.dart';
import '../widgets/app_background.dart';
import 'calendar_page.dart';
import 'pointage_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';
import 'theme_page.dart';

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
  void initState() {
    super.initState();
    widget.controller.addListener(_syncNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService.requestNotificationsPermission());
      _syncNotification();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncNotification();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncNotification);
    super.dispose();
  }

  void _syncNotification() {
    if (!mounted) {
      return;
    }
    final l10n = context.l10n;
    unawaited(
      NotificationService.updatePointageNotification(
        widget.controller.data,
        l10n,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(_titleForSection(l10n, _section)),
        ),
        drawer: _buildDrawer(context, l10n),
        body: AppBackground(
          backgroundId: widget.controller.data.backgroundId,
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

  Drawer _buildDrawer(BuildContext context, AppLocalizations l10n) {
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
                  l10n.appTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.tagline,
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
            label: l10n.sectionSettings,
            icon: Icons.tune,
          ),
          _drawerItem(
            context,
            section: HomeSection.theme,
            label: l10n.sectionTheme,
            icon: Icons.palette_outlined,
          ),
          _drawerItem(
            context,
            section: HomeSection.pointage,
            label: l10n.sectionPointage,
            icon: Icons.timer_outlined,
          ),
          _drawerItem(
            context,
            section: HomeSection.calendar,
            label: l10n.sectionCalendar,
            icon: Icons.calendar_month_outlined,
          ),
          _drawerItem(
            context,
            section: HomeSection.stats,
            label: l10n.sectionStats,
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

  String _titleForSection(AppLocalizations l10n, HomeSection section) {
    switch (section) {
      case HomeSection.settings:
        return l10n.sectionSettings;
      case HomeSection.theme:
        return l10n.sectionTheme;
      case HomeSection.pointage:
        return l10n.sectionPointage;
      case HomeSection.calendar:
        return l10n.sectionCalendar;
      case HomeSection.stats:
        return l10n.sectionStats;
    }
  }
}
