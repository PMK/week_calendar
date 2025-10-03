import 'package:week_calendar/models/calendar_event.dart';

class MockStorageService {
  final List<CalendarEvent> _events = [];

  Future<void> init() async {
    // Mock initialization - instant
  }

  Future<void> saveEvent(CalendarEvent event) async {
    _events.add(event);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
  }

  Future<List<CalendarEvent>> getEvents() async {
    return List.from(_events);
  }

  Future<CalendarEvent?> getEvent(String id) async {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _events.clear();
  }
}
