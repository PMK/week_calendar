import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week_calendar/main.dart';

void main() {
  const calendarChannel = MethodChannel('week_calendar/calendar');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          return switch (call.method) {
            'isDavx5Installed' => false,
            'getAppSettings' => <String, Object?>{
              'weekStartDay': 'monday',
              'themePreference': 'light',
              'showEndTimeDisplay': false,
              'showWeekNumberInIcon': false,
              'hasEnabledCalendarIds': false,
              'enabledCalendarIds': <String>[],
            },
            'saveAppSettings' => true,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': 'google-primary',
                'accountName': 'me@gmail.com',
                'accountType': 'com.google',
                'name': 'Personal',
                'color': 0xFF2563EB,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => _mockCalendarEventsForCurrentWeek(),
            'createCalendarEvent' => 'created-event-id',
            'updateCalendarEvent' => true,
            'deleteCalendarEvent' => true,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, null);
  });

  testWidgets('shows the current week calendar grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final weekNumber = _isoWeekNumber(today);
    final weekYear = _isoWeekYear(today);

    expect(find.text('Week $weekNumber, $weekYear'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Today'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Today'))
          .onPressed,
      isNull,
    );
    expect(find.byIcon(Icons.menu), findsOneWidget);
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

    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      expect(find.byKey(ValueKey('day-cell-$weekday')), findsOneWidget);
    }

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('Provider planning event'), findsOneWidget);
    expect(find.text('Provider design review'), findsOneWidget);

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('swipes between weeks and returns to today', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final nextWeek = DateTime.now().add(const Duration(days: 7));
    final nextWeekNumber = _isoWeekNumber(nextWeek);
    final nextWeekYear = _isoWeekYear(nextWeek);

    await tester.drag(
      find.byKey(const ValueKey('week-page-view')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week $nextWeekNumber, $nextWeekYear'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Today'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Today'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Today'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('opens week picker and jumps to selected week', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final today = DateTime.now();
    final visibleMonth = DateTime(today.year, today.month);
    final targetWeekStart = _startOfWeek(today.add(const Duration(days: 7)));
    final targetWeekNumber = _isoWeekNumber(targetWeekStart);
    final targetWeekYear = _isoWeekYear(targetWeekStart);

    await tester.tap(find.byKey(const ValueKey('week-title-button')));
    await tester.pumpAndSettle();

    expect(find.text('Select week'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('week-picker-month-title')))
          .data,
      '${_fullMonthName(visibleMonth)} ${visibleMonth.year}',
    );
    expect(
      find.byKey(ValueKey('week-picker-week-${_dateKey(targetWeekStart)}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('week-picker-day-${_dateKey(today)}')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey('week-picker-week-number-${_dateKey(targetWeekStart)}'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('week-picker-select-button')),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(
        find.byKey(const ValueKey('week-picker-select-button')),
      ),
      isA<FilledButton>(),
    );

    await tester.tap(
      find.byKey(ValueKey('week-picker-week-${_dateKey(targetWeekStart)}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-picker-select-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Week $targetWeekNumber, $targetWeekYear'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Today'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('changes week picker month with arrows and vertical swipe', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final today = DateTime.now();
    final currentMonth = DateTime(today.year, today.month);
    final nextMonth = DateTime(today.year, today.month + 1);
    final monthAfterNext = DateTime(today.year, today.month + 2);

    await tester.tap(find.byKey(const ValueKey('week-title-button')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('week-picker-month-title')))
          .data,
      '${_fullMonthName(currentMonth)} ${currentMonth.year}',
    );

    await tester.tap(find.byKey(const ValueKey('week-picker-next-month')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('week-picker-month-title')))
          .data,
      '${_fullMonthName(nextMonth)} ${nextMonth.year}',
    );

    await tester.drag(
      find.byKey(const ValueKey('week-picker-month-page-view')),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('week-picker-month-title')))
          .data,
      '${_fullMonthName(monthAfterNext)} ${monthAfterNext.year}',
    );
  });

  testWidgets('opens event search from downward swipe', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.drag(
      find.byKey(const ValueKey('week-page-view')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('search-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('event-search-field')), findsOneWidget);
    expect(find.text('Search events...'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-grid-overlay')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_left),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey('event-search-field')),
      'not-present',
    );
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsNothing);
    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('event-search-field')),
      'provider',
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_left),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_left),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('search-bar')), findsNothing);
    expect(find.byKey(const ValueKey('search-grid-overlay')), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('week-page-view')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('event-search-field')))
          .controller
          ?.text,
      isEmpty,
    );

    await tester.drag(
      find.byKey(const ValueKey('week-page-view')),
      const Offset(0, -500),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('search-bar')), findsNothing);
    expect(find.byKey(const ValueKey('search-grid-overlay')), findsNothing);
  });

  testWidgets('shows search after downward swipe ends', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('week-page-view')),
      const Offset(0, 120),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('search-bar')), findsOneWidget);
  });

  testWidgets('search animates to result week and clear keeps that week', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          return switch (call.method) {
            'getAppSettings' => <String, Object?>{
              'weekStartDay': 'monday',
              'themePreference': 'light',
              'showEndTimeDisplay': false,
              'hasEnabledCalendarIds': false,
              'enabledCalendarIds': <String>[],
            },
            'saveAppSettings' => true,
            'isDavx5Installed' => false,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': 'google-primary',
                'accountName': 'me@gmail.com',
                'accountType': 'com.google',
                'name': 'Personal',
                'color': 0xFF2563EB,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => _searchEventsForRequestedWeek(
              call.arguments as Map<dynamic, dynamic>,
            ),
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final nextWeekStart = _startOfWeek(
      DateTime.now(),
    ).add(const Duration(days: 7));
    final nextWeekNumber = _isoWeekNumber(nextWeekStart);
    final nextWeekYear = _isoWeekYear(nextWeekStart);

    await tester.drag(
      find.byKey(const ValueKey('week-page-view')),
      const Offset(0, 500),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('event-search-field')),
      'next week target',
    );
    await tester.pumpAndSettle();

    expect(find.text('Week $nextWeekNumber, $nextWeekYear'), findsOneWidget);
    expect(find.text('Next week target'), findsOneWidget);

    var eventContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey('day-cell-event-1-0')),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((eventContainer.decoration as BoxDecoration).border, isNotNull);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Week $nextWeekNumber, $nextWeekYear'), findsOneWidget);
    eventContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey('day-cell-event-1-0')),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((eventContainer.decoration as BoxDecoration).border, isNull);
  });

  testWidgets('places spanning all-day events on actual visible dates', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          return switch (call.method) {
            'getAppSettings' => <String, Object?>{
              'weekStartDay': 'monday',
              'themePreference': 'light',
              'showEndTimeDisplay': false,
              'hasEnabledCalendarIds': false,
              'enabledCalendarIds': <String>[],
            },
            'saveAppSettings' => true,
            'isDavx5Installed' => false,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': 'google-primary',
                'accountName': 'me@gmail.com',
                'accountType': 'com.google',
                'name': 'Personal',
                'color': 0xFF2563EB,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => [_spanningAllDayEventForCurrentWeek()],
            'createCalendarEvent' => 'created-event-id',
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Spanning all day event'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('day-cell-event-1-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('day-cell-event-2-0')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-cell-event-1-0')),
        matching: find.byIcon(Icons.keyboard_return),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-cell-event-2-0')),
        matching: find.byIcon(Icons.keyboard_return),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('day-cell-event-6-0')), findsNothing);
  });

  testWidgets('renders all-day items first without the all-day label', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          return switch (call.method) {
            'getAppSettings' => <String, Object?>{
              'weekStartDay': 'monday',
              'themePreference': 'light',
              'showEndTimeDisplay': false,
              'hasEnabledCalendarIds': false,
              'enabledCalendarIds': <String>[],
            },
            'saveAppSettings' => true,
            'isDavx5Installed' => false,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': 'google-primary',
                'accountName': 'me@gmail.com',
                'accountType': 'com.google',
                'name': 'Personal',
                'color': 0xFF111827,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => _allDayAndTimedEventsForCurrentWeek(),
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('All-day launch'), findsOneWidget);
    expect(find.text('Timed launch'), findsOneWidget);
    expect(find.text('All day'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-cell-event-1-0')),
        matching: find.text('All-day launch'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('day-cell-event-1-1')),
        matching: find.text('Timed launch'),
      ),
      findsOneWidget,
    );

    final allDayContainers = find.descendant(
      of: find.byKey(const ValueKey('day-cell-event-1-0')),
      matching: find.byType(Container),
    );
    final timedContainers = find.descendant(
      of: find.byKey(const ValueKey('day-cell-event-1-1')),
      matching: find.byType(Container),
    );
    final allDayOuterContainer = tester.widget<Container>(
      allDayContainers.first,
    );
    final timedOuterContainer = tester.widget<Container>(timedContainers.first);
    final timedTimeContainer = tester.widget<Container>(timedContainers.at(1));

    expect(
      tester.getSize(allDayContainers.first).height,
      tester.getSize(timedContainers.first).height,
    );
    expect(tester.getSize(timedContainers.at(1)).height, lessThan(28));
    expect(
      (allDayOuterContainer.decoration as BoxDecoration).color,
      const Color(0xFF111827),
    );
    expect(
      (timedOuterContainer.decoration as BoxDecoration).color,
      Colors.transparent,
    );
    expect(
      (timedTimeContainer.decoration as BoxDecoration).color,
      const Color(0xFF2563EB),
    );
  });

  testWidgets('opens a day events sheet and an event details sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final thursday = _startOfWeek(DateTime.now()).add(const Duration(days: 3));

    expect(find.byKey(const ValueKey('day-cell-gradient-4')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('day-cell-gradient-4')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('day-events-bottom-sheet')),
      findsOneWidget,
    );
    expect(find.byTooltip('Close day events'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('day-events-title'))).data,
      _fullDateLabel(thursday),
    );
    expect(find.text('Calendar roadmap review'), findsWidgets);
    expect(find.text('Calendar database check'), findsWidgets);
    expect(find.text('Calendar overflow event'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('day-events-item-0')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('edit-event-bottom-sheet')),
      findsOneWidget,
    );
    expect(find.text('Edit event'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('event-title-field')),
          )
          .controller
          ?.text,
      'Calendar roadmap review',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.descendant(
              of: find.byKey(const ValueKey('event-start-time-field')),
              matching: find.byType(TextFormField),
            ),
          )
          .controller
          ?.text,
      '09:15',
    );

    await tester.tap(find.byKey(const ValueKey('cancel-new-event-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('day-events-bottom-sheet')), findsNothing);
  });

  testWidgets('starts copy and move mode from edit event actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('day-cell-event-1-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('copy-event-button')), findsOneWidget);
    expect(find.byIcon(Icons.content_copy), findsOneWidget);
    expect(find.byKey(const ValueKey('move-event-button')), findsOneWidget);
    expect(find.byIcon(Icons.drive_file_move), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-event-button')), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('copy-event-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('copy-mode-banner')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('event-transfer-cancel-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('day-cell-empty-space-2')));
    await tester.pumpAndSettle();

    expect(find.text('Event copied'), findsOneWidget);
    expect(find.byKey(const ValueKey('copy-mode-banner')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('event-transfer-close-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('copy-mode-banner')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('day-cell-event-1-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('move-event-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('move-mode-banner')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('day-cell-empty-space-2')));
    await tester.pumpAndSettle();

    expect(find.text('Event moved'), findsOneWidget);
    expect(find.byKey(const ValueKey('move-mode-banner')), findsNothing);
  });

  testWidgets('asks for non-repeating event delete confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('day-cell-event-1-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-event-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Are you sure you want to delete this event?'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cancel-delete-event-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('confirm-delete-event-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('cancel-delete-event-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('edit-event-bottom-sheet')),
      findsOneWidget,
    );
  });

  testWidgets('asks for repeating event delete scope', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('week_calendar/calendar'),
          (call) async {
            return switch (call.method) {
              'getAppSettings' => <String, Object?>{
                'weekStartDay': 'monday',
                'themePreference': 'light',
                'showEndTimeDisplay': false,
                'hasEnabledCalendarIds': false,
                'enabledCalendarIds': <String>[],
              },
              'saveAppSettings' => true,
              'hasCalendarPermission' => true,
              'requestCalendarPermission' => true,
              'getCalendars' => <Map<String, Object?>>[
                {
                  'id': 'google-primary',
                  'accountName': 'me@gmail.com',
                  'accountType': 'com.google',
                  'name': 'Personal',
                  'color': 0xFF2563EB,
                  'enabled': true,
                },
              ],
              'getCalendarEvents' => [_repeatingCalendarEventForCurrentWeek()],
              'deleteCalendarEvent' => true,
              _ => null,
            };
          },
        );

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('day-cell-event-1-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-event-button')));
    await tester.pumpAndSettle();

    expect(find.text('This event is a repeating event.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('delete-this-event-only-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('delete-future-events-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cancel-delete-event-button')),
      findsOneWidget,
    );
  });

  testWidgets('opens a new event sheet from empty day-cell space', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final saturday = _startOfWeek(DateTime.now()).add(const Duration(days: 5));

    await tester.tap(find.byKey(const ValueKey('day-cell-empty-space-6')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('new-event-bottom-sheet')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('event-title-field')),
          )
          .controller
          ?.text,
      isEmpty,
    );
    expect(find.text('Title *'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.descendant(
              of: find.byKey(const ValueKey('event-start-date-field')),
              matching: find.byType(TextFormField),
            ),
          )
          .controller
          ?.text,
      _shortDateLabel(saturday),
    );
    expect(find.text('All day event'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('event-all-day-field')),
      ),
      isA<SwitchListTile>(),
    );
    expect(
      find.byKey(const ValueKey('event-start-time-field')),
      findsOneWidget,
    );
    expect(find.text('Start date *'), findsOneWidget);
    expect(find.byKey(const ValueKey('event-end-date-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('event-end-time-field')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('done-new-event-button')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey('event-title-field')),
      'New provider event',
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('done-new-event-button')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const ValueKey('done-new-event-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('new-event-bottom-sheet')), findsNothing);
    expect(find.text('Event saved'), findsOneWidget);
  });

  testWidgets('opens and closes the settings side sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-side-sheet')), findsOneWidget);
    expect(
      tester
          .widget<Material>(find.byKey(const ValueKey('settings-side-sheet')))
          .shape,
      isA<RoundedRectangleBorder>(),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('settings-jump-to-week-item')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('settings-week-start-item')))
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('settings-default-alert-item')))
          .dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('settings-theme-item'))).dy,
      ),
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byTooltip('Close settings'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-davx5-item')), findsNothing);
    expect(find.text('Calendars'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('settings-calendars-subtitle')),
          )
          .data,
      '1 selected',
    );
    expect(find.text('Week starts on'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('settings-week-start-subtitle')),
          )
          .data,
      'Monday',
    );
    expect(find.text('Theme'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('settings-theme-subtitle')))
          .data,
      'Light',
    );
    expect(find.text('End time display'), findsOneWidget);
    expect(find.text('Show week number in icon'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('settings-week-number-icon-item')),
          )
          .dy,
      greaterThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('settings-end-time-display-item')),
            )
            .dy,
      ),
    );
    expect(find.text('Default alert'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('settings-default-alert-subtitle')),
          )
          .data,
      '15 minutes before',
    );
    expect(find.text('Jump to week'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    await tester.drag(
      find.descendant(
        of: find.byKey(const ValueKey('settings-side-sheet')),
        matching: find.byType(ListView),
      ),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.0.0+1'), findsOneWidget);

    await tester.tap(find.byTooltip('Close settings'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-side-sheet')), findsNothing);
  });

  testWidgets('closes settings side sheet on left-to-right swipe', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('settings-side-sheet')),
      const Offset(260, 0),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-side-sheet')), findsNothing);
  });

  testWidgets('settings jump to week opens picker and closes settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final targetWeekStart = _startOfWeek(
      DateTime.now(),
    ).add(const Duration(days: 7));
    final targetWeekNumber = _isoWeekNumber(targetWeekStart);
    final targetWeekYear = _isoWeekYear(targetWeekStart);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-jump-to-week-item')));
    await tester.pumpAndSettle();

    expect(find.text('Select week'), findsOneWidget);

    await tester.tap(
      find.byKey(ValueKey('week-picker-week-${_dateKey(targetWeekStart)}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-picker-select-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-side-sheet')), findsNothing);
    expect(
      find.text('Week $targetWeekNumber, $targetWeekYear'),
      findsOneWidget,
    );
  });

  testWidgets('loads saved settings on startup', (WidgetTester tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          return switch (call.method) {
            'getAppSettings' => <String, Object?>{
              'weekStartDay': 'sunday',
              'themePreference': 'dark',
              'showEndTimeDisplay': true,
              'showWeekNumberInIcon': true,
              'hasEnabledCalendarIds': true,
              'enabledCalendarIds': <String>['google-primary'],
            },
            'saveAppSettings' => true,
            'isDavx5Installed' => false,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': 'google-primary',
                'accountName': 'me@gmail.com',
                'accountType': 'com.google',
                'name': 'Personal',
                'color': 0xFF2563EB,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => _mockCalendarEventsForCurrentWeek(),
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final sundayTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('day-cell-7')),
    );
    final mondayTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('day-cell-1')),
    );

    expect(sundayTopLeft.dy, lessThan(mondayTopLeft.dy));
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    expect(find.text('09:00-10:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('settings-week-start-subtitle')),
          )
          .data,
      'Sunday',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('settings-theme-subtitle')))
          .data,
      'Dark',
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('settings-end-time-display-item')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('settings-week-number-icon-item')),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('saves changed settings', (WidgetTester tester) async {
    final savedPayloads = <Map<dynamic, dynamic>>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          if (call.method == 'saveAppSettings') {
            savedPayloads.add(Map<dynamic, dynamic>.of(call.arguments as Map));
            return true;
          }

          return switch (call.method) {
            'getAppSettings' => <String, Object?>{
              'weekStartDay': 'monday',
              'themePreference': 'light',
              'showEndTimeDisplay': false,
              'hasEnabledCalendarIds': false,
              'enabledCalendarIds': <String>[],
            },
            'isDavx5Installed' => false,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': 'google-primary',
                'accountName': 'me@gmail.com',
                'accountType': 'com.google',
                'name': 'Personal',
                'color': 0xFF2563EB,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => _mockCalendarEventsForCurrentWeek(),
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-week-start-item')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-start-sunday-option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-start-done-button')));
    await tester.pumpAndSettle();

    expect(
      savedPayloads.any((payload) => payload['weekStartDay'] == 'sunday'),
      isTrue,
    );
  });

  testWidgets('syncs launcher icon when week number setting changes', (
    WidgetTester tester,
  ) async {
    final requestedIconNames = <String?>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          if (call.method == 'setLauncherIcon') {
            requestedIconNames.add(
              (call.arguments as Map<dynamic, dynamic>)['iconName'] as String?,
            );
            return true;
          }

          return switch (call.method) {
            'getAppSettings' => <String, Object?>{
              'weekStartDay': 'monday',
              'themePreference': 'light',
              'showEndTimeDisplay': false,
              'showWeekNumberInIcon': false,
              'hasEnabledCalendarIds': false,
              'enabledCalendarIds': <String>[],
            },
            'saveAppSettings' => true,
            'isDavx5Installed' => false,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': 'google-primary',
                'accountName': 'me@gmail.com',
                'accountType': 'com.google',
                'name': 'Personal',
                'color': 0xFF2563EB,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => _mockCalendarEventsForCurrentWeek(),
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(requestedIconNames, contains(null));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings-week-number-icon-item')),
    );
    await tester.pumpAndSettle();

    final weekNumber = _isoWeekNumber(DateTime.now()).clamp(1, 53);
    expect(requestedIconNames, contains('icon_$weekNumber'));

    await tester.tap(
      find.byKey(const ValueKey('settings-week-number-icon-item')),
    );
    await tester.pumpAndSettle();

    expect(requestedIconNames.last, isNull);
  });

  testWidgets('keeps launcher icon on current week when swiping weeks', (
    WidgetTester tester,
  ) async {
    final requestedIconNames = <String?>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          if (call.method == 'setLauncherIcon') {
            requestedIconNames.add(
              (call.arguments as Map<dynamic, dynamic>)['iconName'] as String?,
            );
            return true;
          }

          return switch (call.method) {
            'getAppSettings' => <String, Object?>{
              'weekStartDay': 'monday',
              'themePreference': 'light',
              'showEndTimeDisplay': false,
              'showWeekNumberInIcon': true,
              'hasEnabledCalendarIds': false,
              'enabledCalendarIds': <String>[],
            },
            'saveAppSettings' => true,
            'isDavx5Installed' => false,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': 'google-primary',
                'accountName': 'me@gmail.com',
                'accountType': 'com.google',
                'name': 'Personal',
                'color': 0xFF2563EB,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => _mockCalendarEventsForCurrentWeek(),
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final currentWeekNumber = _isoWeekNumber(DateTime.now()).clamp(1, 53);
    expect(requestedIconNames, contains('icon_$currentWeekNumber'));
    requestedIconNames.clear();

    final nextWeek = DateTime.now().add(const Duration(days: 7));
    final nextWeekNumber = _isoWeekNumber(nextWeek);
    final nextWeekYear = _isoWeekYear(nextWeek);

    await tester.drag(
      find.byKey(const ValueKey('week-page-view')),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week $nextWeekNumber, $nextWeekYear'), findsOneWidget);
    expect(requestedIconNames, isEmpty);
  });

  testWidgets('shows calendar selection bottom sheet grouped by account', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-calendars-item')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('calendars-bottom-sheet')),
      findsOneWidget,
    );
    expect(find.text('me@gmail.com · Google'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('calendar-switch-google-primary')),
          )
          .value,
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('calendar-switch-google-primary')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('calendars-done-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendars-bottom-sheet')), findsNothing);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('settings-calendars-subtitle')),
          )
          .data,
      '0 selected',
    );
  });

  testWidgets('shows CalendarContract calendars in calendar bottom sheet', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          return switch (call.method) {
            'isDavx5Installed' => true,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': '10',
                'accountName': 'me@gmail.com',
                'accountType': 'com.google',
                'name': 'Personal',
                'color': 0xFF2563EB,
                'enabled': true,
              },
              {
                'id': '11',
                'accountName': 'Samsung account',
                'accountType': 'com.samsung.android.calendar',
                'name': 'Phone',
                'color': 0xFFDB2777,
                'enabled': false,
              },
              {
                'id': '20',
                'accountName': 'work@example.com',
                'accountType': 'com.microsoft.office.outlook',
                'name': 'Work',
                'color': 0xFF16A34A,
                'enabled': true,
              },
              {
                'id': '30',
                'accountName': 'caldav@example.com',
                'accountType': 'at.bitfire.davdroid',
                'name': 'DAV',
                'color': 0xFFEA580C,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => _mockCalendarEventsForCurrentWeek(),
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('settings-calendars-subtitle')),
          )
          .data,
      '3 selected',
    );

    await tester.tap(find.byKey(const ValueKey('settings-calendars-item')));
    await tester.pumpAndSettle();

    expect(find.text('me@gmail.com · Google'), findsOneWidget);
    expect(find.text('Samsung account · Samsung'), findsOneWidget);
    expect(find.text('work@example.com · Outlook'), findsOneWidget);
    expect(find.text('caldav@example.com · DAVx5'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('DAV'), findsOneWidget);
    expect(find.text('Personal CalDAV'), findsNothing);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('settings-calendars-subtitle')),
          )
          .data,
      '3 selected',
    );
    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('calendar-switch-11')))
          .value,
      isFalse,
    );
  });

  testWidgets('blocks the app when no supported calendar provider is detected', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          return switch (call.method) {
            'isDavx5Installed' => false,
            'hasCalendarPermission' => true,
            'requestCalendarPermission' => true,
            'getCalendars' => <Map<String, Object?>>[
              {
                'id': 'local-calendar',
                'accountName': 'Local calendar',
                'accountType': 'LOCAL',
                'name': 'Local',
                'color': 0xFF475569,
                'enabled': true,
              },
            ],
            'getCalendarEvents' => <Map<String, Object?>>[],
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('no-calendar-provider-dialog')),
      findsOneWidget,
    );
    expect(
      find.text(
        'No CalDAV found. Setup an account via Google-, Samsung-, Outlook/Exchange sync apps, or DAVx5 configured to continue.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('retry-calendar-provider-button')),
      findsOneWidget,
    );
  });

  testWidgets('blocks the app when calendar permission is denied', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(calendarChannel, (call) async {
          return switch (call.method) {
            'getAppSettings' => <String, Object?>{
              'weekStartDay': 'monday',
              'themePreference': 'light',
              'showEndTimeDisplay': false,
              'hasEnabledCalendarIds': false,
              'enabledCalendarIds': <String>[],
            },
            'saveAppSettings' => true,
            'hasCalendarPermission' => false,
            'requestCalendarPermission' => false,
            _ => null,
          };
        });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('calendar-permission-dialog')),
      findsOneWidget,
    );
    expect(find.text('Calendar permission required'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('retry-calendar-permission-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('no-calendar-provider-dialog')),
      findsNothing,
    );
  });

  testWidgets('updates settings dialog and switch values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-week-start-item')));
    await tester.pumpAndSettle();

    expect(find.text('Week starts on'), findsWidgets);
    expect(
      find.byKey(const ValueKey('week-start-monday-option')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('week-start-sunday-option')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('week-start-sunday-option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('week-start-done-button')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('settings-week-start-subtitle')),
          )
          .data,
      'Sunday',
    );

    await tester.tap(find.byTooltip('Close settings'));
    await tester.pumpAndSettle();

    final sundayTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('day-cell-7')),
    );
    final mondayTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('day-cell-1')),
    );
    final tuesdayTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('day-cell-2')),
    );
    final wednesdayTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('day-cell-3')),
    );

    expect(sundayTopLeft.dx, mondayTopLeft.dx);
    expect(sundayTopLeft.dy, lessThan(mondayTopLeft.dy));
    expect(mondayTopLeft.dy, lessThan(tuesdayTopLeft.dy));
    expect(wednesdayTopLeft.dx, greaterThan(sundayTopLeft.dx));
    expect((wednesdayTopLeft.dy - sundayTopLeft.dy).abs(), lessThan(1));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-theme-item')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('theme-select-field')), findsOneWidget);

    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Arctic'), findsOneWidget);
    expect(find.text('Forest Night'), findsOneWidget);
    expect(find.text('Ember Light'), findsOneWidget);
    expect(find.text('Noderunners'), findsOneWidget);
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-done-button')));
    await tester.pumpAndSettle();

    expect(find.text('Dark'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('settings-end-time-display-item')),
          )
          .value,
      isFalse,
    );

    await tester.tap(
      find.byKey(const ValueKey('settings-end-time-display-item')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('settings-end-time-display-item')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('settings-week-number-icon-item')),
          )
          .value,
      isFalse,
    );

    await tester.tap(
      find.byKey(const ValueKey('settings-week-number-icon-item')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('settings-week-number-icon-item')),
          )
          .value,
      isTrue,
    );
  });
}

