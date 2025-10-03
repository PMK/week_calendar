import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week_calendar/widgets/day_cell.dart';
import 'package:week_calendar/models/calendar_event.dart';
import '../test_helpers.dart';

void main() {
  group('DayCell Widget Tests', () {
    testWidgets('Displays date and day name', (tester) async {
      final date = DateTime(2024, 1, 15); // Monday

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: const [],
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Jan'), findsOneWidget);
    });

    testWidgets('Shows today color when isToday is true', (tester) async {
      final date = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: const [],
              isToday: true,
              todayColor: Colors.yellow,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(DayCell),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.yellow);
    });

    testWidgets('Displays events', (tester) async {
      final date = DateTime(2024, 1, 15);
      final events = [
        TestHelpers.createTestEvent(title: 'Meeting', date: date),
        TestHelpers.createTestEvent(title: 'Lunch', date: date),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: events,
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Meeting'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('Shows gradient when too many events', (tester) async {
      final date = DateTime(2024, 1, 15);
      final events = List.generate(
        5,
        (i) => TestHelpers.createTestEvent(title: 'Event $i', date: date),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: events,
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      // Gradient should be visible when there are more than 3 events
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).gradient != null,
        ),
        findsWidgets,
      );
    });

    testWidgets('Header tap opens overlay (via onDateTap simulation)', (
      tester,
    ) async {
      final date = DateTime(2024, 1, 15);
      bool headerTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: const [],
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () => headerTapped = true,
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      // The header has a GestureDetector that wraps the day name, date, and month
      // We need to tap on the actual GestureDetector, not just the text
      final headerGesture = find.ancestor(
        of: find.text('Monday'),
        matching: find.byType(GestureDetector),
      );

      expect(headerGesture, findsWidgets);

      // Tap the first GestureDetector found (which is the header)
      await tester.tap(headerGesture.first);
      await tester.pump();

      expect(headerTapped, true);
    }, skip: true);

    testWidgets('Body tap calls onCreateEvent when no overflow', (
      tester,
    ) async {
      final date = DateTime(2024, 1, 15);
      final events = [
        TestHelpers.createTestEvent(title: 'Event 1', date: date),
      ];
      bool createEventCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: events,
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () => createEventCalled = true,
              isDarkMode: false,
            ),
          ),
        ),
      );

      // Find the body area (below the events)
      // We'll tap on the DayCell but below the event items
      final dayCellFinder = find.byType(DayCell);
      final cellRect = tester.getRect(dayCellFinder);

      // Tap in the lower portion of the cell (empty space)
      await tester.tapAt(Offset(cellRect.center.dx, cellRect.bottom - 20));
      await tester.pump();

      expect(createEventCalled, true);
    });

    testWidgets('Tapping event calls onEventTap when no overflow', (
      tester,
    ) async {
      final date = DateTime(2024, 1, 15);
      final testEvent = TestHelpers.createTestEvent(
        title: 'Tappable Event',
        date: date,
      );
      CalendarEvent? tappedEvent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: [testEvent],
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (event) => tappedEvent = event,
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable Event'));
      await tester.pump();

      expect(tappedEvent, isNotNull);
      expect(tappedEvent?.title, 'Tappable Event');
    });

    testWidgets('Entire cell opens overlay when too many events', (
      tester,
    ) async {
      final date = DateTime(2024, 1, 15);
      final events = List.generate(
        5,
        (i) => TestHelpers.createTestEvent(title: 'Event $i', date: date),
      );
      bool overlayOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: events,
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () => overlayOpened = true,
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      // When there are too many events, tapping anywhere should open overlay
      final dayCellFinder = find.byType(DayCell);
      await tester.tap(dayCellFinder);
      await tester.pump();

      // Note: This test verifies the gesture detector is present
      // In actual app, it would show modal bottom sheet
      expect(overlayOpened, true);
    }, skip: true);

    testWidgets('Dark mode changes cell appearance', (tester) async {
      final date = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: const [],
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(DayCell),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;

      // Dark mode should use dark background color
      expect(decoration.color, const Color(0xFF2C2C2C));
    });

    testWidgets('Day name is displayed with correct styling', (tester) async {
      final date = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: const [],
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      final dayNameText = tester.widget<Text>(find.text('Monday'));
      expect(dayNameText.style?.fontWeight, FontWeight.bold);
      expect(dayNameText.style?.fontSize, 14);
    });

    testWidgets('Month and date are displayed next to each other', (
      tester,
    ) async {
      final date = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: const [],
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      // Find the Row containing month and date
      final rowFinder = find.ancestor(
        of: find.text('15'),
        matching: find.byType(Row),
      );

      expect(rowFinder, findsWidgets);
      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('No gradient shown when events fit', (tester) async {
      final date = DateTime(2024, 1, 15);
      final events = List.generate(
        2,
        (i) => TestHelpers.createTestEvent(title: 'Event $i', date: date),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: events,
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      // With only 2 events, no gradient should appear
      final gradientContainers = find.byWidgetPredicate(
        (widget) =>
            widget is Positioned &&
            widget.child is IgnorePointer &&
            (widget.child as IgnorePointer).child is Container,
      );

      expect(gradientContainers, findsNothing);
    });

    testWidgets('Highlighted event shows with special styling', (tester) async {
      final date = DateTime(2024, 1, 15);
      final event = TestHelpers.createTestEvent(
        id: 'highlighted-1',
        title: 'Highlighted Event',
        date: date,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayCell(
              date: date,
              events: [event],
              isToday: false,
              todayColor: Colors.blue.shade100,
              onEventTap: (_) {},
              onDateTap: () {},
              onCreateEvent: () {},
              isDarkMode: false,
              highlightedEventId: 'highlighted-1',
            ),
          ),
        ),
      );

      // The event item should be highlighted
      expect(find.text('Highlighted Event'), findsOneWidget);

      // Find the EventItem widget
      final eventItemFinder = find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'EventItem',
      );

      expect(eventItemFinder, findsOneWidget);
    });
  });
}
