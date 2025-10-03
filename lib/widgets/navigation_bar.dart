import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import 'week_picker_dialog.dart';

class CalendarNavigationBar extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const CalendarNavigationBar({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: TextButton(
              onPressed: provider.isViewingToday ? null : provider.goToToday,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Today',
                  style: TextStyle(
                    color: provider.isViewingToday
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          leadingWidth: 70,
          title: InkWell(
            onTap: () => _showWeekPicker(context, provider),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Week ${provider.currentWeekNumber}, ${provider.currentYear}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 24),
              ],
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.menu), onPressed: onSettingsTap),
          ],
        );
      },
    );
  }

  void _showWeekPicker(BuildContext context, CalendarProvider provider) {
    showDialog(
      context: context,
      builder: (context) => const WeekPickerDialog(),
    );
  }
}
