import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final DateTime? endDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final String? location;
  final String? notes;
  final List<String> categories;
  final Color color;
  final List<EventAlert> alerts;
  final String? repeatRule;
  final List<String> invitees;
  final String? calendarId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    this.endDate,
    this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.location,
    this.notes,
    this.categories = const [],
    this.color = Colors.blue,
    this.alerts = const [],
    this.repeatRule,
    this.invitees = const [],
    this.calendarId,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAllDay,
    String? location,
    String? notes,
    List<String>? categories,
    Color? color,
    List<EventAlert>? alerts,
    String? repeatRule,
    List<String>? invitees,
    String? calendarId,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      categories: categories ?? this.categories,
      color: color ?? this.color,
      alerts: alerts ?? this.alerts,
      repeatRule: repeatRule ?? this.repeatRule,
      invitees: invitees ?? this.invitees,
      calendarId: calendarId ?? this.calendarId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'startTime': startTime != null
          ? '${startTime!.hour}:${startTime!.minute}'
          : null,
      'endTime': endTime != null ? '${endTime!.hour}:${endTime!.minute}' : null,
      'isAllDay': isAllDay ? 1 : 0,
      'location': location,
      'notes': notes,
      'categories': categories.join(','),
      'color': color.toARGB32(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'repeatRule': repeatRule,
      'invitees': invitees.join(','),
      'calendarId': calendarId,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      startTime: parseTime(json['startTime']),
      endTime: parseTime(json['endTime']),
      isAllDay: json['isAllDay'] == 1,
      location: json['location'],
      notes: json['notes'],
      categories: json['categories'] != null && json['categories'].isNotEmpty
          ? json['categories'].split(',')
          : [],
      color: Color(json['color'] ?? Colors.blue.toARGB32()),
      alerts: json['alerts'] != null
          ? (json['alerts'] as List).map((a) => EventAlert.fromJson(a)).toList()
          : [],
      repeatRule: json['repeatRule'],
      invitees: json['invitees'] != null && json['invitees'].isNotEmpty
          ? json['invitees'].split(',')
          : [],
      calendarId: json['calendarId'],
    );
  }
}

class EventAlert {
  final int minutesBefore;
  final String type; // 'notification' or 'email'

  EventAlert({required this.minutesBefore, this.type = 'notification'});

  Map<String, dynamic> toJson() => {
    'minutesBefore': minutesBefore,
    'type': type,
  };

  factory EventAlert.fromJson(Map<String, dynamic> json) => EventAlert(
    minutesBefore: json['minutesBefore'],
    type: json['type'] ?? 'notification',
  );

  @override
  String toString() {
    if (minutesBefore == 0) return 'At time of event';
    if (minutesBefore < 60) return '$minutesBefore minutes before';
    if (minutesBefore < 1440) return '${minutesBefore ~/ 60} hours before';
    return '${minutesBefore ~/ 1440} days before';
  }
}
