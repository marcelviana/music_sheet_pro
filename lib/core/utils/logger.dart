import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class Logger {
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message) {
    _log(LogLevel.info, message);
  }

  static void warning(String message, [Object? error]) {
    _log(LogLevel.warning, message, error);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(LogLevel level, String message,
      [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = '[${level.name.toUpperCase()}] $timestamp';

    developer.log(
      '$prefix: $message',
      error: error,
      stackTrace: stackTrace,
      level: _getLevelValue(level),
    );
  }

  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
