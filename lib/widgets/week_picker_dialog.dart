import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/date_utils.dart';

class WeekPickerDialog extends StatefulWidget {
  const WeekPickerDialog({super.key});

  @override
  State<WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<WeekPickerDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    _selectedDate = provider.selectedDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CalendarProvider, SettingsProvider>(
      builder: (context, calendarProvider, settingsProvider, child) {
        final isDarkMode = settingsProvider.settings.isDarkMode;
        final backgroundColor = isDarkMode
            ? const Color(0xFF2C2C2C)
            : Colors.white;
        final currentWeekStart = DateTimeUtils.getWeekStart(
          calendarProvider.selectedDate,
          settingsProvider.settings.weekStartDay,
        );
        final selectedWeekStart = DateTimeUtils.getWeekStart(
          _selectedDate,
          settingsProvider.settings.weekStartDay,
        );

        return Dialog(
          backgroundColor: backgroundColor,
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Week',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                // Month/Year navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _displayedMonth = DateTime(
                            _displayedMonth.year,
                            _displayedMonth.month - 1,
                            1,
                          );
                        });
                      },
                    ),
                    Text(
                      '${_getMonthName(_displayedMonth.month)} ${_displayedMonth.year}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _displayedMonth = DateTime(
                            _displayedMonth.year,
                            _displayedMonth.month + 1,
                            1,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Calendar grid
                Expanded(
                  child: _buildCalendarGrid(
                    settingsProvider,
                    isDarkMode,
                    currentWeekStart,
                    selectedWeekStart,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade300 : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        calendarProvider.goToDate(_selectedDate);
                        Navigator.pop(context);
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid(
    SettingsProvider settingsProvider,
    bool isDarkMode,
    DateTime currentWeekStart,
    DateTime selectedWeekStart,
  ) {
    final firstDayOfMonth = _displayedMonth;
    final lastDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    );

    // Get the first day to show (might be from previous month)
    final firstDayToShow = firstDayOfMonth.subtract(
      Duration(
        days:
            (firstDayOfMonth.weekday -
                settingsProvider.settings.weekStartDay +
                7) %
            7,
      ),
    );

    // Calculate number of weeks to show
    final weeksToShow = ((lastDayOfMonth.difference(firstDayToShow).inDays) / 7)
        .ceil();

    return Column(
      children: [
        // Day headers
        Row(
          children: List.generate(7, (index) {
            final dayIndex =
                (settingsProvider.settings.weekStartDay + index - 1) % 7;
            return Expanded(
              child: Center(
                child: Text(
                  _getDayAbbr(dayIndex + 1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Weeks
        Expanded(
          child: ListView.builder(
            itemCount: weeksToShow,
            itemBuilder: (context, weekIndex) {
              final weekStartDate = firstDayToShow.add(
                Duration(days: weekIndex * 7),
              );
              final isCurrentWeek = DateTimeUtils.isSameDay(
                weekStartDate,
                currentWeekStart,
              );
              final isSelectedWeek = DateTimeUtils.isSameDay(
                weekStartDate,
                selectedWeekStart,
              );

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = weekStartDate;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: isCurrentWeek
                        ? Border.all(
                            color: isDarkMode
                                ? Colors.blue.shade300
                                : Colors.blue,
                            width: 2,
                          )
                        : null,
                    color: isSelectedWeek
                        ? (isDarkMode
                              ? Colors.blue.shade700.withValues(alpha: 0.3)
                              : Colors.blue.withValues(alpha: 0.1))
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: List.generate(7, (dayIndex) {
                      final date = weekStartDate.add(Duration(days: dayIndex));
                      final isCurrentMonth =
                          date.month == _displayedMonth.month;
                      final isToday = DateTimeUtils.isSameDay(
                        date,
                        DateTime.now(),
                      );

                      return Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isToday
                                ? (isDarkMode
                                      ? Colors.blue.shade700
                                      : Colors.blue)
                                : null,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isToday
                                    ? Colors.white
                                    : isCurrentMonth
                                    ? (isDarkMode ? Colors.white : Colors.black)
                                    : (isDarkMode
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400),
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getDayAbbr(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
