import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'settings.dart';
part 'bottom_sheets.dart';
part 'week_grid.dart';
part 'week_picker.dart';

final _themePreferenceNotifier = ValueNotifier<_ThemePreference>(
  _ThemePreference.light,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_ThemePreference>(
      valueListenable: _themePreferenceNotifier,
      builder: (context, themePreference, child) {
        return MaterialApp(
          title: 'Week Calendar',
          theme: themePreference.themeData,
          home: const WeekCalendarPage(),
          // debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class WeekCalendarPage extends StatefulWidget {
  const WeekCalendarPage({super.key});

  @override
  State<WeekCalendarPage> createState() => _WeekCalendarPageState();
}

class _WeekCalendarPageState extends State<WeekCalendarPage>
    with WidgetsBindingObserver {
  static const _currentWeekPage = 10000;
  static const _appVersion = '1.0.0+1';

  late final DateTime _today;
  late final PageController _weekPageController;
  late DateTime _currentWeekStart;
  late DateTime _displayedWeekStart;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  var _isSearchVisible = false;
  var _searchResults = <_SearchResult>[];
  var _selectedSearchIndex = -1;
  var _verticalSearchDragDistance = 0.0;
  final _eventsByWeekCache = <String, Map<String, List<_CalendarItem>>>{};
  var _weekStartDay = _WeekStartDay.monday;
  var _themePreference = _ThemePreference.light;
  var _showEndTimeDisplay = false;
  var _showWeekNumberInIcon = false;
  var _defaultAlertOption = _AlertOption.fifteenMinutesBefore;
  var _calendarAccountsForSettings = const <_CalendarAccount>[];
  var _hasLoadedDeviceCalendars = false;
  var _isCalendarPermissionDialogVisible = false;
  var _isCalendarPermissionDialogRouteOpen = false;
  var _isNoCalendarProviderDialogVisible = false;
  var _isNoCalendarProviderDialogRouteOpen = false;
  _EventTransfer? _eventTransfer;
  int _calendarLoadRequest = 0;
  int _launcherIconSyncVersion = 0;
  var _hasSyncedLauncherIcon = false;
  String? _requestedLauncherIconName;
  Timer? _launcherIconWeekRefreshTimer;
  final _calendarSyncGateway = const _CalendarSyncGateway();
  final _settingsGateway = const _SettingsGateway();
  late Set<String> _enabledCalendarIds;

  bool get _isCurrentWeek => _isSameDay(_displayedWeekStart, _currentWeekStart);

  bool get _canShowPreviousResult => _selectedSearchIndex > 0;

  bool get _canShowNextResult =>
      _selectedSearchIndex >= 0 &&
      _selectedSearchIndex < _searchResults.length - 1;

  _SearchResult? get _selectedSearchResult {
    if (_selectedSearchIndex < 0 ||
        _selectedSearchIndex >= _searchResults.length) {
      return null;
    }

    return _searchResults[_selectedSearchIndex];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _today = DateTime.now();
    _currentWeekStart = _startOfWeekFor(_today, _weekStartDay);
    _displayedWeekStart = _currentWeekStart;
    _weekPageController = PageController(initialPage: _currentWeekPage);
    _searchController.addListener(_handleSearchChanged);
    _enabledCalendarIds = {};
    _loadSettingsAndDisplayedWeekEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _launcherIconWeekRefreshTimer?.cancel();
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncLauncherIconWithCurrentWeek());
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekNumber = _isoWeekNumber(_displayedWeekStart);
    final weekYear = _isoWeekYear(_displayedWeekStart);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leadingWidth: 88,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: TextButton(
            onPressed: _isCurrentWeek ? null : _showCurrentWeek,
            child: const Text('Today'),
          ),
        ),
        centerTitle: true,
        title: InkWell(
          key: const ValueKey('week-title-button'),
          borderRadius: BorderRadius.circular(8),
          onTap: _showWeekPickerDialog,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Week $weekNumber, $weekYear',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 26),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: _showSettingsSideSheet,
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isSearchVisible)
              _SearchPanel(
                controller: _searchController,
                focusNode: _searchFocusNode,
                canShowPreviousResult: _canShowPreviousResult,
                canShowNextResult: _canShowNextResult,
                showPreviousResult: () {
                  _showSearchResult(_selectedSearchIndex - 1);
                },
                showNextResult: () {
                  _showSearchResult(_selectedSearchIndex + 1);
                },
                closeSearch: _hideSearch,
              ),
            if (_isSearchVisible &&
                _searchController.text.trim().isNotEmpty &&
                _searchResults.isEmpty)
              const _NoResultsBox(),
            if (_eventTransfer != null)
              _EventTransferBanner(
                transfer: _eventTransfer!,
                showEndTimeDisplay: _showEndTimeDisplay,
                cancel: _cancelEventTransfer,
              ),
            Expanded(
              child: GestureDetector(
                onVerticalDragStart: _handleVerticalDragStart,
                onVerticalDragUpdate: _handleVerticalDragUpdate,
                onVerticalDragEnd: _handleVerticalDragEnd,
                child: Stack(
                  children: [
                    PageView.builder(
                      key: const ValueKey('week-page-view'),
                      controller: _weekPageController,
                      onPageChanged: _handleWeekPageChanged,
                      itemBuilder: (context, page) {
                        final weekStart = _weekStartForPage(page);

                        return _WeekGrid(
                          weekStart: weekStart,
                          eventsByDate: _eventsForWeek(weekStart),
                          showEndTimeDisplay: _showEndTimeDisplay,
                          selectedSearchResult: _selectedSearchResult,
                          openDay: _showDayEventsBottomSheet,
                          addEvent: _showNewEventBottomSheet,
                          openEvent: _showEventDetailsBottomSheet,
                          selectTransferDate: _eventTransfer == null
                              ? null
                              : _handleEventTransferDateSelected,
                        );
                      },
                    ),
                    if (_eventTransfer != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: Center(
                          child: FilledButton(
                            key: const ValueKey('event-transfer-cancel-button'),
                            onPressed: _cancelEventTransfer,
                            child: const Text('Cancel'),
                          ),
                        ),
                      ),
                    if (_isSearchVisible)
                      Positioned.fill(
                        child: AbsorbPointer(
                          child: ColoredBox(
                            key: const ValueKey('search-grid-overlay'),
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDayEventsBottomSheet(
    DateTime day,
    List<_CalendarItem> events,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _DayEventsBottomSheet(
          day: day,
          events: events,
          openEvent: (item) {
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showEventDetailsBottomSheet(day, item);
              }
            });
          },
        );
      },
    );
  }

  Future<void> _showEventDetailsBottomSheet(
    DateTime day,
    _CalendarItem item,
  ) async {
    final result = await showModalBottomSheet<_EventSheetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _EventDetailsBottomSheet(
          day: day,
          item: item,
          categories: _calendarCategories(),
          defaultAlertOption: _defaultAlertOption,
        );
      },
    );

    if (result == null) {
      return;
    }

    switch (result) {
      case _SaveEventSheetResult(:final draft):
        await _saveCalendarEvent(draft);
      case _CopyEventSheetResult():
        _startEventTransfer(_EventTransferMode.copy, item);
      case _MoveEventSheetResult():
        _startEventTransfer(_EventTransferMode.move, item);
      case _DeleteEventSheetResult(:final scope):
        await _deleteCalendarEvent(item, scope);
    }
  }

  Future<void> _showNewEventBottomSheet(DateTime day) async {
    final result = await showModalBottomSheet<_EventSheetResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _EventDetailsBottomSheet(
          day: day,
          categories: _calendarCategories(),
          defaultAlertOption: _defaultAlertOption,
        );
      },
    );

    if (result == null) {
      return;
    }

    if (result case _SaveEventSheetResult(:final draft)) {
      await _saveCalendarEvent(draft);
    }
  }

  Future<void> _saveCalendarEvent(_DraftCalendarEvent draft) async {
    try {
      var hasPermission = await _calendarSyncGateway.hasCalendarPermission();
      if (!hasPermission) {
        hasPermission = await _calendarSyncGateway.requestCalendarPermission();
      }

      if (!hasPermission) {
        if (mounted) {
          _showCalendarPermissionDialog();
        }
        return;
      }

      if (draft.eventId == null) {
        await _calendarSyncGateway.createCalendarEvent(draft);
      } else {
        await _calendarSyncGateway.updateCalendarEvent(draft);
      }

      if (!mounted) {
        return;
      }

      _showMessage(draft.eventId == null ? 'Event saved' : 'Event updated');
      await _loadDisplayedWeekEvents(forceRefresh: true);
    } on MissingPluginException {
      if (mounted) {
        _showMessage('Calendar saving is not available on this platform.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Event could not be saved.');
      }
    }
  }

  Future<void> _deleteCalendarEvent(
    _CalendarItem item,
    _DeleteEventScope scope,
  ) async {
    try {
      var hasPermission = await _calendarSyncGateway.hasCalendarPermission();
      if (!hasPermission) {
        hasPermission = await _calendarSyncGateway.requestCalendarPermission();
      }

      if (!hasPermission) {
        if (mounted) {
          _showCalendarPermissionDialog();
        }
        return;
      }

      await _calendarSyncGateway.deleteCalendarEvent(item, scope);

      if (!mounted) {
        return;
      }

      _showMessage('Event deleted');
      await _loadDisplayedWeekEvents(forceRefresh: true);
    } on MissingPluginException {
      if (mounted) {
        _showMessage('Calendar deletion is not available on this platform.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Event could not be deleted.');
      }
    }
  }

  void _startEventTransfer(_EventTransferMode mode, _CalendarItem item) {
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _isSearchVisible = false;
      _searchResults = const [];
      _selectedSearchIndex = -1;
      _eventTransfer = _EventTransfer(mode: mode, item: item);
    });
  }

  void _cancelEventTransfer() {
    setState(() {
      _eventTransfer = null;
    });
  }

  Future<void> _handleEventTransferDateSelected(DateTime targetDay) async {
    final transfer = _eventTransfer;
    if (transfer == null) {
      return;
    }

    if (transfer.mode == _EventTransferMode.move) {
      setState(() {
        _eventTransfer = null;
      });
    }

    final draft = _draftFromItemForDate(
      transfer.item,
      targetDay,
      includeEventId: transfer.mode == _EventTransferMode.move,
    );

    if (draft == null) {
      _showMessage('Event date could not be changed.');
      return;
    }

    if (transfer.mode == _EventTransferMode.copy) {
      await _copyCalendarEvent(draft);
    } else {
      await _moveCalendarEvent(draft);
    }
  }

  Future<void> _copyCalendarEvent(_DraftCalendarEvent draft) async {
    try {
      var hasPermission = await _calendarSyncGateway.hasCalendarPermission();
      if (!hasPermission) {
        hasPermission = await _calendarSyncGateway.requestCalendarPermission();
      }

      if (!hasPermission) {
        if (mounted) {
          _showCalendarPermissionDialog();
        }
        return;
      }

      await _calendarSyncGateway.createCalendarEvent(draft);

      if (!mounted) {
        return;
      }

      _showMessage('Event copied');
      await _loadDisplayedWeekEvents(forceRefresh: true);
    } on MissingPluginException {
      if (mounted) {
        _showMessage('Calendar copying is not available on this platform.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Event could not be copied.');
      }
    }
  }

  Future<void> _moveCalendarEvent(_DraftCalendarEvent draft) async {
    try {
      var hasPermission = await _calendarSyncGateway.hasCalendarPermission();
      if (!hasPermission) {
        hasPermission = await _calendarSyncGateway.requestCalendarPermission();
      }

      if (!hasPermission) {
        if (mounted) {
          _showCalendarPermissionDialog();
        }
        return;
      }

      await _calendarSyncGateway.updateCalendarEvent(draft);

      if (!mounted) {
        return;
      }

      _showMessage('Event moved');
      await _loadDisplayedWeekEvents(forceRefresh: true);
    } on MissingPluginException {
      if (mounted) {
        _showMessage('Calendar moving is not available on this platform.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Event could not be moved.');
      }
    }
  }

  _DraftCalendarEvent? _draftFromItemForDate(
    _CalendarItem item,
    DateTime targetDay, {
    required bool includeEventId,
  }) {
    final calendarId = item.calendarId ?? _calendarCategories().firstOrNull?.id;
    final sourceStart = item.startDateTime;
    final sourceEnd = item.endDateTime;

    if (calendarId == null || sourceStart == null || sourceEnd == null) {
      return null;
    }

    final duration = sourceEnd.isAfter(sourceStart)
        ? sourceEnd.difference(sourceStart)
        : const Duration(hours: 1);
    final startDateTime = item.allDay
        ? DateTime(targetDay.year, targetDay.month, targetDay.day)
        : DateTime(
            targetDay.year,
            targetDay.month,
            targetDay.day,
            sourceStart.hour,
            sourceStart.minute,
          );
    final endDateTime = startDateTime.add(duration);

    return _DraftCalendarEvent(
      eventId: includeEventId ? item.id : null,
      title: item.title,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      allDay: item.allDay,
      categoryId: calendarId,
      location: item.location ?? '',
      alertOption: _alertOptionFromMinutes(item.alertMinutes),
      secondAlertOption: _alertOptionFromMinutes(item.secondAlertMinutes),
      repeatOption: _RepeatOption.never,
      customFrequency: _CustomFrequency.daily,
      every: 1,
      selectedWeekdays: {startDateTime.weekday},
      monthlyMode: _MonthlyMode.each,
      selectedMonthDays: {startDateTime.day},
      monthlyOrdinal: _Ordinal.third,
      monthlyOrdinalTarget: _OrdinalTarget.saturday,
      selectedMonths: {startDateTime.month},
      yearlyUsesDaysOfWeek: false,
      yearlyOrdinal: _Ordinal.last,
      yearlyOrdinalTarget: _OrdinalTarget.thursday,
      endRepeat: false,
      repeatEndDate: null,
      notes: item.notes ?? '',
      rawRrule: item.rrule?.trim().isEmpty ?? true ? null : item.rrule,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showWeekPickerDialog({BuildContext? settingsContext}) async {
    final selectedWeekStart = await showDialog<DateTime>(
      context: settingsContext ?? context,
      builder: (context) {
        return _WeekPickerDialog(
          initialMonth: _isCurrentWeek ? _today : _displayedWeekStart,
          selectedWeekStart: _displayedWeekStart,
          today: _today,
          weekStartDay: _weekStartDay,
        );
      },
    );

    if (selectedWeekStart == null || !_weekPageController.hasClients) {
      return;
    }

    final pageAnimation = _weekPageController.animateToPage(
      _pageForWeekStart(selectedWeekStart),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );

    if (settingsContext != null && settingsContext.mounted) {
      Navigator.of(settingsContext).pop();
    }

    await pageAnimation;
  }

  Future<void> _loadSettingsAndDisplayedWeekEvents() async {
    try {
      final settings = await _settingsGateway.load();

      if (!mounted) {
        return;
      }

      setState(() {
        _weekStartDay = settings.weekStartDay;
        _themePreference = settings.themePreference;
        _showEndTimeDisplay = settings.showEndTimeDisplay;
        _showWeekNumberInIcon = settings.showWeekNumberInIcon;
        _defaultAlertOption = settings.defaultAlertOption;
        _themePreferenceNotifier.value = settings.themePreference;

        if (settings.hasEnabledCalendarIds) {
          _enabledCalendarIds = settings.enabledCalendarIds;
          _hasLoadedDeviceCalendars = true;
        }

        _currentWeekStart = _startOfWeekFor(_today, _weekStartDay);
        _displayedWeekStart = _currentWeekStart;
      });
    } on MissingPluginException {
      // Tests and unsupported platforms can run with default settings.
    } catch (_) {
      // Corrupt settings should not block calendar startup.
    }

    if (mounted) {
      unawaited(_syncLauncherIconWithCurrentWeek());
      _loadDisplayedWeekEvents(requestPermission: true);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _settingsGateway.save(
        _SavedSettings(
          weekStartDay: _weekStartDay,
          themePreference: _themePreference,
          showEndTimeDisplay: _showEndTimeDisplay,
          showWeekNumberInIcon: _showWeekNumberInIcon,
          defaultAlertOption: _defaultAlertOption,
          hasEnabledCalendarIds: true,
          enabledCalendarIds: Set<String>.of(_enabledCalendarIds),
        ),
      );
    } on MissingPluginException {
      // Persistence is best-effort outside Android.
    } catch (_) {
      // Keep UI responsive if settings persistence fails.
    }
  }

  void _showSettingsSideSheet() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _SettingsSideSheet(
          calendarAccounts: _calendarAccountsForSettings,
          enabledCalendarIds: _enabledCalendarIds,
          weekStartDay: _weekStartDay,
          themePreference: _themePreference,
          showEndTimeDisplay: _showEndTimeDisplay,
          showWeekNumberInIcon: _showWeekNumberInIcon,
          defaultAlertOption: _defaultAlertOption,
          appVersion: _appVersion,
          loadCalendarAccounts: _loadCalendarAccountsForSettings,
          onCalendarEnabledIdsChanged: (enabledIds) {
            setState(() {
              _enabledCalendarIds = enabledIds;
            });
            _saveSettings();
          },
          onWeekStartDayChanged: (weekStartDay) {
            setState(() {
              _weekStartDay = weekStartDay;
              _currentWeekStart = _startOfWeekFor(_today, _weekStartDay);
              _eventsByWeekCache.clear();
              final currentPage = _weekPageController.hasClients
                  ? (_weekPageController.page?.round() ?? _currentWeekPage)
                  : _currentWeekPage;
              _displayedWeekStart = _currentWeekStart.add(
                Duration(days: (currentPage - _currentWeekPage) * 7),
              );
            });
            _saveSettings();
            unawaited(_syncLauncherIconWithCurrentWeek());
            _loadDisplayedWeekEvents();
          },
          onThemePreferenceChanged: (themePreference) {
            setState(() {
              _themePreference = themePreference;
            });
            _themePreferenceNotifier.value = themePreference;
            _saveSettings();
          },
          onShowEndTimeDisplayChanged: (showEndTimeDisplay) {
            setState(() {
              _showEndTimeDisplay = showEndTimeDisplay;
            });
            _saveSettings();
          },
          onShowWeekNumberInIconChanged: (showWeekNumberInIcon) {
            setState(() {
              _showWeekNumberInIcon = showWeekNumberInIcon;
            });
            _saveSettings();
            unawaited(_syncLauncherIconWithCurrentWeek());
          },
          onDefaultAlertOptionChanged: (defaultAlertOption) {
            setState(() {
              _defaultAlertOption = defaultAlertOption;
            });
            _saveSettings();
          },
          onJumpToWeek: (settingsContext) {
            _showWeekPickerDialog(settingsContext: settingsContext);
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  Future<List<_CalendarAccount>> _loadCalendarAccountsForSettings() async {
    try {
      var hasPermission = await _calendarSyncGateway.hasCalendarPermission();

      if (!hasPermission) {
        hasPermission = await _calendarSyncGateway.requestCalendarPermission();
      }

      if (!hasPermission) {
        if (mounted) {
          _showCalendarPermissionDialog();
        }

        return const [];
      }

      final calendarAccounts = await _calendarSyncGateway.getCalendars();

      if (!mounted) {
        return calendarAccounts;
      }

      setState(() {
        if (calendarAccounts.isNotEmpty) {
          _calendarAccountsForSettings = calendarAccounts;

          if (!_hasLoadedDeviceCalendars) {
            _enabledCalendarIds = _defaultEnabledCalendarIds(calendarAccounts);
            _hasLoadedDeviceCalendars = true;
          }
        }
      });

      if (calendarAccounts.isEmpty) {
        _showNoCalendarProviderDialog();
      } else {
        _hideNoCalendarProviderDialog();
      }

      return calendarAccounts;
    } on MissingPluginException {
      return _calendarAccountsForSettings;
    } catch (_) {
      if (mounted) {
        _showNoCalendarProviderDialog();
      }

      return const [];
    }
  }

  void _showCalendarPermissionDialog() {
    if (_isCalendarPermissionDialogVisible || !mounted) {
      return;
    }

    _isCalendarPermissionDialogVisible = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isCalendarPermissionDialogVisible) {
        return;
      }

      _isCalendarPermissionDialogRouteOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: Dialog.fullscreen(
              key: const ValueKey('calendar-permission-dialog'),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Calendar permission required',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Week Calendar needs calendar permission to show, create, update, move, copy, and delete events.',
                        key: const ValueKey('calendar-permission-message'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const ValueKey('retry-calendar-permission-button'),
                        onPressed: () {
                          _loadDisplayedWeekEvents(requestPermission: true);
                        },
                        child: const Text('Grant permission'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ).then((_) {
        if (mounted) {
          _isCalendarPermissionDialogVisible = false;
          _isCalendarPermissionDialogRouteOpen = false;
        }
      });
    });
  }

  void _hideCalendarPermissionDialog() {
    if (!_isCalendarPermissionDialogVisible || !mounted) {
      return;
    }

    _isCalendarPermissionDialogVisible = false;
    if (_isCalendarPermissionDialogRouteOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showNoCalendarProviderDialog() {
    if (_isNoCalendarProviderDialogVisible || !mounted) {
      return;
    }

    _isNoCalendarProviderDialogVisible = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isNoCalendarProviderDialogVisible) {
        return;
      }

      _isNoCalendarProviderDialogRouteOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: Dialog.fullscreen(
              key: const ValueKey('no-calendar-provider-dialog'),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Calendar setup required',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No CalDAV found. Setup an account via Google-, Samsung-, Outlook/Exchange sync apps, or DAVx5 configured to continue.',
                        key: const ValueKey('no-calendar-provider-message'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        key: const ValueKey('retry-calendar-provider-button'),
                        onPressed: () {
                          _loadDisplayedWeekEvents(requestPermission: true);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ).then((_) {
        if (mounted) {
          _isNoCalendarProviderDialogVisible = false;
          _isNoCalendarProviderDialogRouteOpen = false;
        }
      });
    });
  }

  void _hideNoCalendarProviderDialog() {
    if (!_isNoCalendarProviderDialogVisible || !mounted) {
      return;
    }

    _isNoCalendarProviderDialogVisible = false;
    if (_isNoCalendarProviderDialogRouteOpen) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _handleWeekPageChanged(int page) {
    final weekStart = _weekStartForPage(page);

    setState(() {
      _displayedWeekStart = weekStart;
    });
    unawaited(_syncLauncherIconWithCurrentWeek());
    _loadDisplayedWeekEvents();
  }

  Future<void> _syncLauncherIconWithCurrentWeek() async {
    final weekNumber = _isoWeekNumber(DateTime.now()).clamp(1, 53);
    final iconName = _showWeekNumberInIcon ? 'icon_$weekNumber' : null;
    _scheduleLauncherIconCurrentWeekRefresh();

    if (_hasSyncedLauncherIcon && _requestedLauncherIconName == iconName) {
      return;
    }

    final syncVersion = ++_launcherIconSyncVersion;

    try {
      await _settingsGateway.setLauncherIcon(iconName);

      if (syncVersion != _launcherIconSyncVersion) {
        return;
      }

      _requestedLauncherIconName = iconName;
      _hasSyncedLauncherIcon = true;
    } on MissingPluginException {
      // Dynamic launcher icons are only available through the Android channel.
      if (syncVersion == _launcherIconSyncVersion) {
        _requestedLauncherIconName = iconName;
        _hasSyncedLauncherIcon = true;
      }
    } on PlatformException {
      // Some launchers reject icon changes; the setting itself can remain saved.
    } catch (_) {
      // Keep the calendar usable if a launcher implementation fails.
    }
  }

  void _scheduleLauncherIconCurrentWeekRefresh() {
    _launcherIconWeekRefreshTimer?.cancel();

    if (!_showWeekNumberInIcon) {
      return;
    }

    final now = DateTime.now();
    final nextIsoWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: DateTime.daysPerWeek - now.weekday + DateTime.monday));

    _launcherIconWeekRefreshTimer = Timer(
      nextIsoWeekStart.difference(now),
      () => unawaited(_syncLauncherIconWithCurrentWeek()),
    );
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    _verticalSearchDragDistance = 0;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_eventTransfer != null) {
      return;
    }

    _verticalSearchDragDistance += details.delta.dy;
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_eventTransfer != null) {
      _verticalSearchDragDistance = 0;
      return;
    }

    final velocity = details.primaryVelocity ?? 0;

    if (_isSearchVisible) {
      if (_verticalSearchDragDistance < -80 || velocity < -250) {
        _hideSearch();
      }
      _verticalSearchDragDistance = 0;
      return;
    }

    if (_verticalSearchDragDistance > 80 || velocity > 250) {
      _showSearch();
    }
    _verticalSearchDragDistance = 0;
  }

  void _showCurrentWeek() {
    _weekPageController.animateToPage(
      _currentWeekPage,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _showSearch() {
    setState(() {
      _isSearchVisible = true;
      _searchResults = const [];
      _selectedSearchIndex = -1;
    });
    _searchController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _hideSearch() {
    _searchFocusNode.unfocus();
    _searchController.clear();
    setState(() {
      _isSearchVisible = false;
      _searchResults = const [];
      _selectedSearchIndex = -1;
    });
  }

  void _handleSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    final results = query.isEmpty ? <_SearchResult>[] : _searchEvents(query);

    setState(() {
      _searchResults = results;
      _selectedSearchIndex = results.isEmpty ? -1 : 0;
    });

    if (results.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSearchResult(0);
        }
      });
    }
  }

  List<_SearchResult> _searchEvents(String query) {
    final results = <_SearchResult>[];
    final weekStarts = [
      for (final weekKey in _eventsByWeekCache.keys)
        ?DateTime.tryParse(weekKey),
    ]..sort();

    for (final weekStart in weekStarts) {
      for (final weekday in _orderedWeekdays(_weekStartDay)) {
        final date = _dateForWeekday(weekStart, weekday);
        final events =
            _eventsForWeek(weekStart)[_dateKey(date)] ??
            const <_CalendarItem>[];

        for (var itemIndex = 0; itemIndex < events.length; itemIndex++) {
          final item = events[itemIndex];
          final searchableText = '${item.title} ${_formatTime(item.startTime)}'
              .toLowerCase();

          if (searchableText.contains(query)) {
            results.add(
              _SearchResult(
                weekStart: weekStart,
                date: date,
                weekday: weekday,
                itemIndex: itemIndex,
              ),
            );
          }
        }
      }
    }

    return results;
  }

  void _showSearchResult(int index) {
    if (index < 0 || index >= _searchResults.length) {
      return;
    }

    final result = _searchResults[index];

    setState(() {
      _selectedSearchIndex = index;
    });

    if (!_weekPageController.hasClients) {
      return;
    }

    _weekPageController.animateToPage(
      _pageForWeekStart(result.weekStart),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  DateTime _weekStartForPage(int page) {
    return _currentWeekStart.add(Duration(days: (page - _currentWeekPage) * 7));
  }

  int _pageForWeekStart(DateTime weekStart) {
    return _currentWeekPage +
        weekStart.difference(_currentWeekStart).inDays ~/ 7;
  }

  DateTime _startOfWeekFor(DateTime date, _WeekStartDay weekStartDay) {
    final currentDate = DateTime(date.year, date.month, date.day);
    return currentDate.subtract(
      Duration(days: _daysSinceWeekStart(date, weekStartDay)),
    );
  }

  int _isoWeekNumber(DateTime date) {
    return _isoWeekNumberFor(date);
  }

  int _isoWeekYear(DateTime date) {
    return _isoWeekYearFor(date);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  DateTime _dateForWeekday(DateTime weekStart, int weekday) {
    return weekStart.add(
      Duration(days: _orderedWeekdays(_weekStartDay).indexOf(weekday)),
    );
  }

  List<int> _orderedWeekdays(_WeekStartDay weekStartDay) {
    return switch (weekStartDay) {
      _WeekStartDay.monday => const [
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ],
      _WeekStartDay.sunday => const [
        DateTime.sunday,
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
      ],
    };
  }

  int _daysSinceWeekStart(DateTime date, _WeekStartDay weekStartDay) {
    return switch (weekStartDay) {
      _WeekStartDay.monday => date.weekday - DateTime.monday,
      _WeekStartDay.sunday => date.weekday % DateTime.sunday,
    };
  }

  Future<void> _loadDisplayedWeekEvents({
    bool requestPermission = false,
    bool forceRefresh = false,
  }) async {
    final request = ++_calendarLoadRequest;

    try {
      var hasPermission = await _calendarSyncGateway.hasCalendarPermission();

      if (!hasPermission && requestPermission) {
        hasPermission = await _calendarSyncGateway.requestCalendarPermission();
      }

      if (request != _calendarLoadRequest || !mounted) {
        return;
      }

      if (!hasPermission) {
        setState(() {
          _eventsByWeekCache.clear();
          _calendarAccountsForSettings = const [];
          _hasLoadedDeviceCalendars = false;
        });
        _showCalendarPermissionDialog();
        return;
      }

      _hideCalendarPermissionDialog();
      final calendarAccounts = await _calendarSyncGateway.getCalendars();

      if (request != _calendarLoadRequest || !mounted) {
        return;
      }

      if (calendarAccounts.isEmpty) {
        setState(() {
          _eventsByWeekCache.clear();
          _calendarAccountsForSettings = const [];
          _hasLoadedDeviceCalendars = false;
        });
        _showNoCalendarProviderDialog();
        return;
      }

      var shouldSaveSettings = false;
      setState(() {
        _calendarAccountsForSettings = calendarAccounts;
        if (!_hasLoadedDeviceCalendars) {
          _enabledCalendarIds = _defaultEnabledCalendarIds(calendarAccounts);
          _hasLoadedDeviceCalendars = true;
          shouldSaveSettings = true;
        }
      });
      if (shouldSaveSettings) {
        _saveSettings();
      }

      for (final weekStart in _preloadWeekStarts(_displayedWeekStart)) {
        final weekKey = _dateKey(weekStart);
        if (!forceRefresh && _eventsByWeekCache.containsKey(weekKey)) {
          continue;
        }

        final events = await _calendarSyncGateway.getCalendarEvents(
          weekStart,
          weekStart.add(const Duration(days: 7)),
        );

        if (request != _calendarLoadRequest || !mounted) {
          return;
        }

        setState(() {
          _eventsByWeekCache[weekKey] = _groupEventsByDate(events, weekStart);
        });
      }
      _hideNoCalendarProviderDialog();
      _hideCalendarPermissionDialog();
    } on MissingPluginException {
      if (request != _calendarLoadRequest || !mounted) {
        return;
      }

      setState(() {
        _eventsByWeekCache.clear();
      });
    } catch (_) {
      if (request != _calendarLoadRequest || !mounted) {
        return;
      }

      setState(() {
        _eventsByWeekCache.clear();
      });
      _showNoCalendarProviderDialog();
    }
  }

  List<DateTime> _preloadWeekStarts(DateTime weekStart) {
    return [
      weekStart,
      weekStart.subtract(const Duration(days: 7)),
      weekStart.add(const Duration(days: 7)),
    ];
  }

  Map<String, List<_CalendarItem>> _eventsForWeek(DateTime weekStart) {
    return _eventsByWeekCache[_dateKey(weekStart)] ?? const {};
  }

  Map<String, List<_CalendarItem>> _groupEventsByDate(
    List<_CalendarItem> events,
    DateTime weekStart,
  ) {
    final groupedEvents = <String, List<_CalendarItem>>{};
    final weekEnd = weekStart.add(const Duration(days: 7));

    for (final event in events) {
      final startDateTime = event.startDateTime;
      final endDateTime = event.endDateTime;

      if (startDateTime == null || endDateTime == null) {
        continue;
      }

      final eventStartDate = DateTime(
        startDateTime.year,
        startDateTime.month,
        startDateTime.day,
      );
      final eventEndDate = _eventEndDateForGrouping(event);
      var currentDate = eventStartDate.isAfter(weekStart)
          ? eventStartDate
          : weekStart;
      final lastDate = eventEndDate.isBefore(weekEnd)
          ? eventEndDate
          : weekEnd.subtract(const Duration(days: 1));

      while (!currentDate.isAfter(lastDate)) {
        groupedEvents.putIfAbsent(_dateKey(currentDate), () => []).add(event);
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    for (final events in groupedEvents.values) {
      events.sort((first, second) {
        if (first.allDay != second.allDay) {
          return first.allDay ? -1 : 1;
        }

        return first.startDateTime!.compareTo(second.startDateTime!);
      });
    }

    return groupedEvents;
  }

  DateTime _eventEndDateForGrouping(_CalendarItem event) {
    final endDateTime = event.endDateTime!;
    final endDate = DateTime(
      endDateTime.year,
      endDateTime.month,
      endDateTime.day,
    );

    if (event.allDay && endDateTime.hour == 0 && endDateTime.minute == 0) {
      return endDate.subtract(const Duration(days: 1));
    }

    return endDate;
  }

  Set<String> _defaultEnabledCalendarIds(List<_CalendarAccount> accounts) {
    return {
      for (final account in accounts)
        for (final calendar in account.calendars)
          if (calendar.defaultEnabled) calendar.id,
    };
  }

  List<_AvailableCalendar> _calendarCategories() {
    return [
      for (final account in _calendarAccountsForSettings)
        for (final calendar in account.calendars)
          if (_enabledCalendarIds.isEmpty ||
              _enabledCalendarIds.contains(calendar.id))
            calendar,
    ];
  }
}

enum _EventTransferMode { copy, move }

class _EventTransfer {
  const _EventTransfer({required this.mode, required this.item});

  final _EventTransferMode mode;
  final _CalendarItem item;
}

class _EventTransferBanner extends StatelessWidget {
  const _EventTransferBanner({
    required this.transfer,
    required this.showEndTimeDisplay,
    required this.cancel,
  });

  final _EventTransfer transfer;
  final bool showEndTimeDisplay;
  final VoidCallback cancel;

  @override
  Widget build(BuildContext context) {
    final isCopy = transfer.mode == _EventTransferMode.copy;
    final backgroundColor = isCopy
        ? Colors.blue.shade50
        : Colors.orange.shade50;
    final borderColor = isCopy ? Colors.blue.shade600 : Colors.orange.shade700;
    final foregroundColor = isCopy
        ? Colors.blue.shade900
        : Colors.orange.shade900;

    return Material(
      key: ValueKey(isCopy ? 'copy-mode-banner' : 'move-mode-banner'),
      color: backgroundColor,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 56) / 2;
            return Row(
              children: [
                Container(
                  width: itemWidth.clamp(120, 320).toDouble(),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _CalendarItemRow(
                    item: transfer.item,
                    showEndTimeDisplay: showEndTimeDisplay,
                    isHighlighted: false,
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const ValueKey('event-transfer-close-button'),
                  tooltip: isCopy ? 'Cancel copy mode' : 'Cancel move mode',
                  color: foregroundColor,
                  onPressed: cancel,
                  icon: const Icon(Icons.close),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.focusNode,
    required this.canShowPreviousResult,
    required this.canShowNextResult,
    required this.showPreviousResult,
    required this.showNextResult,
    required this.closeSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canShowPreviousResult;
  final bool canShowNextResult;
  final VoidCallback showPreviousResult;
  final VoidCallback showNextResult;
  final VoidCallback closeSearch;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('search-bar'),
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Previous result',
              onPressed: canShowPreviousResult ? showPreviousResult : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Next result',
              onPressed: canShowNextResult ? showNextResult : null,
              icon: const Icon(Icons.chevron_right),
            ),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return TextField(
                    key: const ValueKey('event-search-field'),
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search events...',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: value.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: controller.clear,
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: closeSearch, child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }
}

class _NoResultsBox extends StatelessWidget {
  const _NoResultsBox();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('no-results-box'),
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          'No results found',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _CalendarSyncGateway {
  const _CalendarSyncGateway();

  static const _channel = MethodChannel('week_calendar/calendar');

  Future<bool> hasCalendarPermission() async {
    return await _channel.invokeMethod<bool>('hasCalendarPermission') ?? false;
  }

  Future<bool> requestCalendarPermission() async {
    return await _channel.invokeMethod<bool>('requestCalendarPermission') ??
        false;
  }

  Future<List<_CalendarAccount>> getCalendars() async {
    final rows = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
      'getCalendars',
    );

    if (rows == null) {
      return const [];
    }

    return _calendarAccountsFromRows(rows);
  }

  Future<List<_CalendarItem>> getCalendarEvents(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _channel
        .invokeListMethod<Map<dynamic, dynamic>>('getCalendarEvents', {
          'startMillis': start.millisecondsSinceEpoch,
          'endMillis': end.millisecondsSinceEpoch,
        });

    if (rows == null) {
      return const [];
    }

    return [for (final row in rows) ?_calendarItemFromRow(row)];
  }

  Future<String> createCalendarEvent(_DraftCalendarEvent draft) async {
    final id = await _channel.invokeMethod<String>(
      'createCalendarEvent',
      draft.toPlatformArguments(),
    );

    if (id == null || id.isEmpty) {
      throw StateError('Calendar provider did not return an event id.');
    }

    return id;
  }

  Future<void> updateCalendarEvent(_DraftCalendarEvent draft) async {
    await _channel.invokeMethod<void>(
      'updateCalendarEvent',
      draft.toPlatformArguments(),
    );
  }

  Future<void> deleteCalendarEvent(
    _CalendarItem item,
    _DeleteEventScope scope,
  ) async {
    await _channel.invokeMethod<void>('deleteCalendarEvent', {
      'eventId': item.id,
      'calendarId': item.calendarId,
      'startMillis': item.startDateTime?.millisecondsSinceEpoch,
      'endMillis': item.endDateTime?.millisecondsSinceEpoch,
      'allDay': item.allDay,
      'deleteScope': scope.platformValue,
    });
  }

  List<_CalendarAccount> _calendarAccountsFromRows(
    List<Map<dynamic, dynamic>> rows,
  ) {
    final groupedCalendars = <String, _CalendarAccountBuilder>{};

    for (final row in rows) {
      final calendar = _availableCalendarFromRow(row);
      final accountName = row['accountName']?.toString().trim();
      final accountType = row['accountType']?.toString().trim() ?? '';
      final providerLabel = _calendarProviderLabel(accountType);

      if (calendar == null ||
          accountName == null ||
          accountName.isEmpty ||
          providerLabel == null) {
        continue;
      }

      final accountKey = '$accountName\n$accountType';
      groupedCalendars
          .putIfAbsent(
            accountKey,
            () => _CalendarAccountBuilder(
              name: '$accountName · $providerLabel',
              accountType: accountType,
            ),
          )
          .calendars
          .add(calendar);
    }

    return [
      for (final builder in groupedCalendars.values)
        _CalendarAccount(
          name: builder.name,
          accountType: builder.accountType,
          calendars: builder.calendars,
        ),
    ];
  }

  String? _calendarProviderLabel(String accountType) {
    final normalizedAccountType = accountType.toLowerCase();

    if (normalizedAccountType.contains('google')) {
      return 'Google';
    }

    if (normalizedAccountType.contains('samsung')) {
      return 'Samsung';
    }

    if (normalizedAccountType.contains('outlook') ||
        normalizedAccountType.contains('microsoft') ||
        normalizedAccountType.contains('office') ||
        normalizedAccountType.contains('exchange')) {
      return 'Outlook';
    }

    if (normalizedAccountType.contains('davdroid') ||
        normalizedAccountType.contains('davx5') ||
        normalizedAccountType.contains('bitfire')) {
      return 'DAVx5';
    }

    return null;
  }

  _AvailableCalendar? _availableCalendarFromRow(Map<dynamic, dynamic> row) {
    final id = row['id']?.toString();
    final name = row['name']?.toString().trim();

    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }

    final colorValue = row['color'];
    final normalizedColor = colorValue is int && colorValue != 0
        ? colorValue & 0xFFFFFFFF
        : 0xFF2563EB;

    return _AvailableCalendar(
      id: id,
      name: name,
      color: Color(normalizedColor),
      defaultEnabled: row['enabled'] != false,
    );
  }

  _CalendarItem? _calendarItemFromRow(Map<dynamic, dynamic> row) {
    final title = row['title'];
    final startYear = row['startYear'];
    final startMonth = row['startMonth'];
    final startDay = row['startDay'];
    final startHour = row['startHour'];
    final startMinute = row['startMinute'];
    final endYear = row['endYear'];
    final endMonth = row['endMonth'];
    final endDay = row['endDay'];
    final endHour = row['endHour'];
    final endMinute = row['endMinute'];

    if (startYear is! int ||
        startMonth is! int ||
        startDay is! int ||
        startHour is! int ||
        startMinute is! int ||
        title is! String ||
        title.trim().isEmpty) {
      return null;
    }

    final startDateTime = DateTime(
      startYear,
      startMonth,
      startDay,
      startHour,
      startMinute,
    );
    final endDateTime =
        endYear is int &&
            endMonth is int &&
            endDay is int &&
            endHour is int &&
            endMinute is int
        ? DateTime(endYear, endMonth, endDay, endHour, endMinute)
        : startDateTime.add(const Duration(hours: 1));
    final colorValue = row['color'];
    final normalizedColor = colorValue is int && colorValue != 0
        ? colorValue & 0xFFFFFFFF
        : 0xFF2563EB;

    return _CalendarItem(
      id: row['id']?.toString(),
      calendarId: row['calendarId']?.toString(),
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      startTime: TimeOfDay.fromDateTime(startDateTime),
      title: title,
      color: Color(normalizedColor),
      allDay: row['allDay'] == true,
      calendarName: row['calendarName']?.toString(),
      location: row['location']?.toString(),
      notes: row['notes']?.toString(),
      rrule: row['rrule']?.toString(),
      alertMinutes: _intFromRow(row['alertMinutes']),
      secondAlertMinutes: _intFromRow(row['secondAlertMinutes']),
    );
  }

  int? _intFromRow(Object? value) {
    return switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value),
      _ => null,
    };
  }
}

class _SettingsGateway {
  const _SettingsGateway();

  static const _channel = MethodChannel('week_calendar/calendar');

  Future<_SavedSettings> load() async {
    final row = await _channel.invokeMapMethod<dynamic, dynamic>(
      'getAppSettings',
    );

    if (row == null) {
      return const _SavedSettings();
    }

    final enabledCalendarRows = row['enabledCalendarIds'];

    return _SavedSettings(
      weekStartDay: _weekStartDayFromName(row['weekStartDay']?.toString()),
      themePreference: _themePreferenceFromName(
        row['themePreference']?.toString(),
      ),
      showEndTimeDisplay: row['showEndTimeDisplay'] == true,
      showWeekNumberInIcon: row['showWeekNumberInIcon'] == true,
      defaultAlertOption: _alertOptionFromName(
        row['defaultAlertOption']?.toString(),
      ),
      hasEnabledCalendarIds: row['hasEnabledCalendarIds'] == true,
      enabledCalendarIds: {
        if (enabledCalendarRows is List)
          for (final id in enabledCalendarRows) id.toString(),
      },
    );
  }

  Future<void> save(_SavedSettings settings) async {
    await _channel.invokeMethod<void>('saveAppSettings', {
      'weekStartDay': settings.weekStartDay.name,
      'themePreference': settings.themePreference.name,
      'showEndTimeDisplay': settings.showEndTimeDisplay,
      'showWeekNumberInIcon': settings.showWeekNumberInIcon,
      'defaultAlertOption': settings.defaultAlertOption.name,
      'enabledCalendarIds': settings.enabledCalendarIds.toList(),
    });
  }

  Future<void> setLauncherIcon(String? iconName) async {
    await _channel.invokeMethod<void>('setLauncherIcon', {
      'iconName': iconName,
    });
  }

  _WeekStartDay _weekStartDayFromName(String? name) {
    return switch (name) {
      'sunday' => _WeekStartDay.sunday,
      _ => _WeekStartDay.monday,
    };
  }

  _ThemePreference _themePreferenceFromName(String? name) {
    return _ThemePreference.values.firstWhere(
      (preference) => preference.name == name,
      orElse: () => _ThemePreference.light,
    );
  }

  _AlertOption _alertOptionFromName(String? name) {
    return _AlertOption.values.firstWhere(
      (option) => option.name == name,
      orElse: () => _AlertOption.fifteenMinutesBefore,
    );
  }
}

class _SavedSettings {
  const _SavedSettings({
    this.weekStartDay = _WeekStartDay.monday,
    this.themePreference = _ThemePreference.light,
    this.showEndTimeDisplay = false,
    this.showWeekNumberInIcon = false,
    this.defaultAlertOption = _AlertOption.fifteenMinutesBefore,
    this.hasEnabledCalendarIds = false,
    this.enabledCalendarIds = const {},
  });

  final _WeekStartDay weekStartDay;
  final _ThemePreference themePreference;
  final bool showEndTimeDisplay;
  final bool showWeekNumberInIcon;
  final _AlertOption defaultAlertOption;
  final bool hasEnabledCalendarIds;
  final Set<String> enabledCalendarIds;
}
