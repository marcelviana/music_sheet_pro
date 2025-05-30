import 'package:flutter/material.dart';

enum SortOrder {
  titleAsc('Título A-Z'),
  titleDesc('Título Z-A'),
  artistAsc('Artista A-Z'),
  artistDesc('Artista Z-A'),
  dateCreatedAsc('Mais antigos'),
  dateCreatedDesc('Mais recentes'),
  favorites('Favoritos primeiro');

  const SortOrder(this.displayName);
  final String displayName;
}

enum DefaultContentView {
  list('Lista'),
  grid('Grade'),
  compact('Compacto');

  const DefaultContentView(this.displayName);
  final String displayName;
}

class AppSettings {
  final bool isDarkMode;
  final double defaultZoomLevel;
  final bool autoScrollEnabled;
  final int autoScrollSpeed;
  final SortOrder defaultSortOrder;
  final DefaultContentView defaultContentView;
  final bool showThumbnails;
  final bool confirmDeleteActions;
  final int maxRecentFiles;
  final bool enableAnalytics;

  const AppSettings({
    this.isDarkMode = false,
    this.defaultZoomLevel = 1.0,
    this.autoScrollEnabled = false,
    this.autoScrollSpeed = 2,
    this.defaultSortOrder = SortOrder.titleAsc,
    this.defaultContentView = DefaultContentView.list,
    this.showThumbnails = true,
    this.confirmDeleteActions = true,
    this.maxRecentFiles = 10,
    this.enableAnalytics = true,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    double? defaultZoomLevel,
    bool? autoScrollEnabled,
    int? autoScrollSpeed,
    SortOrder? defaultSortOrder,
    DefaultContentView? defaultContentView,
    bool? showThumbnails,
    bool? confirmDeleteActions,
    int? maxRecentFiles,
    bool? enableAnalytics,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      defaultZoomLevel: defaultZoomLevel ?? this.defaultZoomLevel,
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
      defaultContentView: defaultContentView ?? this.defaultContentView,
      showThumbnails: showThumbnails ?? this.showThumbnails,
      confirmDeleteActions: confirmDeleteActions ?? this.confirmDeleteActions,
      maxRecentFiles: maxRecentFiles ?? this.maxRecentFiles,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDarkMode': isDarkMode,
      'defaultZoomLevel': defaultZoomLevel,
      'autoScrollEnabled': autoScrollEnabled,
      'autoScrollSpeed': autoScrollSpeed,
      'defaultSortOrder': defaultSortOrder.name,
      'defaultContentView': defaultContentView.name,
      'showThumbnails': showThumbnails,
      'confirmDeleteActions': confirmDeleteActions,
      'maxRecentFiles': maxRecentFiles,
      'enableAnalytics': enableAnalytics,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      isDarkMode: map['isDarkMode'] ?? false,
      defaultZoomLevel: (map['defaultZoomLevel'] ?? 1.0).toDouble(),
      autoScrollEnabled: map['autoScrollEnabled'] ?? false,
      autoScrollSpeed: map['autoScrollSpeed'] ?? 2,
      defaultSortOrder: SortOrder.values.firstWhere(
        (e) => e.name == map['defaultSortOrder'],
        orElse: () => SortOrder.titleAsc,
      ),
      defaultContentView: DefaultContentView.values.firstWhere(
        (e) => e.name == map['defaultContentView'],
        orElse: () => DefaultContentView.list,
      ),
      showThumbnails: map['showThumbnails'] ?? true,
      confirmDeleteActions: map['confirmDeleteActions'] ?? true,
      maxRecentFiles: map['maxRecentFiles'] ?? 10,
      enableAnalytics: map['enableAnalytics'] ?? true,
    );
  }

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
