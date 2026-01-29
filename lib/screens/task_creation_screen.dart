import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCreationScreen extends StatefulWidget {
  final Function(Task) onSave;
  final Task? initialTask; // Optional initial task for editing

  const TaskCreationScreen({Key? key, required this.onSave, this.initialTask})
      : super(key: key);

  @override
  _TaskCreationScreenState createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _priority;
  late String _category;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and values based on initialTask if provided
    if (widget.initialTask != null) {
      _titleController = TextEditingController(text: widget.initialTask!.title);
      _descriptionController =
          TextEditingController(text: widget.initialTask!.description);
      _priority = widget.initialTask!.priority;
      _category = widget.initialTask!.category;
      _dueDate = widget.initialTask!.dueDate;
      _dueTime = _dueDate != null
          ? TimeOfDay.fromDateTime(_dueDate!)
          : TimeOfDay.now();
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _priority = 'Medium';
      _category = 'Personal';
      // Default to current date and time
      DateTime now = DateTime.now();
      _dueDate = now;
      _dueTime = TimeOfDay.fromDateTime(now);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Only allow selecting today and future dates
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
      // If the selected date is today and the time is in the past, reset time to current
      if (_dueDate != null && _dueTime != null) {
        DateTime combinedDateTime = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _dueTime!.hour,
          _dueTime!.minute,
        );
        if (combinedDateTime.isBefore(DateTime.now())) {
          DateTime now = DateTime.now();
          _dueTime = TimeOfDay.fromDateTime(now);
        }
      }
    }
  }

  Future<void> _selectDueTime() async {
    TimeOfDay initialTime = _dueTime ?? TimeOfDay.now();

    // Check if the selected date is today, and if so, adjust initial time to prevent past times
    if (_dueDate != null &&
        _dueDate!.day == DateTime.now().day &&
        _dueDate!.month == DateTime.now().month &&
        _dueDate!.year == DateTime.now().year) {
      TimeOfDay currentTime = TimeOfDay.fromDateTime(DateTime.now());
      // If the current selected time is before current time, use current time
      if (_dueTime != null && _dueTime!.hour < currentTime.hour ||
          (_dueTime!.hour == currentTime.hour &&
              _dueTime!.minute < currentTime.minute)) {
        initialTime = currentTime;
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null && picked != _dueTime) {
      // Check if the selected date is today and the selected time is in the past
      if (_dueDate != null &&
          _dueDate!.day == DateTime.now().day &&
          _dueDate!.month == DateTime.now().month &&
          _dueDate!.year == DateTime.now().year) {
        DateTime selectedDateTime = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          picked.hour,
          picked.minute,
        );
        if (selectedDateTime.isBefore(DateTime.now())) {
          // Show snackbar to inform user that past time cannot be selected
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot select a time that has already passed'),
              backgroundColor: Colors.red,
            ),
          );
          return; // Don't update the time
        }
      }
      setState(() {
        _dueTime = picked;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      // Combine date and time
      DateTime? combinedDateTime;
      if (_dueDate != null && _dueTime != null) {
        combinedDateTime = DateTime(
          _dueDate!.year,
          _dueDate!.month,
          _dueDate!.day,
          _dueTime!.hour,
          _dueTime!.minute,
        );
      }

      // Calculate priority based on due date/time using ML-based logic
      String calculatedPriority = _calculatePriority(combinedDateTime);

      final task = Task(
        id: widget.initialTask?.id ??
            DateTime.now()
                .millisecondsSinceEpoch
                .toString(), // Keep original ID when editing
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: combinedDateTime, // Use combined date and time
        priority: calculatedPriority, // Use ML-calculated priority
        category: _category,
        isCompleted: widget.initialTask?.isCompleted ??
            false, // Preserve completion status
        createdAt: widget.initialTask?.createdAt ??
            DateTime.now(), // Keep original creation date when editing
        updatedAt: DateTime.now(), // Update the timestamp
      );
      widget.onSave(task);
      Navigator.pop(context);
    }
  }

  String _calculatePriority(DateTime? dueDate) {
    if (dueDate == null) {
      return 'Low'; // Default to Low if no due date set
    }

    Duration timeUntilDue = dueDate.difference(DateTime.now());
    int hoursUntilDue = timeUntilDue.inHours;

    if (hoursUntilDue < 3) {
      return 'High';
    } else if (hoursUntilDue < 8) {
      return 'Medium';
    } else if (hoursUntilDue < 15) {
      return 'Low';
    } else {
      return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.initialTask != null
            ? const Text('Edit Task')
            : const Text('Create New Task'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter task title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.length > 100) {
                    return 'Title is too long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter task description',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length > 500) {
                    return 'Description is too long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Combined date and time selection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Due Date & Time *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Date',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_dueDate != null
                                    ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                    : 'Select date'),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Due Time',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_dueTime != null
                                    ? _dueTime!.format(context)
                                    : 'Select time'),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _selectDueDate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Select Date'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _selectDueTime,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Select Time'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Priority',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: [
                  ChoiceChip(
                    label: const Text('Low'),
                    selected: _priority == 'Low',
                    onSelected: (selected) {
                      setState(() {
                        _priority = selected ? 'Low' : _priority;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Medium'),
                    selected: _priority == 'Medium',
                    onSelected: (selected) {
                      setState(() {
                        _priority = selected ? 'Medium' : _priority;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('High'),
                    selected: _priority == 'High',
                    onSelected: (selected) {
                      setState(() {
                        _priority = selected ? 'High' : _priority;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: [
                  ChoiceChip(
                    label: const Text('Personal'),
                    selected: _category == 'Personal',
                    onSelected: (selected) {
                      setState(() {
                        _category = selected ? 'Personal' : _category;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Work'),
                    selected: _category == 'Work',
                    onSelected: (selected) {
                      setState(() {
                        _category = selected ? 'Work' : _category;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Shopping'),
                    selected: _category == 'Shopping',
                    onSelected: (selected) {
                      setState(() {
                        _category = selected ? 'Shopping' : _category;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Health'),
                    selected: _category == 'Health',
                    onSelected: (selected) {
                      setState(() {
                        _category = selected ? 'Health' : _category;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Education'),
                    selected: _category == 'Education',
                    onSelected: (selected) {
                      setState(() {
                        _category = selected ? 'Education' : _category;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Entertainment'),
                    selected: _category == 'Entertainment',
                    onSelected: (selected) {
                      setState(() {
                        _category = selected ? 'Entertainment' : _category;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.initialTask != null ? 'Update Task' : 'Save Task',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
