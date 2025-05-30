// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:music_sheet_pro/app/routes.dart';
import 'package:music_sheet_pro/app/theme.dart';
import 'package:music_sheet_pro/core/services/settings_service.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final SettingsService _settingsService;

  @override
  void initState() {
    super.initState();
    _settingsService = serviceLocator<SettingsService>();
    // Add listener to rebuild when settings change
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild with new theme
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settingsService.settings;

    return MaterialApp(
      title: 'MusicSheet Pro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
