import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/caldav_provider.dart';
import 'screens/calendar_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  await StorageService.instance.init();

  runApp(const WeekCalendarApp());
}

class WeekCalendarApp extends StatelessWidget {
  const WeekCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(create: (_) => CalDAVProvider()),
        ChangeNotifierProxyProvider<SettingsProvider, CalendarProvider>(
          create: (context) => CalendarProvider(
            Provider.of<SettingsProvider>(context, listen: false),
          )..loadEvents(),
          update: (context, settings, previous) =>
              previous ?? CalendarProvider(settings)
                ..loadEvents(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Week Calendar',
            debugShowCheckedModeBanner: false,
            theme: settings.currentTheme,
            home: const CalendarScreen(),
          );
        },
      ),
    );
  }
}
