import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../utils/date_utils.dart';
import 'event_item.dart';
import 'day_events_overlay.dart';

class DayCell extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  final bool isToday;
  final Color todayColor;
  final Function(CalendarEvent) onEventTap;
  final VoidCallback onDateTap;
  final VoidCallback onCreateEvent;
  final bool compact;
  final bool isDarkMode;
  final String? highlightedEventId;

  const DayCell({
    super.key,
    required this.date,
    required this.events,
    required this.isToday,
    required this.todayColor,
    required this.onEventTap,
    required this.onDateTap,
    required this.onCreateEvent,
    this.compact = false,
    this.isDarkMode = false,
    this.highlightedEventId,
  });

  bool _isEventContinuation(CalendarEvent event, DateTime currentDate) {
    if (event.repeatRule != null && event.repeatRule != 'Never') {
      return false;
    }

    if (event.endDate == null) {
      return false;
    }

    final eventStartDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );
    final currentDateNormalized = DateTime(
      currentDate.year,
      currentDate.month,
      currentDate.day,
    );

    return currentDateNormalized.isAfter(eventStartDate);
  }

  void _showDayEventsOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayEventsOverlay(
        date: date,
        events: events,
        onEventTap: onEventTap,
        onDateTap: onDateTap,
        isDarkMode: isDarkMode,
        highlightedEventId: highlightedEventId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color based on mode
    Color backgroundColor;
    if (isDarkMode) {
      backgroundColor = isToday
          ? todayColor.withAlpha(80)
          : const Color(0xFF2C2C2C);
    } else {
      backgroundColor = isToday
          ? todayColor
          : Colors.grey.shade100.withValues(alpha: 0.75);
    }

    final hasOverflow = events.length > 3;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - clickable to open overlay
          GestureDetector(
            onTap: () => _showDayEventsOverlay(context),
            child: Container(
              padding: EdgeInsets.all(compact ? 4 : 8),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day name on left
                  Text(
                    compact
                        ? DateTimeUtils.getDayAbbr(date.weekday)
                        : DateTimeUtils.getDayName(date.weekday),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 12 : 14,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                    ),
                  ),
                  // Month and date on right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateTimeUtils.getMonthAbbr(date.month),
                        style: TextStyle(
                          fontSize: compact ? 10 : 12,
                          height: 1.2,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 16 : 20,
                          height: 1.0,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Events body
          Expanded(
            child: GestureDetector(
              onTap: hasOverflow
                  ? () => _showDayEventsOverlay(context)
                  : onCreateEvent,
              child: Stack(
                children: [
                  // Events list (non-scrollable)
                  IgnorePointer(
                    ignoring: hasOverflow,
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2 : 4,
                        vertical: 4,
                      ),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final isHighlighted =
                            highlightedEventId != null &&
                            event.id == highlightedEventId;
                        final isContinuation = _isEventContinuation(
                          event,
                          date,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: GestureDetector(
                            onTap: hasOverflow ? null : () => onEventTap(event),
                            child: EventItem(
                              event: event,
                              onTap: () => onEventTap(event),
                              compact: compact,
                              isDarkMode: isDarkMode,
                              isHighlighted: isHighlighted,
                              isContinuation: isContinuation,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay at bottom to indicate more items
                  if (hasOverflow)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 30,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
