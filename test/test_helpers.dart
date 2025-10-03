import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:week_calendar/providers/calendar_provider.dart';
import 'package:week_calendar/providers/settings_provider.dart';
import 'package:week_calendar/providers/caldav_provider.dart';
import 'package:week_calendar/models/calendar_event.dart';

class TestHelpers {
  static CalendarEvent createTestEvent({
    String? id,
    String title = 'Test Event',
    DateTime? date,
    DateTime? endDate,
    bool isAllDay = false,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Color color = Colors.blue,
  }) {
    return CalendarEvent(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date ?? DateTime.now(),
      endDate: endDate,
      isAllDay: isAllDay,
      startTime: startTime,
      endTime: endTime,
      color: color,
      categories: [],
      alerts: [],
    );
  }

  static Widget createTestApp({
    required Widget child,
    SettingsProvider? settingsProvider,
    CalendarProvider? calendarProvider,
    CalDAVProvider? caldavProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => settingsProvider ?? SettingsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => caldavProvider ?? CalDAVProvider(),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, CalendarProvider>(
          create: (context) =>
              calendarProvider ??
              CalendarProvider(
                Provider.of<SettingsProvider>(context, listen: false),
              ),
          update: (context, settings, previous) =>
              previous ?? CalendarProvider(settings),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  static DateTime createDate(int year, int month, int day) {
    return DateTime(year, month, day);
  }

  static TimeOfDay createTime(int hour, int minute) {
    return TimeOfDay(hour: hour, minute: minute);
  }
}
