import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/utils/date_utils.dart';

void main() {
  group('DateTimeUtils Tests', () {
    test('Get week number', () {
      // January 1, 2024 is in week 1
      expect(DateTimeUtils.getWeekNumber(DateTime(2024, 1, 1)), 1);

      // January 15, 2024 is in week 3
      expect(DateTimeUtils.getWeekNumber(DateTime(2024, 1, 15)), 3);

      // December 31, 2024
      expect(
        DateTimeUtils.getWeekNumber(DateTime(2024, 12, 31)),
        greaterThan(50),
      );
    });

    test('Get week start (Monday)', () {
      // Wednesday, January 17, 2024
      final date = DateTime(2024, 1, 17);
      final weekStart = DateTimeUtils.getWeekStart(date, 1);

      // Should return Monday, January 15, 2024
      expect(weekStart.year, 2024);
      expect(weekStart.month, 1);
      expect(weekStart.day, 15);
      expect(weekStart.weekday, DateTime.monday);
    });

    test('Get week start (Sunday)', () {
      // Wednesday, January 17, 2024
      final date = DateTime(2024, 1, 17);
      final weekStart = DateTimeUtils.getWeekStart(date, 7);

      // Should return Sunday, January 14, 2024
      expect(weekStart.year, 2024);
      expect(weekStart.month, 1);
      expect(weekStart.day, 14);
      expect(weekStart.weekday, DateTime.sunday);
    });

    test('Get week days', () {
      final date = DateTime(2024, 1, 17); // Wednesday
      final weekDays = DateTimeUtils.getWeekDays(date, 1);

      expect(weekDays.length, 7);
      expect(weekDays[0].weekday, DateTime.monday);
      expect(weekDays[6].weekday, DateTime.sunday);
    });

    test('isSameDay returns correct value', () {
      final date1 = DateTime(2024, 1, 15, 10, 30);
      final date2 = DateTime(2024, 1, 15, 14, 45);
      final date3 = DateTime(2024, 1, 16, 10, 30);

      expect(DateTimeUtils.isSameDay(date1, date2), true);
      expect(DateTimeUtils.isSameDay(date1, date3), false);
    });

    test('Get month abbreviation', () {
      expect(DateTimeUtils.getMonthAbbr(1), 'Jan');
      expect(DateTimeUtils.getMonthAbbr(6), 'Jun');
      expect(DateTimeUtils.getMonthAbbr(12), 'Dec');
    });

    test('Get day name', () {
      expect(DateTimeUtils.getDayName(1), 'Monday');
      expect(DateTimeUtils.getDayName(4), 'Thursday');
      expect(DateTimeUtils.getDayName(7), 'Sunday');
    });

    test('Get day abbreviation', () {
      expect(DateTimeUtils.getDayAbbr(1), 'Mon');
      expect(DateTimeUtils.getDayAbbr(4), 'Thu');
      expect(DateTimeUtils.getDayAbbr(7), 'Sun');
    });

    test('Week days start on correct day', () {
      final date = DateTime(2024, 1, 17);

      // Monday start
      final mondayWeek = DateTimeUtils.getWeekDays(date, 1);
      expect(mondayWeek[0].weekday, DateTime.monday);

      // Sunday start
      final sundayWeek = DateTimeUtils.getWeekDays(date, 7);
      expect(sundayWeek[0].weekday, DateTime.sunday);

      // Wednesday start
      final wednesdayWeek = DateTimeUtils.getWeekDays(date, 3);
      expect(wednesdayWeek[0].weekday, DateTime.wednesday);
    });
  });
}
