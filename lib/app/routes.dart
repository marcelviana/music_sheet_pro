import 'package:flutter/material.dart';
import 'package:music_sheet_pro/presentation/library/library_screen.dart';
import 'package:music_sheet_pro/presentation/setlists/setlists_screen.dart';
import 'package:music_sheet_pro/presentation/viewer/viewer_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String library = '/library';
  static const String viewer = '/viewer';
  static const String setlists = '/setlists';
  
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
      case library:
        return MaterialPageRoute(builder: (_) => const LibraryScreen());
      case viewer:
        final args = settings.arguments as ViewerScreenArgs?;
        return MaterialPageRoute(builder: (_) => ViewerScreen(musicId: args?.musicId));
      case setlists:
        return MaterialPageRoute(builder: (_) => const SetlistsScreen());
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

class ViewerScreenArgs {
  final String? musicId;
  
  ViewerScreenArgs({this.musicId});
}