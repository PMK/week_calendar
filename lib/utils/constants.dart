class AppConstants {
  static const String appName = 'Week Calendar';

  // Week start days
  static const int monday = 1;
  static const int sunday = 7;

  // Alert options (minutes before event)
  static const List<int> alertOptions = [
    0, // At time of event
    5, // 5 minutes
    15, // 15 minutes
    30, // 30 minutes
    60, // 1 hour
    120, // 2 hours
    1440, // 1 day
    2880, // 2 days
    10080, // 1 week
  ];

  // Repeat options
  static const List<String> repeatOptions = [
    'Never',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  // Day names
  static const List<String> dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
}
