class Task {
  String id;
  String userId;
  String title;
  String description;
  DateTime? dueDate;
  String priority; // High, Medium, Low
  String category; // Work, Personal, Shopping, Health, Education, Entertainment
  bool isCompleted;
  DateTime createdAt;
  DateTime updatedAt;

  Task({
    this.id = '',
    this.userId = '',
    this.title = '',
    this.description = '',
    this.dueDate,
    this.priority = 'Medium',
    this.category = 'Personal',
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: json['priority'] ?? 'Medium',
      category: json['category'] ?? 'Personal',
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'category': category,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class TaskPriorityMLModel {
  static String calculatePriorityBasedOnTime(Task task) {
    if (task.dueDate == null) {
      return 'Low'; // If no due date, default to low priority
    }

    final now = DateTime.now();
    final difference = task.dueDate!.difference(now).inHours;

    if (difference < 3) {
      return 'High'; // Less than 3 hours: High priority
    } else if (difference < 8) {
      return 'Medium'; // Less than 8 hours: Medium priority
    } else if (difference < 15) {
      return 'Low'; // Less than 15 hours: Low priority
    } else {
      return 'Low'; // More than 15 hours: Low priority
    }
  }

  static double calculateImportanceScore(Task task,
      {Map<String, int> userHistory = const {}}) {
    // Calculate priority based on time to due date
    String timeBasedPriority = calculatePriorityBasedOnTime(task);

    // Base importance score based on priority (High=100, Medium=70, Low=30)
    double priorityScore = timeBasedPriority == 'High'
        ? 100
        : (timeBasedPriority == 'Medium' ? 70 : 30);

    // Due date urgency factor
    if (task.dueDate != null) {
      final dueDateTime = task.dueDate!.difference(DateTime.now()).inMinutes;
      if (dueDateTime < 60) {
        priorityScore *= 1.5; // Very urgent
      } else if (dueDateTime < 1440) {
        priorityScore *= 1.3; // Due within 24 hours
      } else if (dueDateTime < 10080) {
        priorityScore *= 1.1; // Due within a week
      }
    }

    // User completion history factor (learned behavior)
    if (userHistory.containsKey(task.category)) {
      final categoryCount = userHistory[task.category] ?? 0;
      if (categoryCount > 5) {
        priorityScore *=
            1.2; // User frequently completes tasks in this category
      }
    }

    // Task age factor (newer tasks get slight boost)
    final taskAge = DateTime.now().difference(task.createdAt).inDays;
    if (taskAge < 3) {
      priorityScore *= 1.1; // New tasks get priority boost
    }

    // Task update recency (recently updated tasks get boost)
    final lastUpdate = DateTime.now().difference(task.updatedAt).inHours;
    if (lastUpdate < 24) {
      priorityScore *= 1.05; // Recently updated tasks
    }

    return priorityScore;
  }

  static List<Task> getSmartUpcomingTasks(List<Task> allTasks,
      {Map<String, int> userHistory = const {}}) {
    // Filter out completed tasks
    final activeTasks = allTasks.where((task) => !task.isCompleted).toList();

    // If no active tasks, return empty list to show "all completed" message
    if (activeTasks.isEmpty) {
      return [];
    }

    // Sort tasks by priority (High > Medium > Low) and then by due date
    final sortedTasks = activeTasks
      ..sort((a, b) {
        // First sort by priority
        int priorityComparison;
        String aPriority = calculatePriorityBasedOnTime(a);
        String bPriority = calculatePriorityBasedOnTime(b);

        if (aPriority == 'High' && bPriority != 'High') {
          priorityComparison = -1;
        } else if (aPriority != 'High' && bPriority == 'High') {
          priorityComparison = 1;
        } else if (aPriority == 'Medium' && bPriority == 'Low') {
          priorityComparison = -1;
        } else if (aPriority == 'Low' && bPriority == 'Medium') {
          priorityComparison = 1;
        } else {
          priorityComparison = 0; // Same priority
        }

        // If priorities are the same, sort by due date (earlier first)
        if (priorityComparison == 0) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        }

        return priorityComparison;
      });

    // Get high priority tasks first (max 3)
    final highPriorityTasks = sortedTasks
        .where((task) => calculatePriorityBasedOnTime(task) == 'High')
        .take(3)
        .toList();

    // If we have fewer than 3 high priority tasks, fill with medium priority
    if (highPriorityTasks.length < 3) {
      final mediumPriorityTasks = sortedTasks
          .where((task) =>
              calculatePriorityBasedOnTime(task) == 'Medium' &&
              !highPriorityTasks.contains(task))
          .take(3 - highPriorityTasks.length)
          .toList();

      highPriorityTasks.addAll(mediumPriorityTasks);
    }

    // If we still have fewer than 3 tasks, fill with low priority
    if (highPriorityTasks.length < 3) {
      final lowPriorityTasks = sortedTasks
          .where((task) =>
              calculatePriorityBasedOnTime(task) == 'Low' &&
              !highPriorityTasks.contains(task))
          .take(3 - highPriorityTasks.length)
          .toList();

      highPriorityTasks.addAll(lowPriorityTasks);
    }

    return highPriorityTasks.take(3).toList();
  }

  // Check if all tasks are completed
  static bool areAllTasksCompleted(List<Task> allTasks) {
    return allTasks.isNotEmpty && allTasks.every((task) => task.isCompleted);
  }
}
