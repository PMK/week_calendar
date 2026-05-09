# Agent Guide

## Project Context

- Project: `week_calendar`
- Stack: Flutter, Dart, Material 3, Android Kotlin platform channel.
- Main app entry: `lib/main.dart`
- Android bridge: `android/app/src/main/kotlin/com/pmk/week_calendar/MainActivity.kt`
- Android manifest: `android/app/src/main/AndroidManifest.xml`
- Android launcher label is `Week Calendar`.
- Main test file: `test/widget_test.dart`
- The app is locked to portrait only:
  - Flutter: `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`
  - Android: `android:screenOrientation="portrait"` on `MainActivity`

## Current Screen Contract

- The main screen is a one-week calendar view.
- `AppBar`:
  - Left action: `Today`, disabled when current week is visible.
  - Center title: `Week <number>, <year>`.
  - Right action: hamburger menu icon that opens Settings.
- Body:
  - Two-column week grid.
  - Each day cell stays fixed by parent layout and must not grow for event overflow.
  - Default week start is Monday:
    - Left column: Monday, Tuesday, Wednesday.
    - Right column: Thursday, Friday, Saturday, Sunday.
  - If Settings > `Week starts on` is Sunday:
    - Left column: Sunday, Monday, Tuesday.
    - Right column: Wednesday, Thursday, Friday, Saturday.
  - Day cell headers show day name on left and `MMM d` on right.
  - Timed calendar item rows show a colored time pill (`HH:mm`) and a one-line title with ellipsis on the cell background. Keep the time/title gap tight.
  - All-day calendar item rows have background color across the whole row and show only the title, not an `All day` label.
  - Calendar item text on colored backgrounds is white or black based on background luminance for contrast.
  - Multi-day events repeat in each visible day cell. On continued days, including the first visible day if the event started before this week, prepend the `keyboard_return`/enter icon.
  - If a day has more than 3 items, show a bottom gradient overlay over the last 20% of the cell. The gradient must intercept taps and open the full day sheet so hidden items cannot be pressed through it.

## Calendar Provider Behavior

- Android calendar data comes through `CalendarContract` via `MethodChannel('week_calendar/calendar')`.
- Supported calendar providers are detected by `CalendarContract.Calendars.ACCOUNT_TYPE`:
  - Google
  - Samsung
  - Outlook / Microsoft / Office / Exchange
  - DAVx5 / davdroid / bitfire
- Unsupported/local-only CalendarProvider accounts are ignored for provider detection.
- On first app launch, request calendar permission immediately. If permission is denied, show a non-dismissible fullscreen blocking dialog explaining calendar permission is required, with a `Grant permission` retry button.
- If no supported provider is detected after permission is granted, the app shows a non-dismissible fullscreen dialog:
  - `No CalDAV found. Setup an account via Google-, Samsung-, Outlook/Exchange sync apps, or DAVx5 configured to continue.`
  - Dialog has a `Retry` button that re-runs calendar provider loading.
- `getCalendars` returns supported calendars grouped by Android account name and provider label, e.g. `me@gmail.com · Google`.
- `getCalendarEvents` queries `CalendarContract.Instances` for the visible week and groups events client-side by local weekday.
- Keep `READ_CALENDAR` permission in the Android manifest.

## Settings

- Settings opens as a right-side sheet using `showGeneralDialog`.
- Settings sheet has rounded left top and left bottom corners matching Material bottom-sheet top corner roundness.
- Settings currently contains:
  - `Calendars`: opens a bottom sheet listing provider calendars grouped by account.
  - `Week starts on`: dialog with Monday and Sunday radio options.
  - `Theme`: dialog with Light, Dark, Arctic, Forest Night, Ember Light, and Noderunners. Noderunners is a dark orange/black theme using a bright orange primary and stays at the bottom of the list.
  - `End time display`: switch for grid item time ranges.
  - `Show week number in icon`: switch under `End time display`; when enabled, `flutter_dynamic_icon_plus` sets the launcher icon to `icon_<visible ISO week number>`.
  - `Default alert`: dialog with alert defaults.
  - `Jump to week`: opens the same week picker as the app bar title. Selecting a week closes Settings while the grid animates to that week.
  - Divider.
  - About section with app version.
- The former `DAVx5` settings item was removed. Do not re-add a provider-specific settings row unless explicitly requested.
- Settings order is `Calendars`, `Jump to week`, `Week starts on`, `Theme`, `Default alert`, `End time display`, `Show week number in icon`, divider, About.
- Android launcher entries are all activity aliases: `.DEFAULT` is the normal icon and `.icon_1` through `.icon_53` are week-number icons. `MainActivity` is not itself a launcher entry.
- Launcher aliases point at `*_adaptive` mipmap XML resources. On Android 8+ these set the Android adaptive-icon background layer to `#333333` and use the transparent PNGs as foregrounds; do not flatten the PNG transparency to change this background.
- The week-number icon setting calls the app MethodChannel method `setLauncherIcon` so Android enables exactly one launcher alias immediately. Keep alias names aligned with `icon_<week number>` and reset to `.DEFAULT` when disabled.
- Settings side sheet closes on a left-to-right swipe. Guard the gesture so it only pops the settings route once.
- The Calendars bottom sheet refreshes CalendarProvider calendars before opening.
- Calendar row layout: color dot, calendar name, switch.
- `Done` saves enabled calendar IDs and closes the sheet.

