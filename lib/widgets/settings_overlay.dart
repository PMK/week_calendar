import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/theme_config.dart';
import '../utils/constants.dart';
import 'week_picker_dialog.dart';

class SettingsOverlay extends StatelessWidget {
  const SettingsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDarkMode = settingsProvider.settings.isDarkMode;
        final backgroundColor = isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white;

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context, isDarkMode),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildThemeSection(context, isDarkMode),
                        const Divider(height: 32),
                        _buildWeekStartSection(context, isDarkMode),
                        const Divider(height: 32),
                        _buildNavigationSection(context, isDarkMode),
                        const Divider(height: 32),
                        _buildAboutSection(context, isDarkMode),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, bool isDarkMode) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              value: settings.settings.isDarkMode,
              onChanged: (value) => settings.toggleDarkMode(),
            ),
            const SizedBox(height: 16),
            Text(
              'Color Theme',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ThemeConfig.presetThemes.map((theme) {
                final isSelected =
                    theme.name == settings.settings.themeConfig.name;
                return GestureDetector(
                  onTap: () => settings.updateTheme(theme),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? (isDarkMode ? Colors.white : Colors.black)
                                : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isDarkMode
                              ? Colors.grey.shade300
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWeekStartSection(BuildContext context, bool isDarkMode) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Week Starts On',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                AppConstants.dayNames[settings.settings.weekStartDay - 1],
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : null,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDarkMode ? Colors.grey.shade400 : null,
              ),
              onTap: () => _showWeekStartPicker(context, settings),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: Text(
            'Jump to Week',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          subtitle: Text(
            'Select a specific week to view',
            style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null),
          ),
          leading: Icon(
            Icons.calendar_today,
            color: isDarkMode ? Colors.grey.shade400 : null,
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDarkMode ? Colors.grey.shade400 : null,
          ),
          onTap: () {
            Navigator.pop(context); // Close settings
            _showWeekPicker(context);
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: Text(
            'Version',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          subtitle: Text(
            '1.0.0',
            style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null),
          ),
        ),
        ListTile(
          title: Text(
            'Issues/Support',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          subtitle: Text(
            'Report bugs or request features',
            style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null),
          ),
          trailing: Icon(
            Icons.open_in_new,
            color: isDarkMode ? Colors.grey.shade400 : null,
          ),
          onTap: () => _openGitHub(context, isDarkMode),
        ),
        ListTile(
          title: Text(
            'CalDAV Integration',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          subtitle: Text(
            'Configure DAVx5 app for calendar sync',
            style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null),
          ),
          trailing: Icon(
            Icons.open_in_new,
            color: isDarkMode ? Colors.grey.shade400 : null,
          ),
          onTap: () => _showCalDAVInfo(context, isDarkMode),
        ),
      ],
    );
  }

  void _showWeekStartPicker(BuildContext context, SettingsProvider settings) {
    final isDarkMode = settings.settings.isDarkMode;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            'Week Starts On',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (index) {
              final dayIndex = index + 1;
              return RadioListTile<int>(
                value: dayIndex,
                groupValue: settings.settings.weekStartDay,
                title: Text(
                  AppConstants.dayNames[index],
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onChanged: (value) {
                  settings.updateWeekStartDay(value!);
                  Navigator.pop(context);
                },
              );
            }),
          ),
        );
      },
    );
  }

  void _showWeekPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WeekPickerDialog(),
    );
  }

  void _openGitHub(BuildContext context, bool isDarkMode) {
    const url = 'https://github.com/yourusername/week-calendar/issues';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'GitHub Issues',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Open: $url\n\nAdd url_launcher package to open links.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade300 : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCalDAVInfo(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        title: Text(
          'CalDAV Setup',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'To sync with CalDAV servers:\n\n'
          '1. Install DAVx5 from Play Store\n'
          '2. Configure your CalDAV account in DAVx5\n'
          '3. Enable calendar sync\n'
          '4. This app will read from Android Calendar Provider\n\n'
          'Note: This demo uses local storage. Full CalDAV integration '
          'requires DAVx5 or similar service.',
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade300 : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
