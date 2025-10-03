import 'theme_config.dart';

class CalendarSettings {
  final int weekStartDay; // 1 = Monday, 7 = Sunday
  final ThemeConfig themeConfig;
  final bool isDarkMode;
  final String dateFormat;
  final String timeFormat;

  CalendarSettings({
    this.weekStartDay = 1,
    required this.themeConfig,
    this.isDarkMode = false,
    this.dateFormat = 'MMM d, yyyy',
    this.timeFormat = 'HH:mm',
  });

  CalendarSettings copyWith({
    int? weekStartDay,
    ThemeConfig? themeConfig,
    bool? isDarkMode,
    String? dateFormat,
    String? timeFormat,
  }) {
    return CalendarSettings(
      weekStartDay: weekStartDay ?? this.weekStartDay,
      themeConfig: themeConfig ?? this.themeConfig,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }

  Map<String, dynamic> toJson() => {
    'weekStartDay': weekStartDay,
    'themeConfig': themeConfig.toJson(),
    'isDarkMode': isDarkMode,
    'dateFormat': dateFormat,
    'timeFormat': timeFormat,
  };

  factory CalendarSettings.fromJson(Map<String, dynamic> json) {
    return CalendarSettings(
      weekStartDay: json['weekStartDay'] ?? 1,
      themeConfig: ThemeConfig.fromJson(json['themeConfig'] ?? {}),
      isDarkMode: json['isDarkMode'] ?? false,
      dateFormat: json['dateFormat'] ?? 'MMM d, yyyy',
      timeFormat: json['timeFormat'] ?? 'HH:mm',
    );
  }
}
