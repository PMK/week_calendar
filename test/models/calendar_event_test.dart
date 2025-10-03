import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/models/calendar_event.dart';

void main() {
  group('CalendarEvent Model Tests', () {
    test('Create event with required fields', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Test Event',
        date: DateTime(2024, 1, 15),
        color: Colors.blue,
        categories: [],
        alerts: [],
      );

      expect(event.id, '1');
      expect(event.title, 'Test Event');
      expect(event.date, DateTime(2024, 1, 15));
      expect(event.isAllDay, false);
      expect(event.color, Colors.blue);
    });

    test('Create all-day event', () {
      final event = CalendarEvent(
        id: '2',
        title: 'All Day Event',
        date: DateTime(2024, 1, 15),
        isAllDay: true,
        color: Colors.green,
        categories: [],
        alerts: [],
      );

      expect(event.isAllDay, true);
      expect(event.startTime, null);
      expect(event.endTime, null);
    });

    test('Create timed event', () {
      final event = CalendarEvent(
        id: '3',
        title: 'Timed Event',
        date: DateTime(2024, 1, 15),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        color: Colors.red,
        categories: [],
        alerts: [],
      );

      expect(event.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(event.endTime, const TimeOfDay(hour: 10, minute: 0));
      expect(event.isAllDay, false);
    });

    test('Create multi-day event', () {
      final event = CalendarEvent(
        id: '4',
        title: 'Multi-Day Event',
        date: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 1, 17),
        isAllDay: true,
        color: Colors.purple,
        categories: [],
        alerts: [],
      );

      expect(event.endDate, DateTime(2024, 1, 17));
      expect(event.endDate!.difference(event.date).inDays, 2);
    });

    test('copyWith creates new instance with updated values', () {
      final original = CalendarEvent(
        id: '5',
        title: 'Original',
        date: DateTime(2024, 1, 15),
        color: Colors.blue,
        categories: [],
        alerts: [],
      );

      final updated = original.copyWith(title: 'Updated', color: Colors.red);

      expect(updated.id, '5');
      expect(updated.title, 'Updated');
      expect(updated.color, Colors.red);
      expect(updated.date, DateTime(2024, 1, 15));
    });

    test('toJson serializes event correctly', () {
      final event = CalendarEvent(
        id: '6',
        title: 'Serialization Test',
        date: DateTime(2024, 1, 15),
        startTime: const TimeOfDay(hour: 9, minute: 30),
        location: 'Office',
        notes: 'Test notes',
        color: Colors.blue,
        categories: ['Work'],
        alerts: [EventAlert(minutesBefore: 15)],
      );

      final json = event.toJson();

      expect(json['id'], '6');
      expect(json['title'], 'Serialization Test');
      expect(json['startTime'], '9:30');
      expect(json['location'], 'Office');
      expect(json['notes'], 'Test notes');
      expect(json['categories'], 'Work');
    });

    test('fromJson deserializes event correctly', () {
      final json = {
        'id': '7',
        'title': 'Deserialization Test',
        'date': '2024-01-15T00:00:00.000',
        'startTime': '14:30',
        'endTime': '15:30',
        'isAllDay': 0,
        'location': 'Home',
        'notes': 'Test notes',
        'categories': 'Personal',
        'color': Colors.green.toARGB32(),
        'alerts': [],
        'repeatRule': 'Never',
        'invitees': '',
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.id, '7');
      expect(event.title, 'Deserialization Test');
      expect(event.startTime, const TimeOfDay(hour: 14, minute: 30));
      expect(event.endTime, const TimeOfDay(hour: 15, minute: 30));
      expect(event.location, 'Home');
      expect(event.categories, ['Personal']);
    });

    test('EventAlert formats correctly', () {
      final alert1 = EventAlert(minutesBefore: 0);
      expect(alert1.toString(), 'At time of event');

      final alert2 = EventAlert(minutesBefore: 15);
      expect(alert2.toString(), '15 minutes before');

      final alert3 = EventAlert(minutesBefore: 60);
      expect(alert3.toString(), '1 hours before');

      final alert4 = EventAlert(minutesBefore: 1440);
      expect(alert4.toString(), '1 days before');
    });
  });
}
