import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
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
            label: 'Statistiques',
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
        return 'Statistiques';
    }
  }
}
