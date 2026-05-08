import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_calendar/main.dart';

void main() {
  testWidgets('shows the current week calendar grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Week Calendar'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    for (final dayName in [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ]) {
      expect(find.text(dayName), findsOneWidget);
    }

    for (
      var weekday = DateTime.monday;
      weekday <= DateTime.sunday;
      weekday++
    ) {
      expect(find.byKey(ValueKey('day-cell-$weekday')), findsOneWidget);
    }

    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
