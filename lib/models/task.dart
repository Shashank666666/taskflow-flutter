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
  static double calculateImportanceScore(Task task, {Map<String, int> userHistory = const {}}) {
    // Base importance score based on priority (High=100, Medium=70, Low=30)
    double priorityScore = task.priority == 'High' 
      ? 100 
      : (task.priority == 'Medium' ? 70 : 30);

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
        priorityScore *= 1.2; // User frequently completes tasks in this category
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

  static List<Task> getSmartUpcomingTasks(List<Task> allTasks, {Map<String, int> userHistory = const {}}) {
    // Filter out completed tasks
    final activeTasks = allTasks.where((task) => !task.isCompleted).toList();

    // If no active tasks, return empty list to show "all completed" message
    if (activeTasks.isEmpty) {
      return [];
    }

    // Calculate importance scores for all active tasks
    final scoredTasks = activeTasks.map((task) {
      return {
        'task': task,
        'score': calculateImportanceScore(task, userHistory: userHistory),
      };
    }).toList();

    // Sort by importance score (descending)
    scoredTasks.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // Get high priority tasks first (max 3)
    final highPriorityTasks = scoredTasks
        .where((item) => (item['task'] as Task).priority == 'High')
        .take(3)
        .map((item) => item['task'] as Task)
        .toList();

    // If we have fewer than 3 high priority tasks, fill with medium priority
    if (highPriorityTasks.length < 3) {
      final mediumPriorityTasks = scoredTasks
          .where((item) => (item['task'] as Task).priority == 'Medium')
          .take(3 - highPriorityTasks.length)
          .map((item) => item['task'] as Task)
          .toList();
      
      highPriorityTasks.addAll(mediumPriorityTasks);
    }

    // If we still have fewer than 3 tasks, fill with low priority
    if (highPriorityTasks.length < 3) {
      final lowPriorityTasks = scoredTasks
          .where((item) => (item['task'] as Task).priority == 'Low')
          .take(3 - highPriorityTasks.length)
          .map((item) => item['task'] as Task)
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
