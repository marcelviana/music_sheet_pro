import 'package:flutter/material.dart';
import 'package:music_sheet_pro/presentation/library/library_screen.dart';
import 'package:music_sheet_pro/presentation/setlists/setlists_screen.dart';
import 'package:music_sheet_pro/presentation/viewer/viewer_screen.dart';
import 'package:music_sheet_pro/presentation/viewer/enhanced_pdf_viewer_screen.dart';
import 'package:music_sheet_pro/presentation/home/home_screen.dart';

// Em lib/app/routes.dart:
class AppRoutes {
  static const String home = '/';
  static const String library = '/library';
  static const String viewer = '/viewer';
  static const String setlists = '/setlists';
  static const String enhancedViewer = '/enhanced-viewer';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case library:
        return MaterialPageRoute(builder: (_) => const LibraryScreen());
      case viewer:
        final args = settings.arguments as ViewerScreenArgs?;
        return MaterialPageRoute(
            builder: (_) => ViewerScreen(musicId: args?.musicId));
      case setlists:
        return MaterialPageRoute(builder: (_) => const SetlistsScreen());
      case enhancedViewer:
        final args = settings.arguments as EnhancedViewerScreenArgs;
        return MaterialPageRoute(
          builder: (_) => EnhancedPdfViewerScreen(
            filePath: args.filePath,
            title: args.title,
            contentId: args.contentId,
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Rota não encontrada: ${settings.name}'),
            ),
          ),
        );
    }
  }
}

class EnhancedViewerScreenArgs {
  final String filePath;
  final String title;
  final String contentId;

  EnhancedViewerScreenArgs(
      {required this.filePath, required this.title, required this.contentId});
}

class ViewerScreenArgs {
  final String? musicId;

  ViewerScreenArgs({this.musicId});
}
