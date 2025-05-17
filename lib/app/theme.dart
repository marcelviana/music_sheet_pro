import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF6200EE),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6200EE),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF6200EE),
        foregroundColor: Colors.white,
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: const Color(0xFF6200EE),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6200EE),
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeData.dark().canvasColor,
        foregroundColor: Colors.white,
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }
}