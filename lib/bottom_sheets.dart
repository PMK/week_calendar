part of 'main.dart';

sealed class _EventSheetResult {
  const _EventSheetResult();
}

class _SaveEventSheetResult extends _EventSheetResult {
  const _SaveEventSheetResult(this.draft);

  final _DraftCalendarEvent draft;
}

class _CopyEventSheetResult extends _EventSheetResult {
  const _CopyEventSheetResult();
}

class _MoveEventSheetResult extends _EventSheetResult {
  const _MoveEventSheetResult();
}

class _DeleteEventSheetResult extends _EventSheetResult {
  const _DeleteEventSheetResult(this.scope);

  final _DeleteEventScope scope;
}

enum _DeleteEventScope {
  thisOnly('thisOnly'),
  future('future'),
  all('all');

  const _DeleteEventScope(this.platformValue);

  final String platformValue;
}

class _DayEventsBottomSheet extends StatefulWidget {
  const _DayEventsBottomSheet({
    required this.day,
    required this.events,
    required this.openEvent,
  });

  final DateTime day;
  final List<_CalendarItem> events;
  final ValueChanged<_CalendarItem> openEvent;

  @override
  State<_DayEventsBottomSheet> createState() => _DayEventsBottomSheetState();
}

class _DayEventsBottomSheetState extends State<_DayEventsBottomSheet> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: SafeArea(
        child: Material(
          key: const ValueKey('day-events-bottom-sheet'),
          color: colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _fullDateLabel(widget.day),
                        key: const ValueKey('day-events-title'),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('close-day-events-button'),
                      tooltip: 'Close day events',
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
                child: widget.events.isEmpty
                    ? Center(
                        child: Text(
                          'No events',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: widget.events.length > 8,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: widget.events.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 8);
                          },
                          itemBuilder: (context, index) {
                            final item = widget.events[index];

                            return GestureDetector(
                              key: ValueKey('day-events-item-$index'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                widget.openEvent(item);
                              },
                              child: _CalendarItemRow(
                                item: item,
                                showEndTimeDisplay: false,
                                isHighlighted: false,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDetailsBottomSheet extends StatelessWidget {
  const _EventDetailsBottomSheet({
    required this.day,
    this.item,
    this.categories = const [],
    this.defaultAlertOption = _AlertOption.fifteenMinutesBefore,
  });

  final DateTime day;
  final _CalendarItem? item;
  final List<_AvailableCalendar> categories;
  final _AlertOption defaultAlertOption;

  @override
  Widget build(BuildContext context) {
    final event = item;
    return _CreateEventBottomSheet(
      day: day,
      categories: categories,
      defaultAlertOption: defaultAlertOption,
      item: event,
    );
  }
}

class _CreateEventBottomSheet extends StatefulWidget {
  const _CreateEventBottomSheet({
    required this.day,
    required this.categories,
    required this.defaultAlertOption,
    this.item,
  });

  final DateTime day;
  final List<_AvailableCalendar> categories;
  final _AlertOption defaultAlertOption;
  final _CalendarItem? item;

  @override
  State<_CreateEventBottomSheet> createState() =>
      _CreateEventBottomSheetState();
}

class _CreateEventBottomSheetState extends State<_CreateEventBottomSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _everyController = TextEditingController(text: '1');
  final _scrollController = ScrollController();

  var _allDay = false;
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  late _AlertOption _alertOption;
  var _secondAlertOption = _AlertOption.none;
  var _repeatOption = _RepeatOption.never;
  var _customFrequency = _CustomFrequency.daily;
  var _selectedWeekdays = <int>{};
  var _monthlyMode = _MonthlyMode.each;
  var _selectedMonthDays = <int>{};
  var _monthlyOrdinal = _Ordinal.third;
  var _monthlyOrdinalTarget = _OrdinalTarget.saturday;
  var _selectedMonths = <int>{};
  var _yearlyUsesDaysOfWeek = false;
  var _yearlyOrdinal = _Ordinal.last;
  var _yearlyOrdinalTarget = _OrdinalTarget.thursday;
  var _endRepeat = false;
  DateTime? _repeatEndDate;
  String? _selectedCategoryId;
  OverlayEntry? _categoryTooltipEntry;
  Timer? _categoryTooltipTimer;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item == null) {
      final roundedStart = _roundedFutureFiveMinute(DateTime.now());
      _startDateTime = DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
        roundedStart.hour,
        roundedStart.minute,
      );
      _endDateTime = _startDateTime.add(const Duration(hours: 1));
      _alertOption = widget.defaultAlertOption;
      _selectedCategoryId = widget.categories.isEmpty
          ? null
          : widget.categories.first.id;
    } else {
      _titleController.text = item.title;
      _locationController.text = item.location ?? '';
      _notesController.text = item.notes ?? '';
      _allDay = item.allDay;
      _startDateTime =
          item.startDateTime ??
          DateTime(widget.day.year, widget.day.month, widget.day.day);
      _endDateTime =
          item.endDateTime ?? _startDateTime.add(const Duration(hours: 1));
      _alertOption = _alertOptionFromMinutes(item.alertMinutes);
      _secondAlertOption = _alertOptionFromMinutes(item.secondAlertMinutes);
      _selectedCategoryId =
          item.calendarId ??
          (widget.categories.isEmpty ? null : widget.categories.first.id);
    }
    _repeatEndDate = _startDateTime.add(const Duration(days: 30));
    _selectedWeekdays = {_startDateTime.weekday};
    _selectedMonthDays = {_startDateTime.day};
    _selectedMonths = {_startDateTime.month};
    if (item != null) {
      _applyRrule(item.rrule);
    }
    _titleController.addListener(_handleValidationChanged);
    _everyController.addListener(_handleValidationChanged);
  }

  @override
  void dispose() {
    _categoryTooltipTimer?.cancel();
    _categoryTooltipEntry?.remove();
    _titleController
      ..removeListener(_handleValidationChanged)
      ..dispose();
    _locationController.dispose();
    _notesController.dispose();
    _everyController
      ..removeListener(_handleValidationChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _isValid;

    return FractionallySizedBox(
      heightFactor: 0.94,
      child: SafeArea(
        child: Material(
          key: ValueKey(
            widget.item == null
                ? 'new-event-bottom-sheet'
                : 'edit-event-bottom-sheet',
          ),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    TextButton(
                      key: const ValueKey('cancel-new-event-button'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    Expanded(
                      child: Text(
                        widget.item == null ? 'New event' : 'Edit event',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton(
                      key: const ValueKey('done-new-event-button'),
                      onPressed: isValid ? _saveDraft : null,
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        key: const ValueKey('event-title-field'),
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        key: const ValueKey('event-all-day-field'),
                        title: const Text('All day event'),
                        value: _allDay,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.trailing,
                        onChanged: (value) {
                          setState(() {
                            _allDay = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _DateTimeGrid(
                        startDateTime: _startDateTime,
                        endDateTime: _endDateTime,
                        allDay: _allDay,
                        onPickStartDate: () => _pickDate(isStart: true),
                        onPickStartTime: () => _pickTime(isStart: true),
                        onPickEndDate: () => _pickDate(isStart: false),
                        onPickEndTime: () => _pickTime(isStart: false),
                      ),
                      const SizedBox(height: 16),
                      widget.categories.isEmpty
                          ? InputDecorator(
                              key: const ValueKey('event-category-empty-field'),
                              decoration: const InputDecoration(
                                labelText: 'Calendar *',
                                border: OutlineInputBorder(),
                              ),
                              child: const Text(
                                'No writable calendar selected',
                              ),
                            )
                          : InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Calendar *',
                                border: OutlineInputBorder(),
                              ),
                              child: _CategoryPicker(
                                categories: widget.categories,
                                selectedCategoryId: _selectedCategoryId,
                                onSelected: _selectCategory,
                              ),
                            ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('event-location-field'),
                        controller: _locationController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PickerField(
                        key: const ValueKey('event-alert-field'),
                        label: 'Alert',
                        value: _alertOption.label,
                        onTap: () => _showAlertDialog(primary: true),
                      ),
                      const SizedBox(height: 12),
                      _PickerField(
                        key: const ValueKey('event-second-alert-field'),
                        label: 'Second alert',
                        value: _secondAlertOption.label,
                        onTap: () => _showAlertDialog(primary: false),
                      ),
                      const SizedBox(height: 12),
                      _PickerField(
                        key: const ValueKey('event-repeat-field'),
                        label: 'Repeat',
                        value: _repeatOption.label,
                        onTap: _showRepeatDialog,
                      ),
                      if (_repeatOption == _RepeatOption.custom) ...[
                        const SizedBox(height: 12),
                        _buildCustomRepeatFields(),
                      ],
                      if (_repeatOption != _RepeatOption.never) ...[
                        const SizedBox(height: 12),
                        SwitchListTile(
                          key: const ValueKey('event-end-repeat-switch'),
                          title: const Text('End repeat'),
                          value: _endRepeat,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (value) {
                            setState(() {
                              _endRepeat = value;
                            });
                          },
                        ),
                        if (_endRepeat)
                          _PickerField(
                            key: const ValueKey('event-repeat-end-date-field'),
                            label: 'End repeat date *',
                            value: _dateFieldLabel(
                              _repeatEndDate ?? _startDateTime,
                            ),
                            onTap: _pickRepeatEndDate,
                          ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('event-notes-field'),
                        controller: _notesController,
                        minLines: 4,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.item != null) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('copy-event-button'),
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pop(const _CopyEventSheetResult());
                          },
                          icon: const Icon(Icons.content_copy),
                          label: const Text('Copy'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('move-event-button'),
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pop(const _MoveEventSheetResult());
                          },
                          icon: const Icon(Icons.drive_file_move),
                          label: const Text('Move'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('delete-event-button'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: _confirmDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRepeatFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<_CustomFrequency>(
          key: const ValueKey('event-repeat-frequency-field'),
          initialValue: _customFrequency,
          decoration: const InputDecoration(
            labelText: 'Frequency *',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final frequency in _CustomFrequency.values)
              DropdownMenuItem(value: frequency, child: Text(frequency.label)),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _customFrequency = value;
              _ensureFrequencyDefaults();
            });
          },
        ),
        const SizedBox(height: 12),
        _EveryField(
          controller: _everyController,
          unitLabel: _customFrequency.pluralLabel,
        ),
        if (_customFrequency == _CustomFrequency.weekly) ...[
          const SizedBox(height: 12),
          _WeekdayCheckboxes(
            selectedWeekdays: _selectedWeekdays,
            onChanged: (selectedWeekdays) {
              setState(() {
                _selectedWeekdays = selectedWeekdays;
              });
            },
          ),
        ],
        if (_customFrequency == _CustomFrequency.monthly) ...[
          const SizedBox(height: 12),
          _MonthlyRepeatFields(
            mode: _monthlyMode,
            selectedDays: _selectedMonthDays,
            ordinal: _monthlyOrdinal,
            ordinalTarget: _monthlyOrdinalTarget,
            onModeChanged: (mode) {
              setState(() {
                _monthlyMode = mode;
              });
            },
            onSelectedDaysChanged: (days) {
              setState(() {
                _selectedMonthDays = days;
              });
            },
            onOrdinalChanged: (ordinal) {
              setState(() {
                _monthlyOrdinal = ordinal;
              });
            },
            onOrdinalTargetChanged: (target) {
              setState(() {
                _monthlyOrdinalTarget = target;
              });
            },
          ),
        ],
        if (_customFrequency == _CustomFrequency.yearly) ...[
          const SizedBox(height: 12),
          _YearlyRepeatFields(
            selectedMonths: _selectedMonths,
            usesDaysOfWeek: _yearlyUsesDaysOfWeek,
            ordinal: _yearlyOrdinal,
            ordinalTarget: _yearlyOrdinalTarget,
            onSelectedMonthsChanged: (months) {
              setState(() {
                _selectedMonths = months;
              });
            },
            onUsesDaysOfWeekChanged: (usesDaysOfWeek) {
              setState(() {
                _yearlyUsesDaysOfWeek = usesDaysOfWeek;
              });
            },
            onOrdinalChanged: (ordinal) {
              setState(() {
                _yearlyOrdinal = ordinal;
              });
            },
            onOrdinalTargetChanged: (target) {
              setState(() {
                _yearlyOrdinalTarget = target;
              });
            },
          ),
        ],
        const SizedBox(height: 12),
        Text(
          _repeatDescription,
          key: const ValueKey('event-repeat-description'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  bool get _isValid {
    if (_titleController.text.trim().isEmpty) {
      return false;
    }
    if (!_allDay && !_endDateTime.isAfter(_startDateTime)) {
      return false;
    }
    if (_selectedCategoryId == null) {
      return false;
    }
    if (_repeatOption != _RepeatOption.custom) {
      return true;
    }
    final every = int.tryParse(_everyController.text);
    if (every == null || every < 1 || every > 999) {
      return false;
    }
    if (_customFrequency == _CustomFrequency.weekly &&
        _selectedWeekdays.isEmpty) {
      return false;
    }
    if (_customFrequency == _CustomFrequency.monthly &&
        _monthlyMode == _MonthlyMode.each &&
        _selectedMonthDays.isEmpty) {
      return false;
    }
    if (_customFrequency == _CustomFrequency.yearly &&
        _selectedMonths.isEmpty) {
      return false;
    }
    return true;
  }

  String get _repeatDescription {
    final every = int.tryParse(_everyController.text) ?? 1;
    final unit = every == 1
        ? _customFrequency.singularLabel
        : _customFrequency.pluralLabel;

    return switch (_customFrequency) {
      _CustomFrequency.daily => 'Event will occur every $every $unit.',
      _CustomFrequency.weekly =>
        'Event will occur every $every $unit on ${_joinedWeekdays(_selectedWeekdays)}.',
      _CustomFrequency.monthly when _monthlyMode == _MonthlyMode.each =>
        'Event will occur every $every $unit on day ${_joinedNumbers(_selectedMonthDays)}.',
      _CustomFrequency.monthly =>
        'Event will occur every $every $unit on the ${_monthlyOrdinal.label} ${_monthlyOrdinalTarget.label}.',
      _CustomFrequency.yearly when _yearlyUsesDaysOfWeek =>
        'Event will occur every $every $unit on the ${_yearlyOrdinal.label} ${_yearlyOrdinalTarget.label} of ${_joinedMonths(_selectedMonths)}.',
      _CustomFrequency.yearly =>
        'Event will occur every $every $unit in ${_joinedMonths(_selectedMonths)}.',
    };
  }

  void _applyRrule(String? rrule) {
    if (rrule == null || rrule.trim().isEmpty) {
      _repeatOption = _RepeatOption.never;
      return;
    }

    final parts = {
      for (final part in rrule.split(';'))
        if (part.contains('='))
          part.split('=').first.toUpperCase(): part
              .split('=')
              .skip(1)
              .join('='),
    };
    final frequency = parts['FREQ']?.toUpperCase();
    final interval = int.tryParse(parts['INTERVAL'] ?? '') ?? 1;
    _everyController.text = interval.clamp(1, 999).toString();
    _endRepeat = parts.containsKey('UNTIL');

    if (frequency == 'DAILY' && interval == 1) {
      _repeatOption = _RepeatOption.everyDay;
      return;
    }
    if (frequency == 'WEEKLY' && interval == 1 && !parts.containsKey('BYDAY')) {
      _repeatOption = _RepeatOption.everyWeek;
      return;
    }
    if (frequency == 'WEEKLY' && interval == 2 && !parts.containsKey('BYDAY')) {
      _repeatOption = _RepeatOption.everyTwoWeeks;
      return;
    }
    if (frequency == 'MONTHLY' && interval == 1 && parts.length <= 2) {
      _repeatOption = _RepeatOption.everyMonth;
      return;
    }
    if (frequency == 'MONTHLY' && interval == 2 && parts.length <= 2) {
      _repeatOption = _RepeatOption.everyTwoMonths;
      return;
    }
    if (frequency == 'MONTHLY' && interval == 3 && parts.length <= 2) {
      _repeatOption = _RepeatOption.everyThreeMonths;
      return;
    }
    if (frequency == 'YEARLY' && interval == 1 && parts.length <= 2) {
      _repeatOption = _RepeatOption.everyYear;
      return;
    }

    _repeatOption = _RepeatOption.custom;
    _customFrequency = switch (frequency) {
      'WEEKLY' => _CustomFrequency.weekly,
      'MONTHLY' => _CustomFrequency.monthly,
      'YEARLY' => _CustomFrequency.yearly,
      _ => _CustomFrequency.daily,
    };

    final byDay = parts['BYDAY'];
    if (_customFrequency == _CustomFrequency.weekly && byDay != null) {
      _selectedWeekdays = {
        for (final value in byDay.split(',')) ?_weekdayFromRrule(value),
      };
    }

    final byMonthDay = parts['BYMONTHDAY'];
    if (_customFrequency == _CustomFrequency.monthly &&
        byMonthDay != null &&
        !byMonthDay.startsWith('-')) {
      _monthlyMode = _MonthlyMode.each;
      _selectedMonthDays = {
        for (final value in byMonthDay.split(',')) ?_boundedInt(value, 1, 31),
      };
    }

    final byMonth = parts['BYMONTH'];
    if (_customFrequency == _CustomFrequency.yearly && byMonth != null) {
      _selectedMonths = {
        for (final value in byMonth.split(',')) ?_boundedInt(value, 1, 12),
      };
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDateTime : _endDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      if (isStart) {
        final previousStart = _startDateTime;
        _startDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _startDateTime.hour,
          _startDateTime.minute,
        );
        _endDateTime = _startDateTime.add(
          _endDateTime.difference(previousStart),
        );
      } else {
        _endDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _endDateTime.hour,
          _endDateTime.minute,
        );
      }
      _normalizeEndDateTime();
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    if (_allDay) {
      return;
    }

    final source = isStart ? _startDateTime : _endDateTime;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(source),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      if (isStart) {
        final previousStart = _startDateTime;
        _startDateTime = DateTime(
          _startDateTime.year,
          _startDateTime.month,
          _startDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        _endDateTime = _startDateTime.add(
          _endDateTime.difference(previousStart),
        );
      } else {
        _endDateTime = DateTime(
          _endDateTime.year,
          _endDateTime.month,
          _endDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
      _normalizeEndDateTime();
    });
  }

  Future<void> _pickRepeatEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _repeatEndDate ?? _startDateTime.add(const Duration(days: 1)),
      firstDate: _startDateTime.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _repeatEndDate = pickedDate;
    });
  }

  Future<void> _showAlertDialog({required bool primary}) async {
    var selectedOption = primary ? _alertOption : _secondAlertOption;
    final option = await showDialog<_AlertOption>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(primary ? 'Alert' : 'Second alert'),
              content: SizedBox(
                width: 360,
                child: RadioGroup<_AlertOption>(
                  groupValue: selectedOption,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setDialogState(() {
                      selectedOption = value;
                    });
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final alertOption in _AlertOption.values)
                          RadioListTile<_AlertOption>(
                            key: ValueKey(
                              '${primary ? 'alert' : 'second-alert'}-${alertOption.name}',
                            ),
                            title: Text(alertOption.label),
                            value: alertOption,
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
                  key: ValueKey(
                    primary ? 'alert-done-button' : 'second-alert-done-button',
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(selectedOption);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (option == null) {
      return;
    }

    setState(() {
      if (primary) {
        _alertOption = option;
      } else {
        _secondAlertOption = option;
      }
    });
  }

  Future<void> _showRepeatDialog() async {
    var selectedRepeatOption = _repeatOption;
    final repeatOption = await showDialog<_RepeatOption>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Repeat'),
              content: SizedBox(
                width: 360,
                child: RadioGroup<_RepeatOption>(
                  groupValue: selectedRepeatOption,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setDialogState(() {
                      selectedRepeatOption = value;
                    });
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final option in _RepeatOption.values)
                          RadioListTile<_RepeatOption>(
                            key: ValueKey('repeat-${option.name}'),
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
                  key: const ValueKey('repeat-done-button'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedRepeatOption);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );

    if (repeatOption == null) {
      return;
    }

    setState(() {
      _repeatOption = repeatOption;
      if (repeatOption == _RepeatOption.custom) {
        _ensureFrequencyDefaults();
      }
    });
  }

  void _selectCategory(_AvailableCalendar category, Rect anchorRect) {
    setState(() {
      _selectedCategoryId = category.id;
    });
    _showCategoryTooltip(category.name, anchorRect);
  }

  void _showCategoryTooltip(String label, Rect anchorRect) {
    _categoryTooltipTimer?.cancel();
    _categoryTooltipEntry?.remove();

    _categoryTooltipEntry = OverlayEntry(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Positioned(
          left: anchorRect.left + anchorRect.width / 2 - 72,
          top: anchorRect.top - 42,
          width: 144,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.inverseSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onInverseSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_categoryTooltipEntry!);
    _categoryTooltipTimer = Timer(const Duration(seconds: 2), () {
      _categoryTooltipEntry?.remove();
      _categoryTooltipEntry = null;
    });
  }

  void _saveDraft() {
    Navigator.of(context).pop(
      _SaveEventSheetResult(
        _DraftCalendarEvent(
          eventId: widget.item?.id,
          title: _titleController.text.trim(),
          startDateTime: _startDateTime,
          endDateTime: _endDateTime,
          allDay: _allDay,
          categoryId: _selectedCategoryId,
          location: _locationController.text.trim(),
          alertOption: _alertOption,
          secondAlertOption: _secondAlertOption,
          repeatOption: _repeatOption,
          customFrequency: _customFrequency,
          every: int.tryParse(_everyController.text) ?? 1,
          selectedWeekdays: Set<int>.of(_selectedWeekdays),
          monthlyMode: _monthlyMode,
          selectedMonthDays: Set<int>.of(_selectedMonthDays),
          monthlyOrdinal: _monthlyOrdinal,
          monthlyOrdinalTarget: _monthlyOrdinalTarget,
          selectedMonths: Set<int>.of(_selectedMonths),
          yearlyUsesDaysOfWeek: _yearlyUsesDaysOfWeek,
          yearlyOrdinal: _yearlyOrdinal,
          yearlyOrdinalTarget: _yearlyOrdinalTarget,
          endRepeat: _endRepeat,
          repeatEndDate: _endRepeat ? _repeatEndDate : null,
          notes: _notesController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final item = widget.item;
    if (item == null) {
      return;
    }

    final isRepeating = item.rrule?.trim().isNotEmpty ?? false;
    final scope = await showDialog<_DeleteEventScope>(
      context: context,
      builder: (context) {
        if (isRepeating) {
          return AlertDialog(
            title: const Text('This event is a repeating event.'),
            actions: [
              TextButton(
                key: const ValueKey('delete-this-event-only-button'),
                onPressed: () {
                  Navigator.of(context).pop(_DeleteEventScope.thisOnly);
                },
                child: const Text('Delete this event only'),
              ),
              TextButton(
                key: const ValueKey('delete-future-events-button'),
                onPressed: () {
                  Navigator.of(context).pop(_DeleteEventScope.future);
                },
                child: const Text('Delete all future events'),
              ),
              TextButton(
                key: const ValueKey('cancel-delete-event-button'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: const Text('Are you sure you want to delete this event?'),
          actions: [
            TextButton(
              key: const ValueKey('cancel-delete-event-button'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              key: const ValueKey('confirm-delete-event-button'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(context).pop(_DeleteEventScope.all);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (scope == null || !mounted) {
      return;
    }

    Navigator.of(context).pop(_DeleteEventSheetResult(scope));
  }

  void _normalizeEndDateTime() {
    if (!_endDateTime.isAfter(_startDateTime)) {
      _endDateTime = _startDateTime.add(const Duration(hours: 1));
    }
  }

  void _ensureFrequencyDefaults() {
    if (_customFrequency == _CustomFrequency.weekly &&
        _selectedWeekdays.isEmpty) {
      _selectedWeekdays = {_startDateTime.weekday};
    }
    if (_customFrequency == _CustomFrequency.monthly &&
        _selectedMonthDays.isEmpty) {
      _selectedMonthDays = {_startDateTime.day};
    }
    if (_customFrequency == _CustomFrequency.yearly &&
        _selectedMonths.isEmpty) {
      _selectedMonths = {_startDateTime.month};
    }
  }

  void _handleValidationChanged() {
    setState(() {});
  }

  DateTime _roundedFutureFiveMinute(DateTime dateTime) {
    final totalMinutes = dateTime.hour * 60 + dateTime.minute;
    final roundedMinutes = ((totalMinutes ~/ 5) + 1) * 5;
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    ).add(Duration(minutes: roundedMinutes));
  }
}

class _DateTimeGrid extends StatelessWidget {
  const _DateTimeGrid({
    required this.startDateTime,
    required this.endDateTime,
    required this.allDay,
    required this.onPickStartDate,
    required this.onPickStartTime,
    required this.onPickEndDate,
    required this.onPickEndTime,
  });

  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool allDay;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndDate;
  final VoidCallback onPickEndTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PickerField(
                key: const ValueKey('event-start-date-field'),
                label: 'Start date *',
                value: _dateFieldLabel(startDateTime),
                onTap: onPickStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickerField(
                key: const ValueKey('event-start-time-field'),
                label: 'Start time *',
                value: _formatTime(TimeOfDay.fromDateTime(startDateTime)),
                enabled: !allDay,
                onTap: onPickStartTime,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PickerField(
                key: const ValueKey('event-end-date-field'),
                label: 'End date *',
                value: _dateFieldLabel(endDateTime),
                onTap: onPickEndDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickerField(
                key: const ValueKey('event-end-time-field'),
                label: 'End time *',
                value: _formatTime(TimeOfDay.fromDateTime(endDateTime)),
                enabled: !allDay,
                onTap: onPickEndTime,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      enabled: enabled,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onTap: enabled ? onTap : null,
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<_AvailableCalendar> categories;
  final String? selectedCategoryId;
  final void Function(_AvailableCalendar category, Rect anchorRect) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final category in categories)
          Builder(
            builder: (context) {
              final selected = category.id == selectedCategoryId;

              return InkResponse(
                key: ValueKey('event-category-${category.id}'),
                radius: 22,
                onTap: () {
                  final box = context.findRenderObject() as RenderBox;
                  final topLeft = box.localToGlobal(Offset.zero);
                  onSelected(category, topLeft & box.size);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _EveryField extends StatelessWidget {
  const _EveryField({required this.controller, required this.unitLabel});

  final TextEditingController controller;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: const ValueKey('event-repeat-every-number-field'),
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Every *',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InputDecorator(
            key: const ValueKey('event-repeat-every-unit-field'),
            decoration: const InputDecoration(
              labelText: 'Frequency',
              border: OutlineInputBorder(),
            ),
            child: Text(unitLabel),
          ),
        ),
      ],
    );
  }
}

class _WeekdayCheckboxes extends StatelessWidget {
  const _WeekdayCheckboxes({
    required this.selectedWeekdays,
    required this.onChanged,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final weekday in _orderedWeekdaysFor(_WeekStartDay.monday))
          FilterChip(
            key: ValueKey('event-repeat-weekday-$weekday'),
            label: Text(_fullDayName(DateTime(2024, 1, weekday))),
            selected: selectedWeekdays.contains(weekday),
            onSelected: (selected) {
              final next = Set<int>.of(selectedWeekdays);
              if (selected) {
                next.add(weekday);
              } else {
                next.remove(weekday);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _MonthlyRepeatFields extends StatelessWidget {
  const _MonthlyRepeatFields({
    required this.mode,
    required this.selectedDays,
    required this.ordinal,
    required this.ordinalTarget,
    required this.onModeChanged,
    required this.onSelectedDaysChanged,
    required this.onOrdinalChanged,
    required this.onOrdinalTargetChanged,
  });

  final _MonthlyMode mode;
  final Set<int> selectedDays;
  final _Ordinal ordinal;
  final _OrdinalTarget ordinalTarget;
  final ValueChanged<_MonthlyMode> onModeChanged;
  final ValueChanged<Set<int>> onSelectedDaysChanged;
  final ValueChanged<_Ordinal> onOrdinalChanged;
  final ValueChanged<_OrdinalTarget> onOrdinalTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_MonthlyMode>(
          segments: const [
            ButtonSegment(value: _MonthlyMode.each, label: Text('Each')),
            ButtonSegment(value: _MonthlyMode.onThe, label: Text('On the...')),
          ],
          selected: {mode},
          onSelectionChanged: (selection) {
            onModeChanged(selection.first);
          },
        ),
        const SizedBox(height: 12),
        if (mode == _MonthlyMode.each)
          _MonthDayGrid(
            selectedDays: selectedDays,
            onChanged: onSelectedDaysChanged,
          )
        else
          _OrdinalFields(
            ordinal: ordinal,
            ordinalTarget: ordinalTarget,
            onOrdinalChanged: onOrdinalChanged,
            onOrdinalTargetChanged: onOrdinalTargetChanged,
          ),
      ],
    );
  }
}

class _MonthDayGrid extends StatelessWidget {
  const _MonthDayGrid({required this.selectedDays, required this.onChanged});

  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      key: const ValueKey('event-repeat-month-days-grid'),
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (var day = 1; day <= 35; day++)
          if (day <= 31)
            FilterChip(
              label: Text('$day'),
              selected: selectedDays.contains(day),
              onSelected: (selected) {
                final next = Set<int>.of(selectedDays);
                if (selected) {
                  next.add(day);
                } else {
                  next.remove(day);
                }
                onChanged(next);
              },
            )
          else
            const SizedBox.shrink(),
      ],
    );
  }
}

class _OrdinalFields extends StatelessWidget {
  const _OrdinalFields({
    required this.ordinal,
    required this.ordinalTarget,
    required this.onOrdinalChanged,
    required this.onOrdinalTargetChanged,
  });

  final _Ordinal ordinal;
  final _OrdinalTarget ordinalTarget;
  final ValueChanged<_Ordinal> onOrdinalChanged;
  final ValueChanged<_OrdinalTarget> onOrdinalTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<_Ordinal>(
            initialValue: ordinal,
            decoration: const InputDecoration(
              labelText: 'On the...',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final value in _Ordinal.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) {
              if (value != null) {
                onOrdinalChanged(value);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<_OrdinalTarget>(
            initialValue: ordinalTarget,
            decoration: const InputDecoration(
              labelText: 'Day',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final value in _OrdinalTarget.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: (value) {
              if (value != null) {
                onOrdinalTargetChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _YearlyRepeatFields extends StatelessWidget {
  const _YearlyRepeatFields({
    required this.selectedMonths,
    required this.usesDaysOfWeek,
    required this.ordinal,
    required this.ordinalTarget,
    required this.onSelectedMonthsChanged,
    required this.onUsesDaysOfWeekChanged,
    required this.onOrdinalChanged,
    required this.onOrdinalTargetChanged,
  });

  final Set<int> selectedMonths;
  final bool usesDaysOfWeek;
  final _Ordinal ordinal;
  final _OrdinalTarget ordinalTarget;
  final ValueChanged<Set<int>> onSelectedMonthsChanged;
  final ValueChanged<bool> onUsesDaysOfWeekChanged;
  final ValueChanged<_Ordinal> onOrdinalChanged;
  final ValueChanged<_OrdinalTarget> onOrdinalTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          key: const ValueKey('event-repeat-months-grid'),
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var month = 1; month <= 12; month++)
              FilterChip(
                label: Text(_shortMonthName(DateTime(2024, month))),
                selected: selectedMonths.contains(month),
                onSelected: (selected) {
                  final next = Set<int>.of(selectedMonths);
                  if (selected) {
                    next.add(month);
                  } else {
                    next.remove(month);
                  }
                  onSelectedMonthsChanged(next);
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          key: const ValueKey('event-repeat-days-of-week-switch'),
          title: const Text('Days of week'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.trailing,
          value: usesDaysOfWeek,
          onChanged: onUsesDaysOfWeekChanged,
        ),
        if (usesDaysOfWeek)
          _OrdinalFields(
            ordinal: ordinal,
            ordinalTarget: ordinalTarget,
            onOrdinalChanged: onOrdinalChanged,
            onOrdinalTargetChanged: onOrdinalTargetChanged,
          ),
      ],
    );
  }
}

class _DraftCalendarEvent {
  const _DraftCalendarEvent({
    this.eventId,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.allDay,
    required this.categoryId,
    required this.location,
    required this.alertOption,
    required this.secondAlertOption,
    required this.repeatOption,
    required this.customFrequency,
    required this.every,
    required this.selectedWeekdays,
    required this.monthlyMode,
    required this.selectedMonthDays,
    required this.monthlyOrdinal,
    required this.monthlyOrdinalTarget,
    required this.selectedMonths,
    required this.yearlyUsesDaysOfWeek,
    required this.yearlyOrdinal,
    required this.yearlyOrdinalTarget,
    required this.endRepeat,
    required this.repeatEndDate,
    required this.notes,
    this.rawRrule,
  });

  final String? eventId;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool allDay;
  final String? categoryId;
  final String location;
  final _AlertOption alertOption;
  final _AlertOption secondAlertOption;
  final _RepeatOption repeatOption;
  final _CustomFrequency customFrequency;
  final int every;
  final Set<int> selectedWeekdays;
  final _MonthlyMode monthlyMode;
  final Set<int> selectedMonthDays;
  final _Ordinal monthlyOrdinal;
  final _OrdinalTarget monthlyOrdinalTarget;
  final Set<int> selectedMonths;
  final bool yearlyUsesDaysOfWeek;
  final _Ordinal yearlyOrdinal;
  final _OrdinalTarget yearlyOrdinalTarget;
  final bool endRepeat;
  final DateTime? repeatEndDate;
  final String notes;
  final String? rawRrule;

  Map<String, Object?> toPlatformArguments() {
    return {
      'calendarId': categoryId,
      'eventId': eventId,
      'title': title,
      'startMillis': startDateTime.millisecondsSinceEpoch,
      'endMillis': endDateTime.millisecondsSinceEpoch,
      'allDay': allDay,
      'location': location,
      'notes': notes,
      'alertMinutes': alertOption.minutes,
      'secondAlertMinutes': secondAlertOption.minutes,
      'rrule': rawRrule ?? _rrule,
    };
  }

  String? get _rrule {
    final baseRule = switch (repeatOption) {
      _RepeatOption.never => null,
      _RepeatOption.everyDay => 'FREQ=DAILY',
      _RepeatOption.everyWeek => 'FREQ=WEEKLY',
      _RepeatOption.everyTwoWeeks => 'FREQ=WEEKLY;INTERVAL=2',
      _RepeatOption.everyMonth => 'FREQ=MONTHLY',
      _RepeatOption.everyTwoMonths => 'FREQ=MONTHLY;INTERVAL=2',
      _RepeatOption.everyThreeMonths => 'FREQ=MONTHLY;INTERVAL=3',
      _RepeatOption.everyYear => 'FREQ=YEARLY',
      _RepeatOption.custom => _customRrule,
    };

    if (baseRule == null) {
      return null;
    }

    final until = repeatEndDate == null
        ? null
        : 'UNTIL=${_rruleUntilDate(repeatEndDate!)}';
    return [baseRule, ?until].join(';');
  }

  String get _customRrule {
    final clampedEvery = every.clamp(1, 999);
    return switch (customFrequency) {
      _CustomFrequency.daily => 'FREQ=DAILY;INTERVAL=$clampedEvery',
      _CustomFrequency.weekly =>
        'FREQ=WEEKLY;INTERVAL=$clampedEvery;BYDAY=${_rruleWeekdays(selectedWeekdays)}',
      _CustomFrequency.monthly when monthlyMode == _MonthlyMode.each =>
        'FREQ=MONTHLY;INTERVAL=$clampedEvery;BYMONTHDAY=${_joinedNumbers(selectedMonthDays)}',
      _CustomFrequency.monthly =>
        'FREQ=MONTHLY;INTERVAL=$clampedEvery;${_ordinalRrule(monthlyOrdinal, monthlyOrdinalTarget)}',
      _CustomFrequency.yearly when yearlyUsesDaysOfWeek =>
        'FREQ=YEARLY;INTERVAL=$clampedEvery;BYMONTH=${_joinedNumbers(selectedMonths)};${_ordinalRrule(yearlyOrdinal, yearlyOrdinalTarget)}',
      _CustomFrequency.yearly =>
        'FREQ=YEARLY;INTERVAL=$clampedEvery;BYMONTH=${_joinedNumbers(selectedMonths)}',
    };
  }
}

enum _RepeatOption {
  never('Never'),
  everyDay('Every day'),
  everyWeek('Every week'),
  everyTwoWeeks('Every 2 weeks'),
  everyMonth('Every month'),
  everyTwoMonths('Every 2 months'),
  everyThreeMonths('Every 3 months (season)'),
  everyYear('Every year'),
  custom('Custom');

  const _RepeatOption(this.label);

  final String label;
}

enum _CustomFrequency {
  daily('Daily', 'day', 'days'),
  weekly('Weekly', 'week', 'weeks'),
  monthly('Monthly', 'month', 'months'),
  yearly('Yearly', 'year', 'years');

  const _CustomFrequency(this.label, this.singularLabel, this.pluralLabel);

  final String label;
  final String singularLabel;
  final String pluralLabel;
}

enum _MonthlyMode { each, onThe }

enum _Ordinal {
  first('first'),
  second('second'),
  third('third'),
  fourth('fourth'),
  fifth('fifth'),
  last('last');

  const _Ordinal(this.label);

  final String label;
}

enum _OrdinalTarget {
  monday('Monday'),
  tuesday('Tuesday'),
  wednesday('Wednesday'),
  thursday('Thursday'),
  friday('Friday'),
  saturday('Saturday'),
  sunday('Sunday'),
  day('day'),
  weekday('weekday'),
  weekendDay('weekend day');

  const _OrdinalTarget(this.label);

  final String label;
}

extension on _AlertOption {
  int? get minutes {
    return switch (this) {
      _AlertOption.none => null,
      _AlertOption.atTimeOfEvent => 0,
      _AlertOption.fiveMinutesBefore => 5,
      _AlertOption.tenMinutesBefore => 10,
      _AlertOption.fifteenMinutesBefore => 15,
      _AlertOption.thirtyMinutesBefore => 30,
      _AlertOption.oneHourBefore => 60,
      _AlertOption.twoHoursBefore => 120,
      _AlertOption.fourHoursBefore => 240,
      _AlertOption.eightHoursBefore => 480,
      _AlertOption.twelveHoursBefore => 720,
      _AlertOption.oneDayBefore => 1440,
      _AlertOption.twoDaysBefore => 2880,
    };
  }
}

_AlertOption _alertOptionFromMinutes(int? minutes) {
  return _AlertOption.values.firstWhere(
    (option) => option.minutes == minutes,
    orElse: () => _AlertOption.none,
  );
}

int? _weekdayFromRrule(String value) {
  return switch (value.toUpperCase()) {
    'MO' => DateTime.monday,
    'TU' => DateTime.tuesday,
    'WE' => DateTime.wednesday,
    'TH' => DateTime.thursday,
    'FR' => DateTime.friday,
    'SA' => DateTime.saturday,
    'SU' => DateTime.sunday,
    _ => null,
  };
}

int? _boundedInt(String value, int min, int max) {
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < min || parsed > max) {
    return null;
  }
  return parsed;
}

String _dateFieldLabel(DateTime date) {
  return '${_shortMonthName(date)} ${date.day}, ${date.year}';
}

String _joinedNumbers(Set<int> numbers) {
  final sorted = numbers.toList()..sort();
  return sorted.isEmpty ? 'none' : sorted.join(', ');
}

String _rruleUntilDate(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day, 23, 59, 59);
  return '${utcDate.year.toString().padLeft(4, '0')}'
      '${utcDate.month.toString().padLeft(2, '0')}'
      '${utcDate.day.toString().padLeft(2, '0')}T'
      '${utcDate.hour.toString().padLeft(2, '0')}'
      '${utcDate.minute.toString().padLeft(2, '0')}'
      '${utcDate.second.toString().padLeft(2, '0')}Z';
}

String _rruleWeekdays(Set<int> weekdays) {
  final sorted = weekdays.toList()..sort();
  return sorted.map(_rruleWeekday).join(',');
}

String _rruleWeekday(int weekday) {
  return switch (weekday) {
    DateTime.monday => 'MO',
    DateTime.tuesday => 'TU',
    DateTime.wednesday => 'WE',
    DateTime.thursday => 'TH',
    DateTime.friday => 'FR',
    DateTime.saturday => 'SA',
    DateTime.sunday => 'SU',
    _ => 'MO',
  };
}

String _ordinalRrule(_Ordinal ordinal, _OrdinalTarget target) {
  final setPosition = switch (ordinal) {
    _Ordinal.first => 1,
    _Ordinal.second => 2,
    _Ordinal.third => 3,
    _Ordinal.fourth => 4,
    _Ordinal.fifth => 5,
    _Ordinal.last => -1,
  };

  if (target == _OrdinalTarget.day) {
    return ordinal == _Ordinal.last
        ? 'BYMONTHDAY=-1'
        : 'BYMONTHDAY=$setPosition';
  }

  final weekdays = switch (target) {
    _OrdinalTarget.monday => 'MO',
    _OrdinalTarget.tuesday => 'TU',
    _OrdinalTarget.wednesday => 'WE',
    _OrdinalTarget.thursday => 'TH',
    _OrdinalTarget.friday => 'FR',
    _OrdinalTarget.saturday => 'SA',
    _OrdinalTarget.sunday => 'SU',
    _OrdinalTarget.weekday => 'MO,TU,WE,TH,FR',
    _OrdinalTarget.weekendDay => 'SA,SU',
    _OrdinalTarget.day => 'MO,TU,WE,TH,FR,SA,SU',
  };

  return 'BYDAY=$weekdays;BYSETPOS=$setPosition';
}

String _joinedWeekdays(Set<int> weekdays) {
  final sorted = weekdays.toList()..sort();
  if (sorted.isEmpty) {
    return 'none';
  }
  return sorted
      .map((weekday) => _fullDayName(DateTime(2024, 1, weekday)))
      .join(', ');
}

String _joinedMonths(Set<int> months) {
  final sorted = months.toList()..sort();
  if (sorted.isEmpty) {
    return 'none';
  }
  return sorted
      .map((month) => _fullMonthName(DateTime(2024, month)))
      .join(' and ');
}
