import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/color_utils.dart';
import '../utils/constants.dart';

class EventDetailOverlay extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime? initialDate;

  const EventDetailOverlay({super.key, this.event, this.initialDate});

  @override
  State<EventDetailOverlay> createState() => _EventDetailOverlayState();
}

class _EventDetailOverlayState extends State<EventDetailOverlay> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late DateTime? _selectedEndDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isAllDay = false;
  Color _selectedColor = Colors.blue;
  List<String> _selectedCategories = [];
  List<EventAlert> _alerts = [];
  String _repeatRule = 'Never';
  List<String> _invitees = [];

  @override
  void initState() {
    super.initState();

    if (widget.event != null) {
      _titleController = TextEditingController(text: widget.event!.title);
      _locationController = TextEditingController(
        text: widget.event!.location ?? '',
      );
      _notesController = TextEditingController(text: widget.event!.notes ?? '');
      _selectedDate = widget.event!.date;
      _selectedEndDate = widget.event!.endDate;
      _startTime = widget.event!.startTime;
      _endTime = widget.event!.endTime;
      _isAllDay = widget.event!.isAllDay;
      _selectedColor = widget.event!.color;
      _selectedCategories = List.from(widget.event!.categories);
      _alerts = List.from(widget.event!.alerts);
      _repeatRule = widget.event!.repeatRule ?? 'Never';
      _invitees = List.from(widget.event!.invitees);
    } else {
      _titleController = TextEditingController();
      _locationController = TextEditingController();
      _notesController = TextEditingController();
      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedEndDate = null;
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(
        hour: TimeOfDay.now().hour + 1,
        minute: TimeOfDay.now().minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final isDarkMode = settingsProvider.settings.isDarkMode;
        final backgroundColor = isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white;
        // final surfaceColor = isDarkMode
        //     ? const Color(0xFF2C2C2C)
        //     : Colors.grey.shade100;

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
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
                  _buildTopBar(context, isDarkMode),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildTextField(
                          'Title',
                          _titleController,
                          required: true,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _buildAllDayCheckbox(isDarkMode),
                        const SizedBox(height: 16),
                        _buildDateTimePickers(isDarkMode),
                        const SizedBox(height: 16),
                        _buildColorPicker(isDarkMode),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Location',
                          _locationController,
                          icon: Icons.location_on,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        _buildAlertSelector(isDarkMode),
                        const SizedBox(height: 16),
                        _buildRepeatSelector(isDarkMode),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Notes',
                          _notesController,
                          maxLines: 4,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 24),
                        if (widget.event != null)
                          _buildActionButtons(context, isDarkMode),
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

  Widget _buildTopBar(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : null),
            ),
          ),
          Text(
            widget.event != null ? 'Edit Event' : 'New Event',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          TextButton(
            onPressed: _saveEvent,
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    IconData? icon,
    bool isDarkMode = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        labelStyle: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null),
        prefixIcon: icon != null
            ? Icon(icon, color: isDarkMode ? Colors.grey.shade400 : null)
            : null,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildAllDayCheckbox(bool isDarkMode) {
    return CheckboxListTile(
      value: _isAllDay,
      onChanged: (value) {
        setState(() {
          _isAllDay = value ?? false;
          if (_isAllDay) {
            _startTime = null;
            _endTime = null;
          } else {
            _startTime = TimeOfDay.now();
            _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);
          }
        });
      },
      title: Text(
        'All Day',
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDateTimePickers(bool isDarkMode) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text(
                  'Start Date',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : null,
                  ),
                ),
                onTap: () => _selectDate(context, true),
              ),
            ),
            if (!_isAllDay)
              Expanded(
                child: ListTile(
                  title: Text(
                    'Start Time',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    _startTime != null ? _formatTime(_startTime!) : '--:--',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : null,
                    ),
                  ),
                  onTap: () => _selectTime(context, true),
                ),
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text(
                  'End Date',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                subtitle: Text(
                  _selectedEndDate != null
                      ? '${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}'
                      : 'Same day',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : null,
                  ),
                ),
                onTap: () => _selectDate(context, false),
              ),
            ),
            if (!_isAllDay)
              Expanded(
                child: ListTile(
                  title: Text(
                    'End Time',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    _endTime != null ? _formatTime(_endTime!) : '--:--',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : null,
                    ),
                  ),
                  onTap: () => _selectTime(context, false),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Color',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ColorUtils.categoryColors.map((color) {
            final isSelected = color.toARGB32() == _selectedColor.toARGB32();
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? (isDarkMode ? Colors.white : Colors.black)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAlertSelector(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        ..._alerts.asMap().entries.map((entry) {
          return ListTile(
            title: Text(
              entry.value.toString(),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                color: isDarkMode ? Colors.grey.shade400 : null,
              ),
              onPressed: () {
                setState(() {
                  _alerts.removeAt(entry.key);
                });
              },
            ),
          );
        }),
        if (_alerts.length < 2)
          TextButton.icon(
            onPressed: _addAlert,
            icon: const Icon(Icons.add),
            label: const Text('Add Alert'),
          ),
      ],
    );
  }

  Widget _buildRepeatSelector(bool isDarkMode) {
    return ListTile(
      title: Text(
        'Repeat',
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      subtitle: Text(
        _repeatRule,
        style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : null),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDarkMode ? Colors.grey.shade400 : null,
      ),
      onTap: _selectRepeat,
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        OutlinedButton.icon(
          onPressed: () => _copyEvent(context),
          icon: Icon(
            Icons.copy,
            color: isDarkMode ? Colors.grey.shade300 : null,
          ),
          label: Text(
            'Copy',
            style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : null),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _moveEvent(context),
          icon: Icon(
            Icons.drive_file_move,
            color: isDarkMode ? Colors.grey.shade300 : null,
          ),
          label: Text(
            'Move',
            style: TextStyle(color: isDarkMode ? Colors.grey.shade300 : null),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _deleteEvent(context),
          icon: const Icon(Icons.delete, color: Colors.red),
          label: const Text('Delete', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? _selectedDate
          : (_selectedEndDate ?? _selectedDate),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _selectedDate = date;
        } else {
          _selectedEndDate = date;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );

    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  void _addAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppConstants.alertOptions.map((minutes) {
              return ListTile(
                title: Text(_formatAlertOption(minutes)),
                onTap: () {
                  setState(() {
                    _alerts.add(EventAlert(minutesBefore: minutes));
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _selectRepeat() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Repeat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppConstants.repeatOptions.map((option) {
              return RadioListTile<String>(
                value: option,
                groupValue: _repeatRule,
                title: Text(option),
                onChanged: (value) {
                  setState(() {
                    _repeatRule = value!;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatAlertOption(int minutes) {
    if (minutes == 0) return 'At time of event';
    if (minutes < 60) return '$minutes minutes before';
    if (minutes < 1440) return '${minutes ~/ 60} hours before';
    return '${minutes ~/ 1440} days before';
  }

  void _saveEvent() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    final provider = Provider.of<CalendarProvider>(context, listen: false);

    final event = CalendarEvent(
      id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      date: _selectedDate,
      endDate: _selectedEndDate,
      startTime: _startTime,
      endTime: _endTime,
      isAllDay: _isAllDay,
      location: _locationController.text.isEmpty
          ? null
          : _locationController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      color: _selectedColor,
      categories: _selectedCategories,
      alerts: _alerts,
      repeatRule: _repeatRule == 'Never' ? null : _repeatRule,
      invitees: _invitees,
    );

    if (widget.event != null) {
      provider.updateEvent(event);
    } else {
      provider.addEvent(event);
    }

    Navigator.pop(context);
  }

  void _copyEvent(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    provider.selectEvent(widget.event!);
    provider.setMode(CalendarMode.copy);
    Navigator.pop(context);
  }

  void _moveEvent(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    provider.selectEvent(widget.event!);
    provider.setMode(CalendarMode.move);
    Navigator.pop(context);
  }

  void _deleteEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text('Are you sure you want to delete this event?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final provider = Provider.of<CalendarProvider>(
                  context,
                  listen: false,
                );
                provider.deleteEvent(widget.event!.id);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close overlay
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
