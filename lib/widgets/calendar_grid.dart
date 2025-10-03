import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/settings_provider.dart';
import '../models/calendar_event.dart';
import 'day_cell.dart';
import '../utils/date_utils.dart';

class CalendarGrid extends StatefulWidget {
  final Function(CalendarEvent) onEventTap;
  final Function(DateTime) onDateTap;
  final Function(DateTime) onCreateEvent;

  const CalendarGrid({
    super.key,
    required this.onEventTap,
    required this.onDateTap,
    required this.onCreateEvent,
  });

  @override
  State<CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<CalendarGrid> {
  late PageController _pageController;
  int _currentPage = 1000; // Start at middle page for infinite scrolling

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CalendarProvider, SettingsProvider>(
      builder: (context, calendarProvider, settingsProvider, child) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                final offset = page - _currentPage;
                if (offset > 0) {
                  for (int i = 0; i < offset; i++) {
                    calendarProvider.nextWeek();
                  }
                } else if (offset < 0) {
                  for (int i = 0; i < offset.abs(); i++) {
                    calendarProvider.previousWeek();
                  }
                }
                _currentPage = page;
              },
              itemBuilder: (context, index) {
                // Calculate which week this page represents
                final offset = index - _currentPage;
                final baseDate = calendarProvider.selectedDate;
                final pageDate = baseDate.add(Duration(days: offset * 7));
                final weekDays = DateTimeUtils.getWeekDays(
                  pageDate,
                  settingsProvider.settings.weekStartDay,
                );
                final isDarkMode = settingsProvider.settings.isDarkMode;

                if (orientation == Orientation.landscape) {
                  return _buildLandscapeLayout(
                    context,
                    weekDays,
                    calendarProvider,
                    settingsProvider,
                    isDarkMode,
                  );
                } else {
                  return _buildPortraitLayout(
                    context,
                    weekDays,
                    calendarProvider,
                    settingsProvider,
                    isDarkMode,
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    List<DateTime> weekDays,
    CalendarProvider calendarProvider,
    SettingsProvider settingsProvider,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: Mon, Tue, Wed
          Expanded(
            child: Column(
              children: [
                _buildDayCell(
                  context,
                  weekDays[0],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
                const SizedBox(height: 8),
                _buildDayCell(
                  context,
                  weekDays[1],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
                const SizedBox(height: 8),
                _buildDayCell(
                  context,
                  weekDays[2],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right column: Thu, Fri, Sat (smaller), Sun (smaller)
          Expanded(
            child: Column(
              children: [
                _buildDayCell(
                  context,
                  weekDays[3],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
                const SizedBox(height: 8),
                _buildDayCell(
                  context,
                  weekDays[4],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
                const SizedBox(height: 8),
                // Saturday - smaller
                _buildDayCell(
                  context,
                  weekDays[5],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 0.7,
                ),
                const SizedBox(height: 8),
                // Sunday - smaller
                _buildDayCell(
                  context,
                  weekDays[6],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 0.7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    List<DateTime> weekDays,
    CalendarProvider calendarProvider,
    SettingsProvider settingsProvider,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First column: Mon, Tue
          Expanded(
            child: Column(
              children: [
                _buildDayCell(
                  context,
                  weekDays[0],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
                const SizedBox(height: 8),
                _buildDayCell(
                  context,
                  weekDays[1],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Second column: Wed, Thu
          Expanded(
            child: Column(
              children: [
                _buildDayCell(
                  context,
                  weekDays[2],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
                const SizedBox(height: 8),
                _buildDayCell(
                  context,
                  weekDays[3],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Third column: Fri, Sat, Sun
          Expanded(
            child: Column(
              children: [
                _buildDayCell(
                  context,
                  weekDays[4],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 1,
                ),
                const SizedBox(height: 8),
                _buildDayCell(
                  context,
                  weekDays[5],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 0.7,
                ),
                const SizedBox(height: 8),
                _buildDayCell(
                  context,
                  weekDays[6],
                  calendarProvider,
                  settingsProvider,
                  isDarkMode,
                  flex: 0.7,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    CalendarProvider calendarProvider,
    SettingsProvider settingsProvider,
    bool isDarkMode, {
    double flex = 1.0,
  }) {
    return Flexible(
      flex: (flex * 100).toInt(),
      child: DayCell(
        date: date,
        events: calendarProvider.getEventsForDate(date),
        isToday: DateTimeUtils.isSameDay(date, DateTime.now()),
        todayColor: settingsProvider.settings.themeConfig.todayColor,
        onEventTap: widget.onEventTap,
        onDateTap: () => widget.onDateTap(date),
        onCreateEvent: () => widget.onCreateEvent(date),
        isDarkMode: isDarkMode,
        highlightedEventId: calendarProvider.highlightedEventId,
      ),
    );
  }
}
