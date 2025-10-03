import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/calendar_settings.dart';
import '../models/theme_config.dart';

class SettingsProvider extends ChangeNotifier {
  CalendarSettings _settings = CalendarSettings(
    themeConfig: ThemeConfig.presetThemes[0],
  );

  CalendarSettings get settings => _settings;

  ThemeData get currentTheme {
    return _settings.isDarkMode
        ? ThemeData.dark().copyWith(
            primaryColor: _settings.themeConfig.primaryColor,
            colorScheme: ColorScheme.dark(
              primary: _settings.themeConfig.primaryColor,
              secondary: _settings.themeConfig.primaryColor,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: _settings.themeConfig.primaryColor,
              foregroundColor: Colors.white,
            ),
          )
        : ThemeData.light().copyWith(
            primaryColor: _settings.themeConfig.primaryColor,
            colorScheme: ColorScheme.light(
              primary: _settings.themeConfig.primaryColor,
              secondary: _settings.themeConfig.primaryColor,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: _settings.themeConfig.primaryColor,
              foregroundColor: Colors.white,
            ),
          );
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('settings');

      if (settingsJson != null) {
        final json = jsonDecode(settingsJson);
        _settings = CalendarSettings.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('settings', jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  Future<void> updateTheme(ThemeConfig theme) async {
    _settings = _settings.copyWith(themeConfig: theme);
    notifyListeners();
    await saveSettings();
  }

  Future<void> toggleDarkMode() async {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    notifyListeners();
    await saveSettings();
  }

  Future<void> updateWeekStartDay(int day) async {
    _settings = _settings.copyWith(weekStartDay: day);
    notifyListeners();
    await saveSettings();
  }
}
