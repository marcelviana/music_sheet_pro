import 'package:flutter/material.dart';
import 'package:music_sheet_pro/app/app.dart';
import 'package:music_sheet_pro/core/services/service_locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();
  runApp(const App());
}