import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../utils/date_utils.dart';
import 'event_item.dart';

class DayEventsOverlay extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  final Function(CalendarEvent) onEventTap;
  final VoidCallback onDateTap;
  final bool isDarkMode;
  final String? highlightedEventId;

  const DayEventsOverlay({
    super.key,
    required this.date,
    required this.events,
    required this.onEventTap,
    required this.onDateTap,
    required this.isDarkMode,
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

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final surfaceColor = isDarkMode
        ? const Color(0xFF2C2C2C)
        : Colors.grey.shade100;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateTimeUtils.getDayName(date.weekday),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.grey.shade300
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateTimeUtils.getMonthAbbr(date.month)} ${date.day}, ${date.year}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Events list
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: isDarkMode
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events for this day',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Scrollbar(
                        controller: scrollController,
                        thumbVisibility: events.length > 10,
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
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
                              padding: const EdgeInsets.only(bottom: 8),
                              child: EventItem(
                                event: event,
                                onTap: () {
                                  Navigator.pop(context);
                                  onEventTap(event);
                                },
                                compact: false,
                                isDarkMode: isDarkMode,
                                isHighlighted: isHighlighted,
                                isContinuation: isContinuation,
                              ),
                            );
                          },
                        ),
                      ),
              ),
              // Add new event button at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(
                    top: BorderSide(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDateTap();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Event'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
