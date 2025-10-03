import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/models/theme_config.dart';

void main() {
  group('ThemeConfig Model Tests', () {
    test('Create theme config', () {
      final theme = ThemeConfig(
        name: 'Test Theme',
        primaryColor: Colors.blue,
        todayColor: Colors.blue.shade100,
      );

      expect(theme.name, 'Test Theme');
      expect(theme.primaryColor, Colors.blue);
      expect(theme.todayColor, Colors.blue.shade100);
    });

    test('Preset themes are available', () {
      final presets = ThemeConfig.presetThemes;

      expect(presets.length, greaterThan(0));
      expect(presets.any((t) => t.name == 'Blue'), true);
      expect(presets.any((t) => t.name == 'Green'), true);
      expect(presets.any((t) => t.name == 'Purple'), true);
    });

    test('toJson serializes theme correctly', () {
      final theme = ThemeConfig(
        name: 'Blue',
        primaryColor: Colors.blue,
        todayColor: Colors.blue.shade100,
      );

      final json = theme.toJson();

      expect(json['name'], 'Blue');
      expect(json['primaryColor'], Colors.blue.toARGB32());
      expect(json['todayColor'], Colors.blue.shade100.toARGB32());
    });

    test('fromJson deserializes theme correctly', () {
      final json = {
        'name': 'Green',
        'primaryColor': Colors.green.toARGB32(),
        'todayColor': Colors.green.shade100.toARGB32(),
      };

      final theme = ThemeConfig.fromJson(json);

      expect(theme.name, 'Green');
      expect(theme.primaryColor, Color(Colors.green.toARGB32()));
      expect(theme.todayColor, Color(Colors.green.shade100.toARGB32()));
    });

    test('fromJson handles missing data', () {
      final json = <String, dynamic>{};
      final theme = ThemeConfig.fromJson(json);

      expect(theme.name, 'Blue');
      expect(theme.primaryColor, Color(Colors.blue.toARGB32()));
    });
  });
}