## Day And Event Sheets

- Tapping a day heading opens a near-fullscreen day bottom sheet even when the day has zero or one event.
- Tapping an event row opens an event details bottom sheet with prefilled, read-only form fields. Full editing is future work.
- Tapping empty space in a non-overflow day cell opens a new-event bottom sheet scaffold.
- Event form required labels use `*` for required fields.
- `All day event` uses a switch, not a checkbox.
- The day bottom sheet:
  - Title is full date: weekday, month name, date, year.
  - Close button is an X on the right.
  - Body is a scrollable list of one-row calendar item rows matching the grid style.
  - Scrollbar appears when event count is large enough.

## Search

- Pulling down on the week grid opens event search after the swipe ends.
- Search result ordering follows the selected week start.
- Search highlighting uses concrete event dates, not an assumption that week start is always Monday.
- Search scans cached previous/current/next weeks, animates to result weeks, highlights the selected item, and clears highlight when the search field is emptied while staying on the current visible week.

## Key Implementation Notes

- `WeekCalendarPage` owns current week state, selected week-start setting, calendar provider state, search state, and bottom-sheet launchers.
- `_startOfWeekFor` supports both Monday and Sunday week starts.
- `_orderedWeekdays` is the source of truth for visible day order and search order.
- `_WeekGrid` receives a week start date and generates seven consecutive day dates.
- `_DayColumn` preserves the 3-left/4-right split using `Expanded`.
- `_DayCell` owns fixed day cell layout, header tap, empty-space tap, item tap, and overflow gradient.
- `_CalendarItemRow` owns event row layout, timed/all-day background differences, continuation icon, and contrast text color.
- `_CalendarSyncGateway` owns Dart-side MethodChannel parsing.
- `_CalendarAccount`, `_AvailableCalendar`, and `_CalendarItem` are local immutable value objects.

## Development Rules

- Prefer existing Flutter, Dart, Material, Android SDK, and `CalendarContract` APIs before adding dependencies.
- Do not install any dependency before checking that the package is actively maintained, with latest commit/release not older than 4 years, and getting permission.
- Keep edits scoped to requested calendar behavior.
- Preserve the two-column, 3-left/4-right grid unless explicitly changed.
- Keep each day cell fixed by parent layout; do not let event content expand the cell.
- Use `TextOverflow.ellipsis` for event titles.
- Keep time visible and fixed-width enough for `HH:mm`; left and right padding inside the time pill should stay symmetric.
- Use semantic widget structure and avoid decorative complexity.
- Prefer small stateless widgets for UI sections.
- If a refactor changes public behavior or the screen contract, ask first.
- Do not reintroduce always-visible calendar sync/status bars in the main grid unless explicitly requested.

## Testing And Verification

Preferred local commands:

```sh
dart format lib/main.dart test/widget_test.dart
flutter analyze
flutter test
flutter build apk --debug
```

Latest local verification from 2026-05-09:

- `flutter analyze` passes with no issues.
- `flutter test` passes: 22 tests.
- `flutter build apk --debug` passes.
- Dart SDK observed: `3.11.5` on `macos_arm64`.
- Flutter observed: `3.41.9` stable, with Dart `3.11.5`.

## Test Coverage Expectations

- Keep widget tests aligned with visible UI behavior.
- Test that the week grid renders all seven weekdays.
- Test day-cell keys for all weekdays.
- Test representative calendar item time/title rendering.
- Test Monday and Sunday week-start layout ordering.
- Test settings side sheet and nested dialogs/bottom sheets.
- Test CalendarContract provider grouping and no-provider blocking dialog.
- Test day bottom sheet, event details placeholder, new-event placeholder, and overflow gradient behavior.
- Test timed versus all-day event row background behavior, continuation icons, settings theme list, and Settings > Jump to week.
- For future date-sensitive behavior, inject a clock/date provider instead of relying directly on `DateTime.now()` in tests.

## Future Implementation Direction

- Persist settings instead of storing them only in widget state.
- Apply enabled calendar IDs to event fetching/filtering.
- Replace read-only event details/new-event sheet with editable form and validation.
- Use a stable event model with at least:
  - `id`
  - `calendarId`
  - `startDateTime`
  - `endDateTime`
  - `title`
  - `color`
- For backend/cloud integration, use ISO-8601 datetimes and group events client-side by local calendar date.
- For overflow UX, consider a calculated `+N more` indicator only if visible count can be measured safely.
- For accessibility, keep semantic labels on event rows with time and full title.

## Code Review Focus

- Check layout constraints first. Calendar cells must stay fixed.
- Check text overflow on narrow devices.
- Check contrast for event item colors.
- Check date logic around Sunday-start weeks, month boundaries, year boundaries, and ISO week labels.
- Check that provider filtering still includes Google, Samsung, Outlook/Exchange, and DAVx5 account types.
- Check that tests do not depend on the real current date unless intentional.
