part of 'main.dart';

class _SettingsSideSheet extends StatefulWidget {
  const _SettingsSideSheet({
    required this.calendarAccounts,
    required this.enabledCalendarIds,
    required this.weekStartDay,
    required this.themePreference,
    required this.showEndTimeDisplay,
    required this.showWeekNumberInIcon,
    required this.defaultAlertOption,
    required this.appVersion,
    required this.loadCalendarAccounts,
    required this.onCalendarEnabledIdsChanged,
    required this.onWeekStartDayChanged,
    required this.onThemePreferenceChanged,
    required this.onShowEndTimeDisplayChanged,
    required this.onShowWeekNumberInIconChanged,
    required this.onDefaultAlertOptionChanged,
    required this.onJumpToWeek,
  });

  final List<_CalendarAccount> calendarAccounts;
  final Set<String> enabledCalendarIds;
  final _WeekStartDay weekStartDay;
  final _ThemePreference themePreference;
  final bool showEndTimeDisplay;
  final bool showWeekNumberInIcon;
  final _AlertOption defaultAlertOption;
  final String appVersion;
  final Future<List<_CalendarAccount>> Function() loadCalendarAccounts;
  final ValueChanged<Set<String>> onCalendarEnabledIdsChanged;
  final ValueChanged<_WeekStartDay> onWeekStartDayChanged;
  final ValueChanged<_ThemePreference> onThemePreferenceChanged;
  final ValueChanged<bool> onShowEndTimeDisplayChanged;
  final ValueChanged<bool> onShowWeekNumberInIconChanged;
  final ValueChanged<_AlertOption> onDefaultAlertOptionChanged;
  final ValueChanged<BuildContext> onJumpToWeek;

  @override
  State<_SettingsSideSheet> createState() => _SettingsSideSheetState();
}

class _SettingsSideSheetState extends State<_SettingsSideSheet> {
  late List<_CalendarAccount> _calendarAccounts;
  late Set<String> _enabledCalendarIds;
  late _WeekStartDay _weekStartDay;
  late _ThemePreference _themePreference;
  late bool _showEndTimeDisplay;
  late bool _showWeekNumberInIcon;
  late _AlertOption _defaultAlertOption;
  var _isCalendarAccountsLoading = false;
  var _horizontalDragDistance = 0.0;
  var _isClosingFromSwipe = false;

