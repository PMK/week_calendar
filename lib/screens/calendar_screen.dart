import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/settings_provider.dart';
import '../models/calendar_event.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/settings_overlay.dart';
import '../widgets/event_detail_overlay.dart';
import '../widgets/search_bar_widget.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  bool _showSearch = false;
  bool _hasSearchInput = false;
  late AnimationController _searchAnimationController;
  late Animation<Offset> _searchSlideAnimation;
  late Animation<double> _backdropAnimation;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _searchAnimationController,
            curve: Curves.easeInOut,
          ),
        );
    _backdropAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (_showSearch) {
        _searchAnimationController.forward();
      } else {
        _searchAnimationController.reverse();
        _hasSearchInput = false;
        Provider.of<CalendarProvider>(context, listen: false).clearSearch();
      }
    });
  }

  void _onSearchChanged(bool hasInput) {
    setState(() {
      _hasSearchInput = hasInput;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDarkMode = settingsProvider.settings.isDarkMode;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: CalendarNavigationBar(
              onSettingsTap: () => _showSettings(context),
            ),
          ),
          body: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 0 && !_showSearch) {
                // Swipe down to show search
                _toggleSearch();
              } else if (details.delta.dy < 0 && _showSearch) {
                // Swipe up to hide search
                _toggleSearch();
              }
            },
            child: Consumer<CalendarProvider>(
              builder: (context, calendarProvider, child) {
                if (calendarProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    Column(
                      children: [
                        if (calendarProvider.mode != CalendarMode.normal)
                          _buildModeIndicator(context, calendarProvider),
                        Expanded(
                          child: CalendarGrid(
                            onEventTap: (event) =>
                                _showEventDetail(context, event),
                            onDateTap: (date) => _handleDateTap(context, date),
                            onCreateEvent: (date) => _showEventDetail(
                              context,
                              null,
                              initialDate: date,
                            ),
                          ),
                        ),
                        if (calendarProvider.mode == CalendarMode.copy)
                          _buildCopyModeBar(
                            context,
                            calendarProvider,
                            isDarkMode,
                          ),
                      ],
                    ),
                    // Backdrop overlay
                    if (_showSearch)
                      FadeTransition(
                        opacity: _backdropAnimation,
                        child: GestureDetector(
                          onTap: _toggleSearch,
                          child: Container(
                            color: Colors.black,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    // Search bar overlay
                    if (_showSearch)
                      SlideTransition(
                        position: _searchSlideAnimation,
                        child: SearchBarWidget(
                          onClose: _toggleSearch,
                          onSearchChanged: _onSearchChanged,
                        ),
                      ),
                    // No results message
                    if (_showSearch &&
                        _hasSearchInput &&
                        calendarProvider.searchResults.isEmpty)
                      Positioned(
                        top: 120,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey.shade800.withValues(
                                        alpha: 0.9,
                                      )
                                    : Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'No results found',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeIndicator(BuildContext context, CalendarProvider provider) {
    String message;
    Color color;

    switch (provider.mode) {
      case CalendarMode.copy:
        message = 'Tap a date to copy event';
        color = Colors.blue;
        break;
      case CalendarMode.move:
        message = 'Tap a date to move event';
        color = Colors.orange;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: color,
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => provider.clearSelection(),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyModeBar(
    BuildContext context,
    CalendarProvider provider,
    bool isDarkMode,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => provider.clearSelection(),
            icon: const Icon(Icons.close),
            label: const Text('Cancel Copy Mode'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _handleDateTap(BuildContext context, DateTime date) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);

    if (provider.mode == CalendarMode.copy && provider.selectedEvent != null) {
      provider.copyEventToDate(provider.selectedEvent!, date);
    } else if (provider.mode == CalendarMode.move &&
        provider.selectedEvent != null) {
      provider.moveEventToDate(provider.selectedEvent!, date);
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsOverlay(),
    );
  }

  void _showEventDetail(
    BuildContext context,
    CalendarEvent? event, {
    DateTime? initialDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          EventDetailOverlay(event: event, initialDate: initialDate),
    );
  }
}
