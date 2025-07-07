import 'package:flutter/material.dart';

class ReminderPickerWidget extends StatefulWidget {
  final DateTime? initialReminderTime;
  final Function(DateTime?) onReminderChanged;

  const ReminderPickerWidget({
    super.key,
    this.initialReminderTime,
    required this.onReminderChanged,
  });

  @override
  State<ReminderPickerWidget> createState() => _ReminderPickerWidgetState();
}

class _ReminderPickerWidgetState extends State<ReminderPickerWidget> {
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialReminderTime;
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now(),
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
        widget.onReminderChanged(_selectedDateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.alarm),
      title: Text(
        _selectedDateTime == null
            ? 'Hatırlatıcı Ayarla'
            : 'Hatırlatıcı: ${_formatDateTime(_selectedDateTime!)}',
      ),
      trailing:
          _selectedDateTime != null
              ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedDateTime = null;
                  });
                  widget.onReminderChanged(null);
                },
              )
              : null,
      onTap: () => _pickDateTime(context),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    // You might want to use the intl package for more robust formatting
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