  @override
  void initState() {
    super.initState();
    _calendarAccounts = widget.calendarAccounts;
    _enabledCalendarIds = Set<String>.of(widget.enabledCalendarIds);
    _weekStartDay = widget.weekStartDay;
    _themePreference = widget.themePreference;
    _showEndTimeDisplay = widget.showEndTimeDisplay;
    _showWeekNumberInIcon = widget.showWeekNumberInIcon;
    _defaultAlertOption = widget.defaultAlertOption;
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final sheetWidth = mediaSize.width < 420 ? mediaSize.width * 0.92 : 400.0;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: sheetWidth,
          height: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {
              _horizontalDragDistance = 0;
            },
            onHorizontalDragUpdate: (details) {
              if (_isClosingFromSwipe) {
                return;
              }
              _horizontalDragDistance += details.delta.dx;
              if (_horizontalDragDistance > 96) {
                _horizontalDragDistance = 0;
                _isClosingFromSwipe = true;
                Navigator.of(context).pop();
              }
            },
            onHorizontalDragEnd: (details) {
              if (!_isClosingFromSwipe &&
                  (details.primaryVelocity ?? 0) > 250) {
                _isClosingFromSwipe = true;
                Navigator.of(context).pop();
              }
            },
            child: Material(
              key: const ValueKey('settings-side-sheet'),
              color: colorScheme.surface,
              elevation: 3,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(28),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Settings',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('close-settings-button'),
                          tooltip: 'Close settings',
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        ListTile(
                          key: const ValueKey('settings-calendars-item'),
                          leading: const Icon(Icons.calendar_month),
                          title: const Text('Calendars'),
                          subtitle: Text(
                            '${_enabledCalendarIds.length} selected',
                            key: const ValueKey('settings-calendars-subtitle'),
                          ),
                          trailing: _isCalendarAccountsLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: _isCalendarAccountsLoading
                              ? null
                              : _showCalendarsBottomSheet,
                        ),
                        ListTile(
                          key: const ValueKey('settings-jump-to-week-item'),
                          leading: const Icon(Icons.today_outlined),
                          title: const Text('Jump to week'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            widget.onJumpToWeek(context);
                          },
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          key: const ValueKey('settings-week-start-item'),
                          leading: const Icon(Icons.calendar_view_week),
                          title: const Text('Week starts on'),
                          subtitle: Text(
                            _weekStartDay.label,
                            key: const ValueKey('settings-week-start-subtitle'),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showWeekStartDialog,
                        ),
                        ListTile(
                          key: const ValueKey('settings-theme-item'),
                          leading: const Icon(Icons.contrast),
                          title: const Text('Theme'),
                          subtitle: Text(
                            _themePreference.label,
                            key: const ValueKey('settings-theme-subtitle'),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showThemeDialog,
                        ),
                        ListTile(
                          key: const ValueKey('settings-default-alert-item'),
                          leading: const Icon(Icons.notifications_outlined),
                          title: const Text('Default alert'),
                          subtitle: Text(
                            _defaultAlertOption.label,
                            key: const ValueKey(
                              'settings-default-alert-subtitle',
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showDefaultAlertDialog,
                        ),
                        SwitchListTile(
                          key: const ValueKey('settings-end-time-display-item'),
                          secondary: const Icon(Icons.schedule),
                          title: const Text('End time display'),
                          value: _showEndTimeDisplay,
                          onChanged: (value) {
                            setState(() {
                              _showEndTimeDisplay = value;
                            });
                            widget.onShowEndTimeDisplayChanged(value);
                          },
                        ),
                        SwitchListTile(
                          key: const ValueKey('settings-week-number-icon-item'),
                          secondary: const Icon(Icons.calendar_today_outlined),
                          title: const Text('Show week number in icon'),
                          value: _showWeekNumberInIcon,
                          onChanged: (value) {
                            setState(() {
                              _showWeekNumberInIcon = value;
                            });
                            widget.onShowWeekNumberInIconChanged(value);
                          },
                        ),
                        const Divider(height: 32),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            'About',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        ListTile(
                          key: const ValueKey('settings-version-item'),
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Version'),
                          subtitle: Text(widget.appVersion),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCalendarsBottomSheet() async {
    setState(() {
      _isCalendarAccountsLoading = true;
    });

    final loadedCalendarAccounts = await widget.loadCalendarAccounts();

    if (!mounted) {
      return;
    }

    final loadedCalendarIds = _calendarIdsForAccounts(loadedCalendarAccounts);
    final hasSelectionForLoadedCalendars = _enabledCalendarIds.any(
      loadedCalendarIds.contains,
    );

    setState(() {
      _isCalendarAccountsLoading = false;
      _calendarAccounts = loadedCalendarAccounts;

      if (loadedCalendarIds.isNotEmpty && !hasSelectionForLoadedCalendars) {
        _enabledCalendarIds = _defaultEnabledCalendarIds(
          loadedCalendarAccounts,
        );
      }
    });

    final enabledCalendarIds = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _CalendarsBottomSheet(
          accounts: _calendarAccounts,
          enabledCalendarIds: _enabledCalendarIds,
        );
      },
    );

    if (enabledCalendarIds == null) {
      return;
    }

    setState(() {
      _enabledCalendarIds = enabledCalendarIds;
    });
    widget.onCalendarEnabledIdsChanged(Set<String>.of(enabledCalendarIds));
  }

  Set<String> _calendarIdsForAccounts(List<_CalendarAccount> accounts) {
    return {
      for (final account in accounts)
        for (final calendar in account.calendars) calendar.id,
    };
  }

  Set<String> _defaultEnabledCalendarIds(List<_CalendarAccount> accounts) {
    return {
      for (final account in accounts)
        for (final calendar in account.calendars)
          if (calendar.defaultEnabled) calendar.id,
    };
  }

  Future<void> _showWeekStartDialog() async {
    var selectedWeekStartDay = _weekStartDay;

    final weekStartDay = await showDialog<_WeekStartDay>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Week starts on'),
              content: RadioGroup<_WeekStartDay>(
                groupValue: selectedWeekStartDay,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setDialogState(() {
                    selectedWeekStartDay = value;
                  });
                },
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<_WeekStartDay>(
                      key: ValueKey('week-start-monday-option'),
                      title: Text('Monday'),
                      value: _WeekStartDay.monday,
                    ),
                    RadioListTile<_WeekStartDay>(
                      key: ValueKey('week-start-sunday-option'),
                      title: Text('Sunday'),
                      value: _WeekStartDay.sunday,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  key: const ValueKey('week-start-done-button'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedWeekStartDay);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (weekStartDay == null) {
      return;
    }

    setState(() {
      _weekStartDay = weekStartDay;
    });
    widget.onWeekStartDayChanged(weekStartDay);
  }

  Future<void> _showThemeDialog() async {
    var selectedThemePreference = _themePreference;

    final themePreference = await showDialog<_ThemePreference>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Theme'),
              content: DropdownButtonFormField<_ThemePreference>(
                key: const ValueKey('theme-select-field'),
                initialValue: selectedThemePreference,
                decoration: const InputDecoration(
                  labelText: 'Theme',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final preference in _ThemePreference.values)
                    DropdownMenuItem(
                      value: preference,
                      child: Text(preference.label),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setDialogState(() {
                    selectedThemePreference = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  key: const ValueKey('theme-done-button'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedThemePreference);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (themePreference == null) {
      return;
    }

    setState(() {
      _themePreference = themePreference;
    });
    widget.onThemePreferenceChanged(themePreference);
  }

  Future<void> _showDefaultAlertDialog() async {
    var selectedAlertOption = _defaultAlertOption;

    final defaultAlertOption = await showDialog<_AlertOption>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Default alert'),
              content: SizedBox(
                width: 360,
                child: RadioGroup<_AlertOption>(
                  groupValue: selectedAlertOption,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setDialogState(() {
                      selectedAlertOption = value;
                    });
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final option in _AlertOption.values)
                          RadioListTile<_AlertOption>(
                            key: ValueKey('default-alert-${option.name}'),
                            title: Text(option.label),
                            value: option,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  key: const ValueKey('default-alert-done-button'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedAlertOption);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (defaultAlertOption == null) {
      return;
    }

    setState(() {
      _defaultAlertOption = defaultAlertOption;
    });
    widget.onDefaultAlertOptionChanged(defaultAlertOption);
  }
}

class _CalendarsBottomSheet extends StatefulWidget {
  const _CalendarsBottomSheet({
    required this.accounts,
    required this.enabledCalendarIds,
  });

  final List<_CalendarAccount> accounts;
  final Set<String> enabledCalendarIds;

  @override
  State<_CalendarsBottomSheet> createState() => _CalendarsBottomSheetState();
}

class _CalendarsBottomSheetState extends State<_CalendarsBottomSheet> {
  late final Set<String> _enabledCalendarIds;

  @override
  void initState() {
    super.initState();
    _enabledCalendarIds = Set<String>.of(widget.enabledCalendarIds);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          key: const ValueKey('calendars-bottom-sheet'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Calendars',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('calendars-done-button'),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(Set<String>.of(_enabledCalendarIds));
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: widget.accounts.isEmpty
                    ? const Center(child: Text('No calendars available'))
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          for (final account in widget.accounts) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                              child: Text(
                                account.name,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            for (final calendar in account.calendars)
                              _CalendarSwitchRow(
                                calendar: calendar,
                                enabled: _enabledCalendarIds.contains(
                                  calendar.id,
                                ),
                                onChanged: (enabled) {
                                  setState(() {
                                    if (enabled) {
                                      _enabledCalendarIds.add(calendar.id);
                                    } else {
                                      _enabledCalendarIds.remove(calendar.id);
                                    }
                                  });
                                },
                              ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarSwitchRow extends StatelessWidget {
  const _CalendarSwitchRow({
    required this.calendar,
    required this.enabled,
    required this.onChanged,
  });

  final _AvailableCalendar calendar;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('calendar-row-${calendar.id}'),
      leading: _CalendarColorDot(color: calendar.color),
      title: Text(calendar.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Switch(
        key: ValueKey('calendar-switch-${calendar.id}'),
        value: enabled,
        onChanged: onChanged,
      ),
      onTap: () {
        onChanged(!enabled);
      },
    );
  }
}

class _CalendarColorDot extends StatelessWidget {
  const _CalendarColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

enum _WeekStartDay {
  monday('Monday'),
  sunday('Sunday');

  const _WeekStartDay(this.label);

  final String label;
}

enum _ThemePreference {
  light('Light'),
  dark('Dark'),
  arctic('Arctic'),
  forestNight('Forest Night'),
  emberLight('Ember Light'),
  noderunners('Noderunners');

  const _ThemePreference(this.label);

  final String label;

  ThemeData get themeData {
    final (seedColor, brightness) = switch (this) {
      _ThemePreference.light => (Colors.indigo, Brightness.light),
      _ThemePreference.dark => (Colors.indigo, Brightness.dark),
      _ThemePreference.arctic => (const Color(0xFF0284C7), Brightness.light),
      _ThemePreference.forestNight => (
        const Color(0xFF22C55E),
        Brightness.dark,
      ),
      _ThemePreference.emberLight => (
        const Color(0xFFDC2626),
        Brightness.light,
      ),
      _ThemePreference.noderunners => (
        const Color(0xFFFD6D00),
        Brightness.dark,
      ),
    };

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(colorScheme: colorScheme, useMaterial3: true);
  }
}

enum _AlertOption {
  none('None'),
  atTimeOfEvent('At time of event'),
  fiveMinutesBefore('5 minutes before'),
  tenMinutesBefore('10 minutes before'),
  fifteenMinutesBefore('15 minutes before'),
  thirtyMinutesBefore('30 minutes before'),
  oneHourBefore('1 hour before'),
  twoHoursBefore('2 hours before'),
  fourHoursBefore('4 hours before'),
  eightHoursBefore('8 hours before'),
  twelveHoursBefore('12 hours before'),
  oneDayBefore('1 day before'),
  twoDaysBefore('2 days before');

  const _AlertOption(this.label);

  final String label;
}

class _CalendarAccount {
  const _CalendarAccount({
    required this.name,
    required this.calendars,
    this.accountType,
  });

  final String name;
  final List<_AvailableCalendar> calendars;
  final String? accountType;
}

class _CalendarAccountBuilder {
  _CalendarAccountBuilder({required this.name, required this.accountType});

  final String name;
  final String accountType;
  final calendars = <_AvailableCalendar>[];
}

class _AvailableCalendar {
  const _AvailableCalendar({
    required this.id,
    required this.name,
    required this.color,
    this.defaultEnabled = false,
  });

  final String id;
  final String name;
  final Color color;
  final bool defaultEnabled;
}