DateTime _startOfWeek(DateTime date) {
  final currentDate = DateTime(date.year, date.month, date.day);
  return currentDate.subtract(
    Duration(days: currentDate.weekday - DateTime.monday),
  );
}

int _isoWeekNumber(DateTime date) {
  final currentDate = DateTime(date.year, date.month, date.day);
  final thursday = currentDate.add(
    Duration(days: DateTime.thursday - currentDate.weekday),
  );
  final firstThursday = DateTime(thursday.year, DateTime.january, 4);
  final firstWeekStart = _startOfWeek(firstThursday);

  return thursday.difference(firstWeekStart).inDays ~/ 7 + 1;
}

int _isoWeekYear(DateTime date) {
  final currentDate = DateTime(date.year, date.month, date.day);
  final thursday = currentDate.add(
    Duration(days: DateTime.thursday - currentDate.weekday),
  );

  return thursday.year;
}

String _fullDateLabel(DateTime date) {
  return '${_fullDayName(date)}, ${_fullMonthName(date)} ${date.day}, ${date.year}';
}

String _fullDayName(DateTime date) {
  return switch (date.weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => '',
  };
}

String _fullMonthName(DateTime date) {
  return switch (date.month) {
    DateTime.january => 'January',
    DateTime.february => 'February',
    DateTime.march => 'March',
    DateTime.april => 'April',
    DateTime.may => 'May',
    DateTime.june => 'June',
    DateTime.july => 'July',
    DateTime.august => 'August',
    DateTime.september => 'September',
    DateTime.october => 'October',
    DateTime.november => 'November',
    DateTime.december => 'December',
    _ => '',
  };
}

