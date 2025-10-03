import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/models/calendar_settings.dart';
import 'package:week_calendar/models/theme_config.dart';
import 'package:flutter/material.dart';

void main() {
  group('CalendarSettings Model Tests', () {
    test('Create settings with defaults', () {
      final settings = CalendarSettings(
        themeConfig: ThemeConfig.presetThemes[0],
      );

      expect(settings.weekStartDay, 1); // Monday
      expect(settings.isDarkMode, false);
      expect(settings.dateFormat, 'MMM d, yyyy');
      expect(settings.timeFormat, 'HH:mm');
    });

    test('Create settings with custom values', () {
      final theme = ThemeConfig(
        name: 'Custom',
        primaryColor: Colors.red,
        todayColor: Colors.red.shade100,
      );

      final settings = CalendarSettings(
        weekStartDay: 7, // Sunday
        themeConfig: theme,
        isDarkMode: true,
        dateFormat: 'dd/MM/yyyy',
        timeFormat: 'hh:mm a',
      );

      expect(settings.weekStartDay, 7);
      expect(settings.isDarkMode, true);
      expect(settings.dateFormat, 'dd/MM/yyyy');
      expect(settings.timeFormat, 'hh:mm a');
    });

    test('copyWith creates new instance', () {
      final original = CalendarSettings(
        themeConfig: ThemeConfig.presetThemes[0],
        isDarkMode: false,
      );

      final updated = original.copyWith(isDarkMode: true);

      expect(updated.isDarkMode, true);
      expect(updated.weekStartDay, original.weekStartDay);
    });

    test('toJson and fromJson work correctly', () {
      final original = CalendarSettings(
        weekStartDay: 7,
        themeConfig: ThemeConfig.presetThemes[1],
        isDarkMode: true,
      );

      final json = original.toJson();
      final restored = CalendarSettings.fromJson(json);

      expect(restored.weekStartDay, original.weekStartDay);
      expect(restored.isDarkMode, original.isDarkMode);
      expect(restored.themeConfig.name, original.themeConfig.name);
    });
  });
}
