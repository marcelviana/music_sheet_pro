import 'package:flutter/material.dart';
import 'package:music_sheet_pro/app/app.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';
import 'package:music_sheet_pro/core/services/settings_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  GoogleFonts.config.allowRuntimeFetching = false;

  debugPrintBeginFrameBanner = true;
  debugPrintEndFrameBanner = true;

  WidgetsFlutterBinding.ensureInitialized();

  // Inicialize sqflite_common_ffi apenas no desktop!
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  setupServiceLocator();

  final settingsService = serviceLocator<SettingsService>();
  await settingsService.initialize();

  runApp(const App());
}
