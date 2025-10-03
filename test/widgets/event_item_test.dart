import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/widgets/event_item.dart';
import '../test_helpers.dart';

void main() {
  group('EventItem Widget Tests', () {
    testWidgets('Displays event title', (tester) async {
      final event = TestHelpers.createTestEvent(title: 'Test Event');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventItem(event: event, onTap: () {}, isDarkMode: false),
          ),
        ),
      );

      expect(find.text('Test Event'), findsOneWidget);
    });

    testWidgets('Shows time for timed events', (tester) async {
      final event = TestHelpers.createTestEvent(
        title: 'Meeting',
        startTime: const TimeOfDay(hour: 9, minute: 30),
        isAllDay: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventItem(event: event, onTap: () {}, isDarkMode: false),
          ),
        ),
      );

      expect(find.text('09:30'), findsOneWidget);
    });

    testWidgets('Does not show time for all-day events', (tester) async {
      final event = TestHelpers.createTestEvent(
        title: 'All Day Event',
        isAllDay: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventItem(event: event, onTap: () {}, isDarkMode: false),
          ),
        ),
      );

      expect(find.textContaining(':'), findsNothing);
    });

    testWidgets('Shows continuation arrow for continued events', (
      tester,
    ) async {
      final event = TestHelpers.createTestEvent(
        title: 'Continued Event',
        isAllDay: false,
        endDate: DateTime.now().add(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventItem(
              event: event,
              onTap: () {},
              isContinuation: true,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.subdirectory_arrow_right), findsOneWidget);
    });

    testWidgets('Highlights when isHighlighted is true', (tester) async {
      final event = TestHelpers.createTestEvent(title: 'Highlighted');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventItem(
              event: event,
              onTap: () {},
              isHighlighted: true,
              isDarkMode: false,
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.boxShadow, isNotNull);
    });

    testWidgets('Calls onTap when tapped', (tester) async {
      final event = TestHelpers.createTestEvent(title: 'Tappable');
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventItem(
              event: event,
              onTap: () => tapped = true,
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable'));
      expect(tapped, true);
    });
  });
}
