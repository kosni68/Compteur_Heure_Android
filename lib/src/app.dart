import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controller/app_controller.dart';
import 'data/app_storage.dart';
import 'localization/app_localizations.dart';
import 'pages/home_shell.dart';
import 'theme/app_theme.dart';
import 'theme/backgrounds.dart';
import 'utils/locale_utils.dart';
import 'widgets/app_background.dart';

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
        onGenerateTitle: (context) => context.l10n.appTitle,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: kSupportedLocales,
        home: const _SplashScreen(),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final seedColor = Color(controller.data.seedColor);
        final locale = localeFromCode(controller.data.localeCode);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.appTitle,
          theme: buildAppTheme(seedColor, Brightness.light),
          darkTheme: buildAppTheme(seedColor, Brightness.dark),
          themeMode: controller.data.themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: kSupportedLocales,
          locale: locale,
          home: HomeShell(controller: controller),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppBackground(
        backgroundId: kDefaultBackgroundId,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
