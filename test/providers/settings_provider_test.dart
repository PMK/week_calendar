import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/providers/settings_provider.dart';
import 'package:week_calendar/models/theme_config.dart';

void main() {
  group('SettingsProvider Tests', () {
    late SettingsProvider provider;

    setUp(() {
      provider = SettingsProvider();
    });

    test('Initial settings are correct', () {
      expect(provider.settings.weekStartDay, 1); // Monday
      expect(provider.settings.isDarkMode, false);
      expect(provider.settings.themeConfig, isNotNull);
    });

    test('Current theme is generated correctly', () {
      final theme = provider.currentTheme;

      expect(theme, isNotNull);
      expect(theme.primaryColor, provider.settings.themeConfig.primaryColor);
    });

    test('Toggle dark mode', () async {
      expect(provider.settings.isDarkMode, false);

      await provider.toggleDarkMode();
      expect(provider.settings.isDarkMode, true);

      await provider.toggleDarkMode();
      expect(provider.settings.isDarkMode, false);
    });

    test('Update theme', () async {
      final newTheme = ThemeConfig.presetThemes[1];
      await provider.updateTheme(newTheme);

      expect(provider.settings.themeConfig.name, newTheme.name);
      expect(provider.settings.themeConfig.primaryColor, newTheme.primaryColor);
    });

    test('Update week start day', () async {
      await provider.updateWeekStartDay(7); // Sunday
      expect(provider.settings.weekStartDay, 7);

      await provider.updateWeekStartDay(1); // Monday
      expect(provider.settings.weekStartDay, 1);
    });

    test('Dark mode changes theme colors', () {
      final lightTheme = provider.currentTheme;
      expect(lightTheme.brightness, Brightness.light);

      provider.toggleDarkMode();
      final darkTheme = provider.currentTheme;
      expect(darkTheme.brightness, Brightness.dark);
    });
  });
}
