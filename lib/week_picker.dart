part of 'main.dart';

class _WeekPickerDialog extends StatefulWidget {
  const _WeekPickerDialog({
    required this.initialMonth,
    required this.selectedWeekStart,
    required this.today,
    required this.weekStartDay,
  });

  final DateTime initialMonth;
  final DateTime selectedWeekStart;
  final DateTime today;
  final _WeekStartDay weekStartDay;

  @override
  State<_WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<_WeekPickerDialog> {
  static const _initialPage = 12000;

  late final PageController _monthPageController;
  late final DateTime _baseMonth;
  late DateTime _visibleMonth;
  late DateTime _selectedWeekStart;

  @override
  void initState() {
    super.initState();
    _baseMonth = DateTime(widget.initialMonth.year, widget.initialMonth.month);
    _visibleMonth = _baseMonth;
    _selectedWeekStart = _startOfWeekFor(
      widget.selectedWeekStart,
      widget.weekStartDay,
    );
    _monthPageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select week'),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: 360,
        height: 370,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('week-picker-previous-month'),
                  tooltip: 'Previous month',
                  onPressed: () {
                    _monthPageController.previousPage(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${_fullMonthName(_visibleMonth)} ${_visibleMonth.year}',
                    key: const ValueKey('week-picker-month-title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('week-picker-next-month'),
                  tooltip: 'Next month',
                  onPressed: () {
                    _monthPageController.nextPage(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _WeekdayHeader(weekStartDay: widget.weekStartDay),
            const SizedBox(height: 8),
            Expanded(
              child: PageView.builder(
                key: const ValueKey('week-picker-month-page-view'),
                controller: _monthPageController,
                scrollDirection: Axis.vertical,
                onPageChanged: (page) {
                  setState(() {
                    _visibleMonth = _addMonths(_baseMonth, page - _initialPage);
                  });
                },
                itemBuilder: (context, page) {
                  return _MonthWeekPickerView(
                    month: _addMonths(_baseMonth, page - _initialPage),
                    today: widget.today,
                    selectedWeekStart: _selectedWeekStart,
                    weekStartDay: widget.weekStartDay,
                    onWeekSelected: (weekStart) {
                      setState(() {
                        _selectedWeekStart = weekStart;
                      });
                    },
                  );
                },
              ),
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
        FilledButton(
          key: const ValueKey('week-picker-select-button'),
          onPressed: () {
            Navigator.of(context).pop(_selectedWeekStart);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }

  DateTime _addMonths(DateTime month, int offset) {
    return DateTime(month.year, month.month + offset);
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.weekStartDay});

  final _WeekStartDay weekStartDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        const SizedBox(width: 42),
        _WeekPickerVerticalDivider(color: colorScheme.outlineVariant),
        for (final weekday in _orderedWeekdaysFor(weekStartDay))
          Expanded(
            child: Text(
              _weekdayShortName(weekday),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekPickerVerticalDivider extends StatelessWidget {
  const _WeekPickerVerticalDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('week-picker-week-number-divider'),
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: color,
    );
  }
}

class _MonthWeekPickerView extends StatelessWidget {
  const _MonthWeekPickerView({
    required this.month,
    required this.today,
    required this.selectedWeekStart,
    required this.weekStartDay,
    required this.onWeekSelected,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selectedWeekStart;
  final _WeekStartDay weekStartDay;
  final ValueChanged<DateTime> onWeekSelected;

  @override
  Widget build(BuildContext context) {
    final firstMonthDay = DateTime(month.year, month.month);
    final firstVisibleDay = _startOfWeekFor(firstMonthDay, weekStartDay);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (var weekIndex = 0; weekIndex < 6; weekIndex++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _WeekPickerRow(
                weekStart: firstVisibleDay.add(Duration(days: weekIndex * 7)),
                visibleMonth: month,
                today: today,
                selected: _isSameDay(
                  selectedWeekStart,
                  firstVisibleDay.add(Duration(days: weekIndex * 7)),
                ),
                colorScheme: colorScheme,
                onTap: onWeekSelected,
              ),
            ),
          ),
      ],
    );
  }
}

class _WeekPickerRow extends StatelessWidget {
  const _WeekPickerRow({
    required this.weekStart,
    required this.visibleMonth,
    required this.today,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final DateTime weekStart;
  final DateTime visibleMonth;
  final DateTime today;
  final bool selected;
  final ColorScheme colorScheme;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('week-picker-week-${_dateKey(weekStart)}'),
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        onTap(weekStart);
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                '${_isoWeekNumberFor(weekStart)}',
                key: ValueKey('week-picker-week-number-${_dateKey(weekStart)}'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _WeekPickerVerticalDivider(color: colorScheme.outlineVariant),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: selected
                      ? Border.all(color: colorScheme.primary, width: 2)
                      : Border.all(color: Colors.transparent, width: 2),
                ),
                child: Row(
                  children: [
                    for (var dayOffset = 0; dayOffset < 7; dayOffset++)
                      Expanded(
                        child: _WeekPickerDay(
                          day: weekStart.add(Duration(days: dayOffset)),
                          visibleMonth: visibleMonth,
                          today: today,
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
}

class _WeekPickerDay extends StatelessWidget {
  const _WeekPickerDay({
    required this.day,
    required this.visibleMonth,
    required this.today,
  });

  final DateTime day;
  final DateTime visibleMonth;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isToday = _isSameDay(day, today);
    final isInVisibleMonth =
        day.year == visibleMonth.year && day.month == visibleMonth.month;

    return Center(
      child: Container(
        key: ValueKey('week-picker-day-${_dateKey(day)}'),
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isToday ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${day.day}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isToday
                ? colorScheme.onPrimaryContainer
                : isInVisibleMonth
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
