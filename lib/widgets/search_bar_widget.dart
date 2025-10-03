import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/settings_provider.dart';

class SearchBarWidget extends StatefulWidget {
  final VoidCallback onClose;
  final Function(bool) onSearchChanged;

  const SearchBarWidget({
    super.key,
    required this.onClose,
    required this.onSearchChanged,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();

    // Auto-focus when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CalendarProvider, SettingsProvider>(
      builder: (context, calendarProvider, settingsProvider, child) {
        final isDarkMode = settingsProvider.settings.isDarkMode;
        final backgroundColor = isDarkMode
            ? const Color(0xFF2C2C2C)
            : Colors.white;

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            // Only respond to swipes if there are results
            if (!calendarProvider.hasSearchResults) return;

            // Swipe right - next result
            if (details.primaryVelocity! > 0) {
              calendarProvider.goToNextSearchResult();
            }
            // Swipe left - previous result
            else if (details.primaryVelocity! < 0) {
              calendarProvider.goToPreviousSearchResult();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Previous result button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: calendarProvider.canGoToPreviousResult
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : Colors.grey,
                    ),
                    onPressed: calendarProvider.canGoToPreviousResult
                        ? calendarProvider.goToPreviousSearchResult
                        : null,
                  ),
                  // Next result button
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward,
                      color: calendarProvider.canGoToNextResult
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : Colors.grey,
                    ),
                    onPressed: calendarProvider.canGoToNextResult
                        ? calendarProvider.goToNextSearchResult
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // Search input field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        hintStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  calendarProvider.clearSearch();
                                  widget.onSearchChanged(false);
                                  setState(
                                    () {},
                                  ); // Update to hide clear button
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        calendarProvider.search(value);
                        widget.onSearchChanged(value.isNotEmpty);
                        setState(() {}); // Update to show/hide clear button
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Cancel button
                  TextButton(
                    onPressed: widget.onClose,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
