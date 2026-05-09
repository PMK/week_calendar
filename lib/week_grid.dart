part of 'main.dart';

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.weekStart,
    required this.eventsByDate,
    required this.showEndTimeDisplay,
    required this.selectedSearchResult,
    required this.openDay,
    required this.addEvent,
    required this.openEvent,
    required this.selectTransferDate,
  });

  final DateTime weekStart;
  final Map<String, List<_CalendarItem>> eventsByDate;
  final bool showEndTimeDisplay;
  final _SearchResult? selectedSearchResult;
  final void Function(DateTime day, List<_CalendarItem> events) openDay;
  final ValueChanged<DateTime> addEvent;
  final void Function(DateTime day, _CalendarItem item) openEvent;
  final ValueChanged<DateTime>? selectTransferDate;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _DayColumn(
              days: days.take(3).toList(),
              eventsByDate: eventsByDate,
              showEndTimeDisplay: showEndTimeDisplay,
              selectedSearchResult: selectedSearchResult,
              openDay: openDay,
              addEvent: addEvent,
              openEvent: openEvent,
              selectTransferDate: selectTransferDate,
            ),
          ),
          Expanded(
            child: _DayColumn(
              days: days.skip(3).toList(),
              eventsByDate: eventsByDate,
              showEndTimeDisplay: showEndTimeDisplay,
              selectedSearchResult: selectedSearchResult,
              openDay: openDay,
              addEvent: addEvent,
              openEvent: openEvent,
              selectTransferDate: selectTransferDate,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult {
  const _SearchResult({
    required this.weekStart,
    required this.date,
    required this.weekday,
    required this.itemIndex,
  });

  final DateTime weekStart;
  final DateTime date;
  final int weekday;
  final int itemIndex;

  bool matches(DateTime day, int eventIndex) {
    return _isSameDay(day, date) && itemIndex == eventIndex;
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.days,
    required this.eventsByDate,
    required this.showEndTimeDisplay,
    required this.selectedSearchResult,
    required this.openDay,
    required this.addEvent,
    required this.openEvent,
    required this.selectTransferDate,
  });

  final List<DateTime> days;
  final Map<String, List<_CalendarItem>> eventsByDate;
  final bool showEndTimeDisplay;
  final _SearchResult? selectedSearchResult;
  final void Function(DateTime day, List<_CalendarItem> events) openDay;
  final ValueChanged<DateTime> addEvent;
  final void Function(DateTime day, _CalendarItem item) openEvent;
  final ValueChanged<DateTime>? selectTransferDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final day in days)
          Expanded(
            child: _DayCell(
              day: day,
              events: eventsByDate[_dateKey(day)] ?? const [],
              showEndTimeDisplay: showEndTimeDisplay,
              selectedSearchResult: selectedSearchResult,
              openDay: openDay,
              addEvent: addEvent,
              openEvent: openEvent,
              selectTransferDate: selectTransferDate,
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.events,
    required this.showEndTimeDisplay,
    required this.selectedSearchResult,
    required this.openDay,
    required this.addEvent,
    required this.openEvent,
    required this.selectTransferDate,
  });

  final DateTime day;
  final List<_CalendarItem> events;
  final bool showEndTimeDisplay;
  final _SearchResult? selectedSearchResult;
  final void Function(DateTime day, List<_CalendarItem> events) openDay;
  final ValueChanged<DateTime> addEvent;
  final void Function(DateTime day, _CalendarItem item) openEvent;
  final ValueChanged<DateTime>? selectTransferDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isToday = _isSameDay(day, DateTime.now());
    final backgroundColor = isToday
        ? colorScheme.primaryContainer
        : colorScheme.surface;
    final hasOverflowEvents = events.length > 3;
    final transferDateSelected = selectTransferDate;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: transferDateSelected != null
          ? () {
              transferDateSelected(day);
            }
          : hasOverflowEvents
          ? () {
              openDay(day, events);
            }
          : null,
      child: Container(
        key: ValueKey('day-cell-${day.weekday}'),
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: isToday ? colorScheme.primary : colorScheme.outlineVariant,
            width: isToday ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              key: ValueKey('day-cell-heading-${day.weekday}'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (transferDateSelected != null) {
                  transferDateSelected(day);
                } else {
                  openDay(day, events);
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _fullDayName(day),
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: isToday
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_shortMonthName(day)} ${day.day}',
                    style: textTheme.labelLarge?.copyWith(
                      color: isToday
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        key: ValueKey('day-cell-empty-space-${day.weekday}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (transferDateSelected != null) {
                            transferDateSelected(day);
                          } else if (hasOverflowEvents) {
                            openDay(day, events);
                          } else {
                            addEvent(day);
                          }
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: events.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 6);
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              key: ValueKey(
                                'day-cell-event-${day.weekday}-$index',
                              ),
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (transferDateSelected != null) {
                                  transferDateSelected(day);
                                } else {
                                  openEvent(day, events[index]);
                                }
                              },
                              child: _CalendarItemRow(
                                item: events[index],
                                showEndTimeDisplay: showEndTimeDisplay,
                                isHighlighted:
                                    selectedSearchResult?.matches(day, index) ??
                                    false,
                                isContinuation: _isContinuationOnDay(
                                  events[index],
                                  day,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (hasOverflowEvents)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: 0.33,
                            widthFactor: 1,
                            child: GestureDetector(
                              key: ValueKey('day-cell-gradient-${day.weekday}'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (transferDateSelected != null) {
                                  transferDateSelected(day);
                                } else {
                                  openDay(day, events);
                                }
                              },
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      backgroundColor.withValues(alpha: 0),
                                      backgroundColor,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarItemRow extends StatelessWidget {
  static const height = 24.0;

  const _CalendarItemRow({
    required this.item,
    required this.showEndTimeDisplay,
    required this.isHighlighted,
    this.isContinuation = false,
  });

  final _CalendarItem item;
  final bool showEndTimeDisplay;
  final bool isHighlighted;
  final bool isContinuation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final coloredTextColor = item.color.computeLuminance() > 0.45
        ? Colors.black
        : Colors.white;
    final timeLabel = _timeLabel();
    final titleTextColor = item.allDay
        ? coloredTextColor
        : colorScheme.onSurface;

    return Semantics(
      label: '$timeLabel ${item.title}',
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: item.allDay ? 6 : 0),
        decoration: BoxDecoration(
          color: item.allDay ? item.color : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isHighlighted
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Row(
          children: [
            if (isContinuation) ...[
              Icon(
                Icons.keyboard_return,
                size: 13,
                color: item.allDay ? coloredTextColor : colorScheme.onSurface,
              ),
              const SizedBox(width: 2),
            ],
            if (!item.allDay) ...[
              Container(
                width: showEndTimeDisplay ? 82 : 40,
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  timeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    color: coloredTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel() {
    if (item.allDay) {
      return 'All day';
    }

    final endDateTime = item.endDateTime;
    if (!showEndTimeDisplay || endDateTime == null) {
      return _formatTime(item.startTime);
    }

    return '${_formatTime(item.startTime)}-${_formatTime(TimeOfDay.fromDateTime(endDateTime))}';
  }
}

bool _isContinuationOnDay(_CalendarItem item, DateTime day) {
  final startDateTime = item.startDateTime;
  if (startDateTime == null) {
    return false;
  }

  final startDate = DateTime(
    startDateTime.year,
    startDateTime.month,
    startDateTime.day,
  );
  final visibleDate = DateTime(day.year, day.month, day.day);

  return visibleDate.isAfter(startDate);
}

class _CalendarItem {
  const _CalendarItem({
    required this.startTime,
    required this.title,
    required this.color,
    this.id,
    this.calendarId,
    this.startDateTime,
    this.endDateTime,
    this.allDay = false,
    this.calendarName,
    this.location,
    this.notes,
    this.rrule,
    this.alertMinutes,
    this.secondAlertMinutes,
  });

  final String? id;
  final String? calendarId;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final TimeOfDay startTime;
  final String title;
  final Color color;
  final bool allDay;
  final String? calendarName;
  final String? location;
  final String? notes;
  final String? rrule;
  final int? alertMinutes;
  final int? secondAlertMinutes;
}

DateTime _startOfWeekFor(DateTime date, _WeekStartDay weekStartDay) {
  final currentDate = DateTime(date.year, date.month, date.day);
  return currentDate.subtract(
    Duration(days: _daysSinceWeekStart(date, weekStartDay)),
  );
}

List<int> _orderedWeekdaysFor(_WeekStartDay weekStartDay) {
  return switch (weekStartDay) {
    _WeekStartDay.monday => const [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ],
    _WeekStartDay.sunday => const [
      DateTime.sunday,
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
    ],
  };
}

int _daysSinceWeekStart(DateTime date, _WeekStartDay weekStartDay) {
  return switch (weekStartDay) {
    _WeekStartDay.monday => date.weekday - DateTime.monday,
    _WeekStartDay.sunday => date.weekday % DateTime.sunday,
  };
}

int _isoWeekNumberFor(DateTime date) {
  final currentDate = DateTime(date.year, date.month, date.day);
  final thursday = currentDate.add(
    Duration(days: DateTime.thursday - currentDate.weekday),
  );
  final firstThursday = DateTime(thursday.year, DateTime.january, 4);
  final firstWeekStart = _startOfWeekFor(firstThursday, _WeekStartDay.monday);

  return thursday.difference(firstWeekStart).inDays ~/ 7 + 1;
}

int _isoWeekYearFor(DateTime date) {
  final currentDate = DateTime(date.year, date.month, date.day);
  final thursday = currentDate.add(
    Duration(days: DateTime.thursday - currentDate.weekday),
  );

  return thursday.year;
}

String _weekdayShortName(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    DateTime.sunday => 'Sun',
    _ => '',
  };
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

String _fullDateLabel(DateTime date) {
  return '${_fullDayName(date)}, ${_fullMonthName(date)} ${date.day}, ${date.year}';
}

String _fullDayName(DateTime date) {
  return switch (date.weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => '',
  };
}

String _fullMonthName(DateTime date) {
  return switch (date.month) {
    DateTime.january => 'January',
    DateTime.february => 'February',
    DateTime.march => 'March',
    DateTime.april => 'April',
    DateTime.may => 'May',
    DateTime.june => 'June',
    DateTime.july => 'July',
    DateTime.august => 'August',
    DateTime.september => 'September',
    DateTime.october => 'October',
    DateTime.november => 'November',
    DateTime.december => 'December',
    _ => '',
  };
}

String _shortMonthName(DateTime date) {
  return switch (date.month) {
    DateTime.january => 'Jan',
    DateTime.february => 'Feb',
    DateTime.march => 'Mar',
    DateTime.april => 'Apr',
    DateTime.may => 'May',
    DateTime.june => 'Jun',
    DateTime.july => 'Jul',
    DateTime.august => 'Aug',
    DateTime.september => 'Sep',
    DateTime.october => 'Oct',
    DateTime.november => 'Nov',
    DateTime.december => 'Dec',
    _ => '',
  };
}
