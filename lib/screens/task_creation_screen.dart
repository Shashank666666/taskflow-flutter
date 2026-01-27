import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskCreationScreen extends StatefulWidget {
  final Function(Task) onSave;
  final Task? initialTask; // Optional initial task for editing

  const TaskCreationScreen({Key? key, required this.onSave, this.initialTask}) : super(key: key);

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
      _descriptionController = TextEditingController(text: widget.initialTask!.description);
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
      _dueDate = DateTime.now().add(const Duration(days: 1)); // Default to tomorrow
      _dueTime = const TimeOfDay(hour: 9, minute: 0); // Default to 9 AM
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
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectDueTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _dueTime) {
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
        id: widget.initialTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), // Keep original ID when editing
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: combinedDateTime, // Use combined date and time
        priority: calculatedPriority, // Use ML-calculated priority
        category: _category,
        isCompleted: widget.initialTask?.isCompleted ?? false, // Preserve completion status
        createdAt: widget.initialTask?.createdAt ?? DateTime.now(), // Keep original creation date when editing
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
    } else if (hoursUntilDue < 10) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.initialTask != null ? const Text('Edit Task') : const Text('Create New Task'),
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
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter task description',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value != null && value.length > 500) {
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
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ListTile(
                              title: const Text('Due Date'),
                              subtitle: _dueDate != null
                                  ? Text('${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}')
                                  : const Text('Select date'),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _selectDueDate,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: ListTile(
                              title: const Text('Time'),
                              subtitle: _dueTime != null
                                  ? Text(_dueTime!.format(context))
                                  : const Text('Select time'),
                              trailing: const Icon(Icons.access_time),
                              onTap: _selectDueTime,
                            ),
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