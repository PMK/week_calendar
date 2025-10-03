import 'package:flutter/material.dart';

class ThemeConfig {
  final Color primaryColor;
  final Color todayColor;
  final String name;

  ThemeConfig({
    required this.primaryColor,
    required this.todayColor,
    required this.name,
  });

  static List<ThemeConfig> get presetThemes => [
    ThemeConfig(
      name: 'Blue',
      primaryColor: Colors.blue,
      todayColor: Colors.blue.shade100,
    ),
    ThemeConfig(
      name: 'Green',
      primaryColor: Colors.green,
      todayColor: Colors.green.shade100,
    ),
    ThemeConfig(
      name: 'Purple',
      primaryColor: Colors.purple,
      todayColor: Colors.purple.shade100,
    ),
    ThemeConfig(
      name: 'Orange',
      primaryColor: Colors.deepOrangeAccent,
      todayColor: Colors.deepOrange,
    ),
    ThemeConfig(
      name: 'Teal',
      primaryColor: Colors.teal,
      todayColor: Colors.teal.shade100,
    ),
    ThemeConfig(
      name: 'Grayscale',
      primaryColor: Colors.grey.shade800,
      todayColor: Colors.grey.shade300,
    ),
  ];

  Map<String, dynamic> toJson() => {
    'name': name,
    'primaryColor': primaryColor.toARGB32(),
    'todayColor': todayColor.toARGB32(),
  };

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      name: json['name'] ?? 'Blue',
      primaryColor: Color(json['primaryColor'] ?? Colors.blue.toARGB32()),
      todayColor: Color(json['todayColor'] ?? Colors.blue.shade100.toARGB32()),
    );
  }
}
