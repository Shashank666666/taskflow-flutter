import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onTaskToggle;
  final Function(Task)? onDeleteTask;

  const TaskList({
    Key? key,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskToggle,
    this.onDeleteTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0), // Soft Grey
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B), // Slate Grey
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPriorityPill(task.priority),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.category,
                        style: const TextStyle(
                          color: Color(0xFF64748B), // Slate Grey
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Due: ${_formatDate(task.dueDate!)}',
                          style: const TextStyle(
                            color: Color(0xFF64748B), // Slate Grey
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit,
                      color: Color(0xFF64748B)), // Pencil
                  onPressed: () =>
                      onTaskTap(task), // This will open the edit screen
                ),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Color(0xFFEF4444)), // Trash
                  onPressed: () => onDeleteTask != null
                      ? onDeleteTask!(task)
                      : null, // Call delete callback
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onTaskToggle(task),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? const Color(0xFF10B981) // Green
                          : const Color(0xFFCBD5E1), // Grey
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? const Color(0xFF10B981) // Green
                            : const Color(0xFF94A3B8), // Lighter Grey
                        width: 1.5,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ],
            ),
            onTap: () =>
                onTaskToggle(task), // Now clicking the task toggles completion
          ),
        );
      },
    );
  }

  Widget _buildPriorityPill(String priority) {
    Color backgroundColor;
    Color textColor;

    switch (priority) {
      case 'High':
        backgroundColor = const Color(0xFFFEE2E2); // Light Red
        textColor = const Color(0xFFEF4444); // Red
        break;
      case 'Medium':
        backgroundColor = const Color(0xFFFEF3C7); // Light Yellow
        textColor = const Color(0xFFF59E0B); // Amber
        break;
      case 'Low':
        backgroundColor = const Color(0xFFD1FAE5); // Light Green
        textColor = const Color(0xFF10B981); // Emerald
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
