import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/utils/color_utils.dart';

void main() {
  group('ColorUtils Tests', () {
    test('Get contrast color for light background', () {
      final color = ColorUtils.getContrastColor(Colors.white);
      expect(color, Colors.black);
    });

    test('Get contrast color for dark background', () {
      final color = ColorUtils.getContrastColor(Colors.black);
      expect(color, Colors.white);
    });

    test('Get contrast color for mid-tone backgrounds', () {
      final lightColor = ColorUtils.getContrastColor(Colors.yellow);
      expect(lightColor, Colors.black);

      final darkColor = ColorUtils.getContrastColor(Colors.blue.shade900);
      expect(darkColor, Colors.white);
    });

    test('Lighten color', () {
      final original = Colors.blue;
      final lighter = ColorUtils.lighten(original);

      expect(
        HSLColor.fromColor(lighter).lightness,
        greaterThan(HSLColor.fromColor(original).lightness),
      );
    });

    test('Darken color', () {
      final original = Colors.blue;
      final darker = ColorUtils.darken(original);

      expect(
        HSLColor.fromColor(darker).lightness,
        lessThan(HSLColor.fromColor(original).lightness),
      );
    });

    test('Lighten with custom amount', () {
      final original = Colors.blue;
      final lighter = ColorUtils.lighten(original, 0.2);

      final originalLightness = HSLColor.fromColor(original).lightness;
      final lighterLightness = HSLColor.fromColor(lighter).lightness;

      expect(lighterLightness - originalLightness, closeTo(0.2, 0.01));
    });

    test('Darken with custom amount', () {
      final original = Colors.blue;
      final darker = ColorUtils.darken(original, 0.2);

      final originalLightness = HSLColor.fromColor(original).lightness;
      final darkerLightness = HSLColor.fromColor(darker).lightness;

      expect(originalLightness - darkerLightness, closeTo(0.2, 0.01));
    });

    test('Category colors are available', () {
      final colors = ColorUtils.categoryColors;

      expect(colors, isNotEmpty);
      expect(colors.length, greaterThan(10));
      expect(colors, contains(Colors.red));
      expect(colors, contains(Colors.blue));
      expect(colors, contains(Colors.green));
    });

    test('Lighten clamps at maximum', () {
      final almostWhite = Colors.grey.shade50;
      final lightened = ColorUtils.lighten(almostWhite, 0.5);

      final lightness = HSLColor.fromColor(lightened).lightness;
      expect(lightness, lessThanOrEqualTo(1.0));
    });

    test('Darken clamps at minimum', () {
      final almostBlack = Colors.grey.shade900;
      final darkened = ColorUtils.darken(almostBlack, 0.5);

      final lightness = HSLColor.fromColor(darkened).lightness;
      expect(lightness, greaterThanOrEqualTo(0.0));
    });
  });
}
