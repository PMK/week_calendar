import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../utils/color_utils.dart';

class EventItem extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final bool compact;
  final bool isDarkMode;
  final bool isHighlighted;
  final bool isContinuation;

  const EventItem({
    super.key,
    required this.event,
    required this.onTap,
    this.compact = false,
    this.isDarkMode = false,
    this.isHighlighted = false,
    this.isContinuation = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = ColorUtils.getContrastColor(event.color);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 6,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: event.isAllDay ? event.color : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isHighlighted ? Colors.yellow : event.color,
            width: isHighlighted ? 3 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Continuation indicator
            if (isContinuation && !event.isAllDay) ...[
              Icon(
                Icons.subdirectory_arrow_right,
                size: compact ? 12 : 14,
                color: event.color,
              ),
              SizedBox(width: compact ? 2 : 4),
            ],
            if (isContinuation && event.isAllDay) ...[
              Icon(
                Icons.subdirectory_arrow_right,
                size: compact ? 12 : 14,
                color: textColor,
              ),
              SizedBox(width: compact ? 2 : 4),
            ],
            // Time badge for non-all-day events (only on first day)
            if (!event.isAllDay &&
                event.startTime != null &&
                !isContinuation) ...[
              if (!compact)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: event.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    _formatTime(event.startTime!),
                    style: TextStyle(
                      fontSize: compact ? 8 : 10,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              if (!compact) const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  color: event.isAllDay
                      ? textColor
                      : (isDarkMode ? Colors.grey.shade300 : Colors.black87),
                  fontWeight: event.isAllDay
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
