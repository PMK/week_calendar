import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/providers/calendar_provider.dart';
import 'package:week_calendar/providers/settings_provider.dart';
import 'package:week_calendar/models/calendar_event.dart';
import '../test_helpers.dart';

void main() {
  group('CalendarProvider Tests', () {
    late SettingsProvider settingsProvider;
    late CalendarProvider calendarProvider;

    setUp(() {
      settingsProvider = SettingsProvider();
      calendarProvider = CalendarProvider(settingsProvider);
    });

    test('Initial state is correct', () {
      expect(calendarProvider.events, isEmpty);
      expect(calendarProvider.selectedEvent, isNull);
      expect(calendarProvider.mode, CalendarMode.normal);
      expect(calendarProvider.isLoading, false);
    });

    test('Get current week number and year', () {
      final now = DateTime.now();
      expect(calendarProvider.currentYear, now.year);
      expect(calendarProvider.currentWeekNumber, greaterThan(0));
    });

    test('isViewingToday returns correct value', () {
      expect(calendarProvider.isViewingToday, true);

      calendarProvider.nextWeek();
      expect(calendarProvider.isViewingToday, false);

      calendarProvider.goToToday();
      expect(calendarProvider.isViewingToday, true);
    });

    test('Get events for specific date', () {
      final date = DateTime(2024, 1, 15);
      final event = TestHelpers.createTestEvent(
        title: 'Test Event',
        date: date,
      );

      calendarProvider.events.add(event);

      final eventsForDate = calendarProvider.getEventsForDate(date);
      expect(eventsForDate.length, 1);
      expect(eventsForDate.first.title, 'Test Event');
    });

    test('Multi-day event appears on all days', () {
      final startDate = DateTime(2024, 1, 15);
      final endDate = DateTime(2024, 1, 17);
      final event = CalendarEvent(
        id: '1',
        title: 'Multi-Day',
        date: startDate,
        endDate: endDate,
        isAllDay: true,
        color: Colors.blue,
        categories: [],
        alerts: [],
      );

      calendarProvider.events.add(event);

      // Check all three days
      expect(
        calendarProvider.getEventsForDate(DateTime(2024, 1, 15)).length,
        1,
      );
      expect(
        calendarProvider.getEventsForDate(DateTime(2024, 1, 16)).length,
        1,
      );
      expect(
        calendarProvider.getEventsForDate(DateTime(2024, 1, 17)).length,
        1,
      );
      expect(
        calendarProvider.getEventsForDate(DateTime(2024, 1, 18)).length,
        0,
      );
    });

    test('Events are sorted correctly', () {
      final date = DateTime(2024, 1, 15);

      final event1 = CalendarEvent(
        id: '1',
        title: 'Morning',
        date: date,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        color: Colors.blue,
        categories: [],
        alerts: [],
      );

      final event2 = CalendarEvent(
        id: '2',
        title: 'All Day',
        date: date,
        isAllDay: true,
        color: Colors.green,
        categories: [],
        alerts: [],
      );

      final event3 = CalendarEvent(
        id: '3',
        title: 'Afternoon',
        date: date,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        color: Colors.red,
        categories: [],
        alerts: [],
      );

      calendarProvider.events.addAll([event1, event2, event3]);

      final sorted = calendarProvider.getEventsForDate(date);

      expect(sorted[0].title, 'All Day'); // All-day first
      expect(sorted[1].title, 'Morning'); // Then by time
      expect(sorted[2].title, 'Afternoon');
    });

    test('Navigate weeks', () {
      final initialDate = calendarProvider.selectedDate;

      calendarProvider.nextWeek();
      expect(calendarProvider.selectedDate.isAfter(initialDate), true);

      calendarProvider.previousWeek();
      expect(calendarProvider.selectedDate.day, initialDate.day);
    });

    test('Go to specific date', () {
      final targetDate = DateTime(2024, 6, 15);
      calendarProvider.goToDate(targetDate);

      expect(calendarProvider.selectedDate, targetDate);
    });

    test('Go to today', () {
      calendarProvider.goToDate(DateTime(2020, 1, 1));
      calendarProvider.goToToday();

      final today = DateTime.now();
      expect(calendarProvider.selectedDate.year, today.year);
      expect(calendarProvider.selectedDate.month, today.month);
      expect(calendarProvider.selectedDate.day, today.day);
    });

    test('Select and clear event', () {
      final event = TestHelpers.createTestEvent();

      calendarProvider.selectEvent(event);
      expect(calendarProvider.selectedEvent, event);

      calendarProvider.clearSelection();
      expect(calendarProvider.selectedEvent, isNull);
      expect(calendarProvider.mode, CalendarMode.normal);
    });

    test('Set mode', () {
      calendarProvider.setMode(CalendarMode.copy);
      expect(calendarProvider.mode, CalendarMode.copy);

      calendarProvider.setMode(CalendarMode.move);
      expect(calendarProvider.mode, CalendarMode.move);

      calendarProvider.setMode(CalendarMode.normal);
      expect(calendarProvider.mode, CalendarMode.normal);
    });

    test('Search functionality', () {
      final event1 = TestHelpers.createTestEvent(title: 'Meeting with John');
      final event2 = TestHelpers.createTestEvent(title: 'Lunch break');
      final event3 = TestHelpers.createTestEvent(title: 'Team meeting');

      calendarProvider.events.addAll([event1, event2, event3]);

      calendarProvider.search('meeting');

      expect(calendarProvider.searchResults.length, 2);
      expect(calendarProvider.searchResults[0].title, 'Meeting with John');
      expect(calendarProvider.searchResults[1].title, 'Team meeting');
    });

    test('Search is case-insensitive', () {
      final event = TestHelpers.createTestEvent(title: 'Important Event');
      calendarProvider.events.add(event);

      calendarProvider.search('important');
      expect(calendarProvider.searchResults.length, 1);

      calendarProvider.search('IMPORTANT');
      expect(calendarProvider.searchResults.length, 1);

      calendarProvider.search('ImPoRtAnT');
      expect(calendarProvider.searchResults.length, 1);
    });

    test('Search in location and notes', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Event',
        date: DateTime.now(),
        location: 'Conference Room',
        notes: 'Bring laptop',
        color: Colors.blue,
        categories: [],
        alerts: [],
      );

      calendarProvider.events.add(event);

      calendarProvider.search('Conference');
      expect(calendarProvider.searchResults.length, 1);

      calendarProvider.search('laptop');
      expect(calendarProvider.searchResults.length, 1);
    });

    test('Navigate search results', () {
      final event1 = TestHelpers.createTestEvent(title: 'Test 1');
      final event2 = TestHelpers.createTestEvent(title: 'Test 2');
      final event3 = TestHelpers.createTestEvent(title: 'Test 3');

      calendarProvider.events.addAll([event1, event2, event3]);
      calendarProvider.search('Test');

      expect(calendarProvider.currentSearchIndex, 0);
      expect(calendarProvider.canGoToPreviousResult, false);
      expect(calendarProvider.canGoToNextResult, true);

      calendarProvider.goToNextSearchResult();
      expect(calendarProvider.currentSearchIndex, 1);

      calendarProvider.goToNextSearchResult();
      expect(calendarProvider.currentSearchIndex, 2);
      expect(calendarProvider.canGoToNextResult, false);

      calendarProvider.goToPreviousSearchResult();
      expect(calendarProvider.currentSearchIndex, 1);
    });

    test('Clear search', () {
      final event = TestHelpers.createTestEvent(title: 'Test');
      calendarProvider.events.add(event);

      calendarProvider.search('Test');
      expect(calendarProvider.searchResults.length, 1);

      calendarProvider.clearSearch();
      expect(calendarProvider.searchResults.isEmpty, true);
      expect(calendarProvider.highlightedEventId, isNull);
    });
  });
}
