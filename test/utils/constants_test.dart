import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/utils/constants.dart';

void main() {
  group('Constants Tests', () {
    test('App name is defined', () {
      expect(AppConstants.appName, 'Week Calendar');
    });

    test('Week start day constants', () {
      expect(AppConstants.monday, 1);
      expect(AppConstants.sunday, 7);
    });

    test('Alert options are defined', () {
      expect(AppConstants.alertOptions, isNotEmpty);
      expect(AppConstants.alertOptions, contains(0)); // At time of event
      expect(AppConstants.alertOptions, contains(15)); // 15 minutes
      expect(AppConstants.alertOptions, contains(1440)); // 1 day
    });

    test('Alert options are sorted', () {
      for (int i = 0; i < AppConstants.alertOptions.length - 1; i++) {
        expect(
          AppConstants.alertOptions[i],
          lessThan(AppConstants.alertOptions[i + 1]),
        );
      }
    });

    test('Repeat options are defined', () {
      expect(AppConstants.repeatOptions, isNotEmpty);
      expect(AppConstants.repeatOptions, contains('Never'));
      expect(AppConstants.repeatOptions, contains('Daily'));
      expect(AppConstants.repeatOptions, contains('Weekly'));
      expect(AppConstants.repeatOptions, contains('Monthly'));
      expect(AppConstants.repeatOptions, contains('Yearly'));
    });

    test('Day names are defined', () {
      expect(AppConstants.dayNames.length, 7);
      expect(AppConstants.dayNames[0], 'Monday');
      expect(AppConstants.dayNames[6], 'Sunday');
    });
  });
}
