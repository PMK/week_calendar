import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Week Calendar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const WeekCalendarPage(),
    );
  }
}

class WeekCalendarPage extends StatelessWidget {
  const WeekCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekStart = _startOfWeek(today);
    final days = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Week Calendar'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _DayColumn(days: days.take(3).toList())),
              Expanded(child: _DayColumn(days: days.skip(3).toList())),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final currentDate = DateTime(date.year, date.month, date.day);
    return currentDate.subtract(
      Duration(days: currentDate.weekday - DateTime.monday),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final day in days)
          Expanded(
            child: _DayCell(day: day),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isToday = _isSameDay(day, DateTime.now());

    return Container(
      key: ValueKey('day-cell-${day.weekday}'),
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? colorScheme.primaryContainer : colorScheme.surface,
        border: Border.all(
          color: isToday ? colorScheme.primary : colorScheme.outlineVariant,
          width: isToday ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _dayName(day),
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: isToday
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_monthName(day)} ${day.day}',
              style: textTheme.labelLarge?.copyWith(
                color: isToday
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _dayName(DateTime date) {
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

  String _monthName(DateTime date) {
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
}
