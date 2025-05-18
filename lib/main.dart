import 'package:flutter/material.dart';
import 'package:music_sheet_pro/app/app.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  debugPrintBeginFrameBanner = true;
  debugPrintEndFrameBanner = true;

  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();

  FlutterError.onError = (FlutterErrorDetails details) {
    final errorString = details.toString();
    if (errorString.contains('multiple heroes that share the same tag')) {
      debugPrint('===== HERO TAG DUPLICADO DETECTADO =====');
      debugPrint(errorString);
      debugPrintStack(stackTrace: details.stack);
    }
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(const App());
}
