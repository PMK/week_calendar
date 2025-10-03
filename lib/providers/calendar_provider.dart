import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../services/storage_service.dart';
import '../utils/date_utils.dart';
import 'settings_provider.dart';

enum CalendarMode { normal, copy, move }

class CalendarProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;

  DateTime _selectedDate = DateTime.now();
  List<CalendarEvent> _events = [];
  CalendarEvent? _selectedEvent;
  CalendarMode _mode = CalendarMode.normal;
  bool _isLoading = false;
  String? _highlightedEventId;
  List<CalendarEvent> _searchResults = [];
  int _currentSearchIndex = 0;

  CalendarProvider(this._settingsProvider);

  DateTime get selectedDate => _selectedDate;
  List<CalendarEvent> get events => _events;
  CalendarEvent? get selectedEvent => _selectedEvent;
  CalendarMode get mode => _mode;
  bool get isLoading => _isLoading;
  String? get highlightedEventId => _highlightedEventId;
  List<CalendarEvent> get searchResults => _searchResults;
  int get currentSearchIndex => _currentSearchIndex;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get canGoToPreviousResult => _currentSearchIndex > 0;
  bool get canGoToNextResult => _currentSearchIndex < _searchResults.length - 1;

  int get currentWeekNumber => DateTimeUtils.getWeekNumber(_selectedDate);
  int get currentYear => _selectedDate.year;

  bool get isViewingToday {
    final now = DateTime.now();
    final weekStart = DateTimeUtils.getWeekStart(
      _selectedDate,
      _settingsProvider.settings.weekStartDay,
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    return now.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        now.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  List<DateTime> get currentWeekDays {
    return DateTimeUtils.getWeekDays(
      _selectedDate,
      _settingsProvider.settings.weekStartDay,
    );
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    return _events.where((event) {
      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      final targetDate = DateTime(date.year, date.month, date.day);

      // For events with end dates (multi-day events)
      if (event.endDate != null) {
        final endDate = DateTime(
          event.endDate!.year,
          event.endDate!.month,
          event.endDate!.day,
        );

        // Check if this is a repeated event
        // Repeated events should only show on their start date in each repetition
        if (event.repeatRule != null && event.repeatRule != 'Never') {
          return eventDate.isAtSameMomentAs(targetDate);
        }

        // For non-repeated multi-day events, show on all days in range
        return targetDate.isAtSameMomentAs(eventDate) ||
            (targetDate.isAfter(eventDate) && targetDate.isBefore(endDate)) ||
            targetDate.isAtSameMomentAs(endDate);
      }

      return eventDate.isAtSameMomentAs(targetDate);
    }).toList()..sort((a, b) {
      // All-day events first
      if (a.isAllDay && !b.isAllDay) return -1;
      if (!a.isAllDay && b.isAllDay) return 1;

      // Then by start time
      if (a.startTime != null && b.startTime != null) {
        final aMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
        final bMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
        return aMinutes.compareTo(bMinutes);
      }

      return 0;
    });
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _events = await StorageService.instance.getEvents();
    } catch (e) {
      debugPrint('Error loading events: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEvent(CalendarEvent event) async {
    try {
      await StorageService.instance.saveEvent(event);
      _events.add(event);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(CalendarEvent event) async {
    try {
      await StorageService.instance.updateEvent(event);
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await StorageService.instance.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }

  void selectEvent(CalendarEvent event) {
    _selectedEvent = event;
    notifyListeners();
  }

  void clearSelection() {
    _selectedEvent = null;
    _mode = CalendarMode.normal;
    notifyListeners();
  }

  void setMode(CalendarMode mode) {
    _mode = mode;
    notifyListeners();
  }

  Future<void> copyEventToDate(CalendarEvent event, DateTime newDate) async {
    final newEvent = event.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: newDate,
      endDate: event.endDate != null
          ? newDate.add(event.endDate!.difference(event.date))
          : null,
    );
    await addEvent(newEvent);
    // Don't clear selection in copy mode - allow multiple copies
    notifyListeners();
  }

  Future<void> moveEventToDate(CalendarEvent event, DateTime newDate) async {
    final updatedEvent = event.copyWith(
      date: newDate,
      endDate: event.endDate != null
          ? newDate.add(event.endDate!.difference(event.date))
          : null,
    );
    await updateEvent(updatedEvent);
    clearSelection();
  }

  void goToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  void goToDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void nextWeek() {
    _selectedDate = _selectedDate.add(const Duration(days: 7));
    notifyListeners();
  }

  void previousWeek() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
    notifyListeners();
  }

  // Search functionality
  void search(String query) {
    if (query.isEmpty) {
      _searchResults = [];
      _highlightedEventId = null;
      _currentSearchIndex = 0;
      notifyListeners();
      return;
    }

    final lowerQuery = query.toLowerCase();
    _searchResults = _events.where((event) {
      return event.title.toLowerCase().contains(lowerQuery) ||
          (event.location?.toLowerCase().contains(lowerQuery) ?? false) ||
          (event.notes?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    if (_searchResults.isNotEmpty) {
      _currentSearchIndex = 0;
      _highlightCurrentResult();
    } else {
      _highlightedEventId = null;
      notifyListeners();
    }
  }

  void goToNextSearchResult() {
    if (canGoToNextResult) {
      _currentSearchIndex++;
      _highlightCurrentResult();
    }
  }

  void goToPreviousSearchResult() {
    if (canGoToPreviousResult) {
      _currentSearchIndex--;
      _highlightCurrentResult();
    }
  }

  void _highlightCurrentResult() {
    if (_searchResults.isEmpty) return;

    final event = _searchResults[_currentSearchIndex];
    _highlightedEventId = event.id;

    // Navigate to the week containing this event
    final eventWeekStart = DateTimeUtils.getWeekStart(
      event.date,
      _settingsProvider.settings.weekStartDay,
    );
    final currentWeekStart = DateTimeUtils.getWeekStart(
      _selectedDate,
      _settingsProvider.settings.weekStartDay,
    );

    if (!DateTimeUtils.isSameDay(eventWeekStart, currentWeekStart)) {
      _selectedDate = event.date;
    }

    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _highlightedEventId = null;
    _currentSearchIndex = 0;
    notifyListeners();
  }
}
