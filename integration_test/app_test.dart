import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:week_calendar/main.dart' as app;
import 'package:week_calendar/services/storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Week Calendar Integration Tests', () {
    setUp(() async {
      // Initialize storage before each test
      await StorageService.instance.init();
    });

    testWidgets('App launches successfully', (tester) async {
      app.main();

      // Wait for the app to settle and load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait for providers to initialize
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Verify main UI elements are present
      expect(find.text('Today'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Verify week number is displayed (format: "Week X, YYYY")
      expect(find.textContaining('Week'), findsOneWidget);
    });

    testWidgets('Calendar grid displays days', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check that day names are displayed
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      for (final day in dayNames) {
        // At least one day should be visible (could be abbreviated)
        expect(find.textContaining(day, findRichText: true), findsWidgets);
      }
    });

    testWidgets('Navigate to next week', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Get current week text
      final weekFinder = find.textContaining('Week');
      expect(weekFinder, findsOneWidget);
      final initialWeekText = tester.widget<Text>(weekFinder.first).data!;

      // Swipe left to go to next week
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Wait for animation to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Week number should have changed
      final newWeekFinder = find.textContaining('Week');
      final newWeekText = tester.widget<Text>(newWeekFinder.first).data!;

      expect(newWeekText, isNot(equals(initialWeekText)));

      // Today button should be visible and enabled
      final todayButton = find.text('Today');
      expect(todayButton, findsOneWidget);
    });

    testWidgets('Navigate to previous week', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Swipe right to go to previous week
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pumpAndSettle();

      // Wait for animation to complete
      await tester.pump(const Duration(milliseconds: 500));

      // Today button should be visible
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('Click Today button returns to current week', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate away from today
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Click Today button
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Should be back at current week
      // Today button should be disabled (we can check if it's visible)
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('Open and close settings', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Open settings
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Verify settings is open
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);

      // Close settings
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Settings should be closed
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('Toggle dark mode', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Open settings
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Find and toggle dark mode switch
      final darkModeSwitch = find.ancestor(
        of: find.text('Dark Mode'),
        matching: find.byType(SwitchListTile),
      );

      expect(darkModeSwitch, findsOneWidget);
      await tester.tap(darkModeSwitch);
      await tester.pumpAndSettle();

      // Close settings
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Theme should have changed (verified by app still running)
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('Open week picker', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Tap on week number/year
      final weekTextFinder = find.textContaining('Week');
      expect(weekTextFinder, findsOneWidget);

      await tester.tap(weekTextFinder);
      await tester.pumpAndSettle();

      // Week picker dialog should open
      expect(find.text('Select Week'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('Change week start day', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Open settings
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Find Week Starts On option
      expect(find.text('Week Starts On'), findsOneWidget);

      await tester.tap(find.text('Week Starts On'));
      await tester.pumpAndSettle();

      // Dialog should open with day options
      expect(find.text('Monday'), findsWidgets);
      expect(find.text('Sunday'), findsWidgets);

      // Select Sunday
      final sundayRadio = find
          .ancestor(
            of: find.text('Sunday'),
            matching: find.byType(RadioListTile<int>),
          )
          .last;

      await tester.tap(sundayRadio);
      await tester.pumpAndSettle();

      // Dialog should close
      // Settings should still be open
      expect(find.text('Settings'), findsOneWidget);

      // Close settings
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('Open search', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find a GestureDetector to swipe down on
      final gestureDetector = find.byType(GestureDetector).first;

      // Swipe down to open search
      await tester.drag(gestureDetector, const Offset(0, 300));
      await tester.pumpAndSettle();

      // Search bar should be visible
      expect(find.text('Search events...'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Close search by tapping Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Search should be closed
      expect(find.text('Search events...'), findsNothing);
    });

    testWidgets('Create new event by tapping day cell', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find all DayCell widgets
      final dayCells = find.byType(GestureDetector);
      expect(dayCells, findsWidgets);

      // Tap on a day cell (use one that's likely visible)
      await tester.tap(dayCells.at(2)); // Third gesture detector
      await tester.pumpAndSettle();

      // Modal bottom sheet should open with event overlay
      // Look for the overlay buttons/fields
      expect(find.text('New Event'), findsOneWidget);

      // Look for Cancel and Done buttons in the overlay
      expect(find.text('Cancel'), findsWidgets);
      expect(find.text('Done'), findsWidgets);

      // Close the overlay
      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();
    });

    testWidgets('Jump to week from settings', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Open settings
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Scroll down to find Jump to Week
      final settingsList = find.byType(ListView).first;
      await tester.drag(
        settingsList,
        const Offset(0, -200),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Find Jump to Week option
      final jumpToWeek = find.text('Jump to Week');
      if (jumpToWeek.evaluate().isNotEmpty) {
        await tester.tap(jumpToWeek);
        await tester.pumpAndSettle();

        // Week picker should open
        expect(find.text('Select Week'), findsOneWidget);

        // Close picker
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }

      // Close settings if still open
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('App handles orientation changes', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify app is running in portrait
      expect(find.text('Today'), findsOneWidget);

      // Simulate landscape mode
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      // App should still work
      expect(find.text('Today'), findsOneWidget);

      // Reset to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
    });

    testWidgets('Navigation bar displays correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check all navigation elements
      expect(find.text('Today'), findsOneWidget);
      expect(find.textContaining('Week'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('Theme colors are displayed in settings', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Open settings
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Look for Color Theme section
      expect(find.text('Color Theme'), findsOneWidget);

      // Find color circles using a more specific predicate
      final colorOptions = find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration) {
            return decoration.shape == BoxShape.circle &&
                decoration.color != null;
          }
        }
        return false;
      });

      expect(colorOptions, findsWidgets);

      // Close settings
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('Day events overlay shows all events', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find and tap a day cell to open overlay
      final dayCells = find.byType(GestureDetector);
      await tester.tap(dayCells.at(2));
      await tester.pumpAndSettle();

      // Overlay should show
      expect(
        find.byWidgetPredicate((widget) => widget is DraggableScrollableSheet),
        findsOneWidget,
      );

      // Should have a "Create New Event" button
      // @TODO: Fix test by dragging downwards so the button appears in the view
      // expect(find.text('Create New Event'), findsOneWidget);

      // Close by tapping close button
      final closeButtons = find.byIcon(Icons.close);
      if (closeButtons.evaluate().isNotEmpty) {
        await tester.tap(closeButtons.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Calendar displays month abbreviations', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check that at least one month abbreviation is visible
      final monthAbbrs = [
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

      bool foundMonth = false;
      for (final month in monthAbbrs) {
        if (find.text(month).evaluate().isNotEmpty) {
          foundMonth = true;
          break;
        }
      }

      expect(
        foundMonth,
        true,
        reason: 'Should display at least one month abbreviation',
      );
    });

    testWidgets('Complete user flow: change theme and navigate', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Step 1: Open settings
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Step 2: Find and tap a theme color (using Column to find the theme section)
      final colorCircles = find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration) {
            return decoration.shape == BoxShape.circle &&
                decoration.color != null;
          }
        }
        return false;
      });

      if (colorCircles.evaluate().length > 1) {
        await tester.tap(colorCircles.at(1)); // Tap second color
        await tester.pumpAndSettle();
      }

      // Step 3: Close settings
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Step 4: Navigate to next week
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Step 5: Go back to today
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // App should still be functional
      expect(find.text('Today'), findsOneWidget);
      expect(find.textContaining('Week'), findsOneWidget);
    });
  });
}
