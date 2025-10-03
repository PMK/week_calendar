import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Get week number of the year (ISO 8601)
  static int getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Get the first day of the week based on start day preference
  static DateTime getWeekStart(DateTime date, int startDay) {
    final currentWeekday = date.weekday;
    final daysToSubtract = (currentWeekday - startDay + 7) % 7;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  /// Get all days in the current week
  static List<DateTime> getWeekDays(DateTime date, int startDay) {
    final weekStart = getWeekStart(date, startDay);
    return List.generate(7, (index) => weekStart.add(Duration(days: index)));
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Format date for display
  static String formatDate(DateTime date, String format) {
    return DateFormat(format).format(date);
  }

  /// Format time for display
  static String formatTime(DateTime time, String format) {
    return DateFormat(format).format(time);
  }

  /// Get month abbreviation
  static String getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Get day name
  static String getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  /// Get day abbreviation
  static String getDayAbbr(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