String _shortDateLabel(DateTime date) {
  return '${_shortMonthName(date)} ${date.day}, ${date.year}';
}

String _shortMonthName(DateTime date) {
  return switch (date.month) {
    DateTime.january => 'Jan',
    DateTime.february => 'Feb',
    DateTime.march => 'Mar',
    DateTime.april => 'Apr',
    DateTime.may => 'May',
    DateTime.june => 'Jun',
    DateTime.july => 'Jul',
    DateTime.august => 'Aug',
    DateTime.september => 'Sep',
    DateTime.october => 'Oct',
    DateTime.november => 'Nov',
    DateTime.december => 'Dec',
    _ => '',
  };
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

List<Map<String, Object?>> _searchEventsForRequestedWeek(
  Map<dynamic, dynamic> arguments,
) {
  final requestedStart = DateTime.fromMillisecondsSinceEpoch(
    arguments['startMillis'] as int,
  );
  final nextWeekStart = _startOfWeek(
    DateTime.now(),
  ).add(const Duration(days: 7));

  if (!_isSameDay(requestedStart, nextWeekStart)) {
    return const [];
  }

  final start = nextWeekStart.add(const Duration(hours: 9));
  final end = start.add(const Duration(hours: 1));

  return [
    {
      'id': 'next-week-target',
      'calendarId': 'google-primary',
      'startYear': start.year,
      'startMonth': start.month,
      'startDay': start.day,
      'startHour': start.hour,
      'startMinute': start.minute,
      'endYear': end.year,
      'endMonth': end.month,
      'endDay': end.day,
      'endHour': end.hour,
      'endMinute': end.minute,
      'title': 'Next week target',
      'allDay': false,
      'color': 0xFF2563EB,
      'calendarName': 'Personal',
    },
  ];
}

List<Map<String, Object?>> _allDayAndTimedEventsForCurrentWeek() {
  final weekStart = _startOfWeek(DateTime.now());
  final allDayEnd = weekStart.add(const Duration(days: 1));
  final timedStart = weekStart.add(const Duration(hours: 8));
  final timedEnd = timedStart.add(const Duration(hours: 1));

  return [
    {
      'id': 'timed-launch',
      'calendarId': 'google-primary',
      'startYear': timedStart.year,
      'startMonth': timedStart.month,
      'startDay': timedStart.day,
      'startHour': timedStart.hour,
      'startMinute': timedStart.minute,
      'endYear': timedEnd.year,
      'endMonth': timedEnd.month,
      'endDay': timedEnd.day,
      'endHour': timedEnd.hour,
      'endMinute': timedEnd.minute,
      'title': 'Timed launch',
      'allDay': false,
      'color': 0xFF2563EB,
      'calendarName': 'Personal',
    },
    {
      'id': 'all-day-launch',
      'calendarId': 'google-primary',
      'startYear': weekStart.year,
      'startMonth': weekStart.month,
      'startDay': weekStart.day,
      'startHour': 0,
      'startMinute': 0,
      'endYear': allDayEnd.year,
      'endMonth': allDayEnd.month,
      'endDay': allDayEnd.day,
      'endHour': 0,
      'endMinute': 0,
      'title': 'All-day launch',
      'allDay': true,
      'color': 0xFF111827,
      'calendarName': 'Personal',
    },
  ];
}

bool _isSameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

List<Map<String, Object?>> _mockCalendarEventsForCurrentWeek() {
  final weekStart = _startOfWeek(DateTime.now());

  Map<String, Object?> eventRow({
    required String id,
    required int dayOffset,
    required int hour,
    required int minute,
    required String title,
    required int color,
  }) {
    final start = weekStart.add(
      Duration(days: dayOffset, hours: hour, minutes: minute),
    );
    final end = start.add(const Duration(hours: 1));

    return {
      'id': id,
      'calendarId': 'google-primary',
      'startYear': start.year,
      'startMonth': start.month,
      'startDay': start.day,
      'startHour': start.hour,
      'startMinute': start.minute,
      'endYear': end.year,
      'endMonth': end.month,
      'endDay': end.day,
      'endHour': end.hour,
      'endMinute': end.minute,
      'title': title,
      'allDay': false,
      'color': color,
      'calendarName': 'Personal',
    };
  }

  return [
    eventRow(
      id: '1',
      dayOffset: 0,
      hour: 9,
      minute: 0,
      title: 'Provider planning event',
      color: 0xFF2563EB,
    ),
    eventRow(
      id: '2',
      dayOffset: 0,
      hour: 11,
      minute: 30,
      title: 'Provider design review',
      color: 0xFF16A34A,
    ),
    eventRow(
      id: '3',
      dayOffset: 2,
      hour: 12,
      minute: 0,
      title: 'Provider lunch event',
      color: 0xFFCA8A04,
    ),
    eventRow(
      id: '4',
      dayOffset: 3,
      hour: 9,
      minute: 15,
      title: 'Calendar roadmap review',
      color: 0xFF0F766E,
    ),
    eventRow(
      id: '5',
      dayOffset: 3,
      hour: 13,
      minute: 0,
      title: 'Calendar database check',
      color: 0xFF9333EA,
    ),
    eventRow(
      id: '6',
      dayOffset: 3,
      hour: 15,
      minute: 30,
      title: 'Calendar release readiness',
      color: 0xFFEA580C,
    ),
    eventRow(
      id: '7',
      dayOffset: 3,
      hour: 17,
      minute: 0,
      title: 'Calendar overflow event',
      color: 0xFF475569,
    ),
  ];
}

Map<String, Object?> _spanningAllDayEventForCurrentWeek() {
  final weekStart = _startOfWeek(DateTime.now());
  final start = weekStart.subtract(const Duration(days: 2));
  final end = weekStart.add(const Duration(days: 2));

  return {
    'id': 'spanning-all-day',
    'calendarId': 'google-primary',
    'startYear': start.year,
    'startMonth': start.month,
    'startDay': start.day,
    'startHour': 0,
    'startMinute': 0,
    'endYear': end.year,
    'endMonth': end.month,
    'endDay': end.day,
    'endHour': 0,
    'endMinute': 0,
    'title': 'Spanning all day event',
    'allDay': true,
    'color': 0xFF2563EB,
    'calendarName': 'Personal',
  };
}

Map<String, Object?> _repeatingCalendarEventForCurrentWeek() {
  final weekStart = _startOfWeek(DateTime.now());
  final start = weekStart.add(const Duration(hours: 8));
  final end = start.add(const Duration(hours: 1));

  return {
    'id': 'repeating-event',
    'calendarId': 'google-primary',
    'startYear': start.year,
    'startMonth': start.month,
    'startDay': start.day,
    'startHour': start.hour,
    'startMinute': start.minute,
    'endYear': end.year,
    'endMonth': end.month,
    'endDay': end.day,
    'endHour': end.hour,
    'endMinute': end.minute,
    'title': 'Repeating provider event',
    'allDay': false,
    'color': 0xFF2563EB,
    'rrule': 'FREQ=WEEKLY',
    'calendarName': 'Personal',
  };
}
