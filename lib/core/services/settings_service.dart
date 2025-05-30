// lib/core/services/settings_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_sheet_pro/core/models/app_settings.dart';
import 'package:music_sheet_pro/core/utils/logger.dart';

class SettingsService extends ChangeNotifier {
  static const String _settingsKey = 'app_settings';

  AppSettings _settings = const AppSettings();
  SharedPreferences? _prefs;
  bool _initialized = false;

  AppSettings get settings => _settings;
  bool get initialized => _initialized;

  /// Initialize the settings service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _initialized = true;
      Logger.info('SettingsService initialized');
    } catch (e, stackTrace) {
      Logger.error('Failed to initialize SettingsService', e, stackTrace);
      _initialized = true; // Continue with defaults
    }
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    try {
      final settingsJson = _prefs!.getString(_settingsKey);
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _settings = AppSettings.fromMap(settingsMap);
        notifyListeners();
        Logger.debug('Settings loaded from storage');
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to load settings', e, stackTrace);
      // Continue with default settings
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    try {
      final settingsJson = jsonEncode(_settings.toMap());
      await _prefs!.setString(_settingsKey, settingsJson);
      Logger.debug('Settings saved to storage');
    } catch (e, stackTrace) {
      Logger.error('Failed to save settings', e, stackTrace);
    }
  }

  /// Update settings and save
  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _saveSettings();
  }

  /// Update individual setting values
  Future<void> setDarkMode(bool isDarkMode) async {
    await updateSettings(_settings.copyWith(isDarkMode: isDarkMode));
  }

  Future<void> setDefaultZoomLevel(double zoomLevel) async {
    await updateSettings(_settings.copyWith(defaultZoomLevel: zoomLevel));
  }

  Future<void> setAutoScrollEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(autoScrollEnabled: enabled));
  }

  Future<void> setAutoScrollSpeed(int speed) async {
    await updateSettings(_settings.copyWith(autoScrollSpeed: speed));
  }

  Future<void> setDefaultSortOrder(SortOrder sortOrder) async {
    await updateSettings(_settings.copyWith(defaultSortOrder: sortOrder));
  }

  Future<void> setDefaultContentView(DefaultContentView contentView) async {
    await updateSettings(_settings.copyWith(defaultContentView: contentView));
  }

  Future<void> setShowThumbnails(bool showThumbnails) async {
    await updateSettings(_settings.copyWith(showThumbnails: showThumbnails));
  }

  Future<void> setConfirmDeleteActions(bool confirm) async {
    await updateSettings(_settings.copyWith(confirmDeleteActions: confirm));
  }

  Future<void> setMaxRecentFiles(int maxFiles) async {
    await updateSettings(_settings.copyWith(maxRecentFiles: maxFiles));
  }

  Future<void> setEnableAnalytics(bool enabled) async {
    await updateSettings(_settings.copyWith(enableAnalytics: enabled));
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    await updateSettings(const AppSettings());
    Logger.info('Settings reset to defaults');
  }

  /// Export settings as JSON string
  String exportSettings() {
    return jsonEncode(_settings.toMap());
  }

  /// Import settings from JSON string
  Future<bool> importSettings(String settingsJson) async {
    try {
      final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
      final importedSettings = AppSettings.fromMap(settingsMap);
      await updateSettings(importedSettings);
      Logger.info('Settings imported successfully');
      return true;
    } catch (e, stackTrace) {
      Logger.error('Failed to import settings', e, stackTrace);
      return false;
    }
  }
}
