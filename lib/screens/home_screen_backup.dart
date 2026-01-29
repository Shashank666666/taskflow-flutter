import 'package:flutter/material.dart';
import 'package:taskflow_flutter/models/task.dart';
import 'package:taskflow_flutter/services/task_service.dart';
import 'package:taskflow_flutter/screens/task_creation_screen.dart';
import 'package:taskflow_flutter/widgets/task_list.dart';
import 'package:taskflow_flutter/widgets/pie_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Task> tasks = [];
  String filter = 'all'; // all, active, completed
  int _currentIndex = 0; // 0: Dashboard, 1: Tasks, 2: Teams, 3: Profile
  int _selectedSegment = -1; // 0: high priority, 1: completed, 2: in progress
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  Future<void> _loadTasks() async {
    final loadedTasks = await TaskService.loadTasks();
    print('Loaded ${loadedTasks.length} tasks');
    for (var task in loadedTasks) {
      print(
          'Task: ${task.title} (ID: ${task.id}, Priority: ${task.priority}, Completed: ${task.isCompleted})');
    }

    print(
        'High priority tasks count: ${loadedTasks.where((task) => task.priority == 'High').length}');
    print(
        'Completed tasks count: ${loadedTasks.where((task) => task.isCompleted).length}');
    print(
        'Active high priority tasks count: ${loadedTasks.where((task) => !task.isCompleted && task.priority == 'High').length}');
    print(
        'Active high priority tasks: ${loadedTasks.where((task) => !task.isCompleted && task.priority == 'High').map((t) => t.title).join(', ')}');

    // Add test tasks if no tasks exist
    if (loadedTasks.isEmpty) {
      print('No tasks found, adding test tasks');

      // Add multiple test tasks with different priorities
      final testTasks = [
        Task(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_high',
          title: 'Complete Project Proposal',
          description:
              'Finish the project proposal document and send to stakeholders',
          dueDate: DateTime.now()
              .add(const Duration(hours: 2)), // High priority (due in 2 hours)
          priority: 'High',
          category: 'Work',
        ),
        Task(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString() +
              '_medium',
          title: 'Buy Groceries',
          description:
              'Pick up milk, bread, eggs, and fruits from the supermarket',
          dueDate: DateTime.now().add(
              const Duration(hours: 6)), // Medium priority (due in 6 hours)
          priority: 'Medium',
          category: 'Personal',
        ),
        Task(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString() + '_low1',
          title: 'Schedule Team Meeting',
          description: 'Arrange a meeting with team members for next week',
          dueDate: DateTime.now()
              .add(const Duration(hours: 12)), // Low priority (due in 12 hours)
          priority: 'Low',
          category: 'Work',
        ),
        Task(
          id: (DateTime.now().millisecondsSinceEpoch + 3).toString() + '_low2',
          title: 'Call Mom',
          description: 'Check in with mom and catch up on life',
          dueDate:
              DateTime.now().add(const Duration(hours: 24)), // Low priority
          priority: 'Low',
          category: 'Personal',
        ),
      ];

      // Add each test task
      for (final task in testTasks) {
        await TaskService.addTask(task);
      }

      // Reload tasks
      final updatedTasks = await TaskService.loadTasks();
      print(
          'Added ${testTasks.length} test tasks, now have ${updatedTasks.length} tasks');
      for (var task in updatedTasks) {
        print(
            'Task: ${task.title} (ID: ${task.id}, Priority: ${task.priority})');
      }
      setState(() {
        tasks = updatedTasks;
      });
    } else {
      setState(() {
        tasks = loadedTasks;
      });
    }
  }

  Future<void> _addTask(Task task) async {
    await TaskService.addTask(task);
    _loadTasks();
  }

  Future<void> _updateTask(Task task) async {
    await TaskService.updateTask(task);
    _loadTasks();
  }

  Future<void> _deleteTask(String id) async {
    await TaskService.deleteTask(id);
    _loadTasks();
  }

  void _editTask(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskCreationScreen(
          initialTask: task,
          onSave: _updateTask,
        ),
      ),
    );
    _loadTasks();
  }

  void _toggleTask(Task task) async {
    print('Toggling task: ${task.title} (ID: ${task.id})');
    print('Current completion status: ${task.isCompleted}');

    // Create a new task object with the updated completion status
    Task updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      category: task.category,
      isCompleted: !task.isCompleted,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );

    print('New completion status: ${updatedTask.isCompleted}');

    await TaskService.updateTask(updatedTask);

    print('Task updated in service, reloading tasks...');

    // Reload tasks to ensure state consistency
    _loadTasks();
  }

  Widget _buildDashboardScreen() {
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final pendingTasks = tasks
        .where((task) =>
            !task.isCompleted &&
            (task.priority == 'Low' || task.priority == 'Medium'))
        .length;
    final inProgressTasks = tasks.where((task) => !task.isCompleted).length;
    final highPriorityTasks = tasks
        .where((task) => !task.isCompleted && task.priority == 'High')
        .length;
    final totalTasks = tasks.length;

    // Filter tasks for upcoming tasks - tasks due within 7 days
    List<Task> allFilteredTasks = [];
    List<Task> allUpcomingTasksWithin7Days =
        []; // Store all upcoming tasks for the empty state check

    // Get all tasks that are due within 7 days (both completed and non-completed)
    for (var task in tasks) {
      if (task.dueDate != null) {
        // Check if task is due within 7 days from now
        final daysUntilDue = task.dueDate!.difference(DateTime.now()).inDays;
        if (daysUntilDue <= 7) {
          // Due within 7 days
          allUpcomingTasksWithin7Days
              .add(task); // Add to the list for empty state check
          if (!task.isCompleted) {
            // Only add non-completed tasks to the display list
            allFilteredTasks.add(task);
          }
        }
      }
    }

    // Sort by priority first (High, then Medium, then Low), then by due date
    allFilteredTasks.sort((a, b) {
      // Define priority order
      int priorityOrder(String priority) {
        switch (priority.toLowerCase()) {
          case 'high':
            return 1;
          case 'medium':
            return 2;
          case 'low':
            return 3;
          default:
            return 4;
        }
      }

      int priorityComparison =
          priorityOrder(a.priority) - priorityOrder(b.priority);
      if (priorityComparison != 0) {
        return priorityComparison;
      }

      // If priorities are the same, sort by due date (earliest first)
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1; // a comes first if only a has a due date
      } else if (b.dueDate != null) {
        return 1; // b comes first if only b has a due date
      }

      return 0;
    });

    // Take only the first 3 tasks
    List<Task> filteredTasks = allFilteredTasks.take(3).toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header - similar to task screen header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1), // Indigo background
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications,
                            color: Colors.white),
                        onPressed: () {
                          // TODO: Implement notifications
                        },
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          _userName.isNotEmpty
                              ? _userName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Welcome section with waving hand emoji
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text("👋🏻",
                      style: TextStyle(fontSize: 24, color: Color(0xFFFFCC4D))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${_userName.split(' ').first}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Here\'s what\'s happening with your tasks today.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Pie chart section
            Center(
              child: TaskPieChart(
                completedTasks: completedTasks,
                inProgressTasks: inProgressTasks,
                pendingTasks: pendingTasks,
                highPriorityTasks: highPriorityTasks,
                totalTasks: totalTasks,
                tasks: tasks,
              ),
            ),
            const SizedBox(height: 24),
            // Stat boxes in horizontal layout
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Tasks',
                    '$totalTasks',
                    Icons.check_circle_outline,
                    const Color(0xFF3F51B5), // Indigo-500
                    _handleCompletedSegment,
                    isActive: _selectedSegment == 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    '$completedTasks',
                    Icons.check_circle,
                    const Color(0xFF2E7D32), // Green-800
                    _handleInprogressSegment,
                    isActive: _selectedSegment == 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'In Progress',
                    '$inProgressTasks',
                    Icons.access_time,
                    const Color(0xFFFBC02D), // Yellow-700
                    _handlePrioritySegment,
                    isActive: _selectedSegment == 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'High Priority',
                    '$highPriorityTasks',
                    Icons.error_outline,
                    const Color(0xFFD32F2F), // Red-700
                    _handleInprogressSegment,
                    isActive: _selectedSegment == 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Upcoming tasks section
            if (allUpcomingTasksWithin7Days.isEmpty)
              _buildNoTasksPlaceholder() // No upcoming tasks at all
            else if (allUpcomingTasksWithin7Days
                .every((task) => task.isCompleted))
              // All upcoming tasks are completed
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF), // White
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0), // 1px solid #E0E0E0
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upcoming Due Tasks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700, // Bold (700)
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              'Tasks due within the next 7 days (sorted by priority)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400, // Regular (400)
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.trending_up,
                            color: const Color(
                                0xFF6366F1), // Purple/Blue trend icon
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _currentIndex = 1; // Switch to Tasks screen
                            });
                          },
                          style: IconButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            hoverColor:
                                const Color(0xFF6366F1).withOpacity(0.1),
                            focusColor:
                                const Color(0xFF6366F1).withOpacity(0.2),
                            highlightColor:
                                const Color(0xFF6366F1).withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.white, // White background
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 60,
                            color: Color(0xFF10B981), // Emerald green
                          ),
                          SizedBox(height: 16),
                          Text(
                            'All Caught Up!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Great job! You have completed all upcoming tasks.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Directly open the add task interface
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TaskCreationScreen(onSave: _addTask),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Add a New Task'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF), // White
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0), // 1px solid #E0E0E0
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upcoming Due Tasks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700, // Bold (700)
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              'Tasks due within the next 7 days (sorted by priority)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400, // Regular (400)
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.trending_up,
                            color: const Color(
                                0xFF6366F1), // Purple/Blue trend icon
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _currentIndex = 1; // Switch to Tasks screen
                            });
                          },
                          style: IconButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            hoverColor:
                                const Color(0xFF6366F1).withOpacity(0.1),
                            focusColor:
                                const Color(0xFF6366F1).withOpacity(0.2),
                            highlightColor:
                                const Color(0xFF6366F1).withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Check if all upcoming tasks (within 7 days) are completed
                    if (allUpcomingTasksWithin7Days.isEmpty ||
                        allUpcomingTasksWithin7Days
                            .every((task) => task.isCompleted))
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 1,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 32,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'All Caught Up!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Great job! You have completed all upcoming tasks.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredTasks
                          .take(3)
                          .map((task) => _buildUpcomingDueTaskCard(task))
                          .toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
    VoidCallback? onTap, {
    bool isActive = false,
  }) {
    // Determine background color based on title
    Color backgroundColor;
    if (title == 'Total Tasks') {
      backgroundColor = const Color(0xFF3B82F6); // Blue
    } else if (title == 'Completed') {
      backgroundColor = const Color(0xFF10B981); // Green
    } else if (title == 'In Progress') {
      backgroundColor = const Color(0xFFF59E0B); // Yellow
    } else if (title == 'High Priority') {
      backgroundColor = const Color(0xFFEF4444); // Red
    } else {
      backgroundColor = Colors.white;
    }

    // Check if this is one of the cards that shouldn't be clickable
    bool isNonClickableCard = (title == 'Total Tasks' ||
        title == 'Completed' ||
        title == 'In Progress' ||
        title == 'High Priority');

    // Return container without gesture detector for non-clickable cards
    if (isNonClickableCard) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? backgroundColor.withOpacity(0.8)
              : backgroundColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? backgroundColor : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFE2E8F0),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      // For other cards that should be clickable
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive
                ? backgroundColor.withOpacity(0.8)
                : backgroundColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? backgroundColor : const Color(0xFFE2E8F0),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFE2E8F0),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTaskCard(Task task) {
    // Determine border color based on priority
    Color borderColor;
    switch (task.priority) {
      case 'High':
        borderColor = const Color(0xFFDC2626); // Red-600
        break;
      case 'Medium':
        borderColor = const Color(0xFFF59E0B); // Amber-500
        break;
      case 'Low':
        borderColor = const Color(0xFF10B981); // Emerald-500
        break;
      default:
        borderColor = const Color(0xFF94A3B8); // Slate-400
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE2E8F0),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (bool? value) {
            _toggleTask(task);
          },
          activeColor: const Color(0xFF10B981),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: task.isCompleted
                ? const Color(0xFF94A3B8)
                : const Color(0xFF1E293B),
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: task.isCompleted
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            if (task.dueDate != null)
              Text(
                'Due: ${_formatDate(task.dueDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: task.isCompleted
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.priority,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editTask(task),
              color: const Color(0xFF6366F1),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _showDeleteDialog(task),
              color: const Color(0xFFEF4444),
            ),
          ],
        ),
        onTap: () => _editTask(task),
      ),
    );
  }

  Widget _buildUpcomingTaskCard(Task task) {
    // Determine status indicator color based on completion status
    Color statusColor = task.isCompleted
        ? const Color(0xFF0F9D58)
        : const Color(0xFFFFA000); // Green for completed, Amber for pending

    // Determine priority tag colors
    Color priorityBgColor, priorityTextColor;
    switch (task.priority) {
      case 'High':
        priorityBgColor = const Color(0xFFFFEBEE); // Light red background
        priorityTextColor = const Color(0xFFD32F2F); // Red text
        break;
      case 'Medium':
        priorityBgColor = const Color(0xFFE3F2FD); // Light blue background
        priorityTextColor = const Color(0xFF1976D2); // Blue text
        break;
      default:
        priorityBgColor = const Color(0xFFF1F8E9); // Light green background
        priorityTextColor = const Color(0xFF388E3C); // Green text
    }

    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 0),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF), // White background
        border: Border(
          bottom:
              BorderSide(color: Color(0xFFF0F0F0), width: 1), // Bottom border
        ),
      ),
      child: Row(
        children: [
          // Status indicator circle
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 16, left: 8),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // Text column (Title and Date/Time)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // Semi-bold
                    color: Color(0xFF333333),
                  ),
                ),
                if (task.dueDate != null) ...[
                  Text(
                    _formatDateTime(task.dueDate!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Priority tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: priorityBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              task.priority,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: priorityTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDueTaskCard(Task task) {
    // Debug print to see task data
    print('Building task card for: ${task.title} (ID: ${task.id})');

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
          task.title.isEmpty ? '(No Title)' : task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
          overflow: TextOverflow.ellipsis,
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
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
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
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
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
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF64748B)), // Pencil
              onPressed: () => _editTask(task),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Color(0xFFEF4444)), // Trash
              onPressed: () => _showDeleteDialog(task),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _toggleTask(task),
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
        onTap: () => _toggleTask(task),
      ),
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

  String _formatDateTime(DateTime date) {
    // Format as "Jan 25, 2026 - 10:00 AM"
    String month = _getMonthName(date.month);
    String ampm = date.hour >= 12 ? 'PM' : 'AM';
    int hour = date.hour % 12;
    if (hour == 0) hour = 12;
    String minute = date.minute.toString().padLeft(2, '0');
    return '$month ${date.day}, ${date.year} - $hour:$minute $ampm';
  }

  String _getTaskStatus(Task task) {
    // If task is completed, return completed status
    if (task.isCompleted) {
      return 'Completed';
    }

    // Determine status based on due date proximity
    if (task.dueDate != null) {
      final now = DateTime.now();
      final difference = task.dueDate!.difference(now);

      // If due date has passed or is within 1 hour, consider it in progress
      if (difference.inHours <= 1) {
        return 'In Progress';
      }
    }

    // Otherwise, it's pending
    return 'Pending';
  }

  // Method to determine which icon to show based on task status
  IconData _getTaskIcon(Task task) {
    if (task.isCompleted) {
      return Icons.check_circle;
    } else if (_getTaskStatus(task) == 'In Progress') {
      return Icons.hourglass_top;
    } else {
      return Icons.hourglass_empty;
    }
  }

  // Method to determine icon color based on task status
  Color _getTaskIconColor(Task task) {
    if (task.isCompleted) {
      return const Color(0xFF10B981); // Green for completed
    } else if (_getTaskStatus(task) == 'In Progress') {
      return const Color(0xFF4285F4); // Blue for in progress
    } else {
      return const Color(0xFFFFA000); // Amber for pending
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  void _showDeleteDialog(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteTask(task.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task deleted')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _handlePrioritySegment() {
    setState(() {
      _selectedSegment = _selectedSegment == 0 ? -1 : 0;
    });
  }

  void _handleCompletedSegment() {
    setState(() {
      _selectedSegment = _selectedSegment == 1 ? -1 : 1;
    });
  }

  void _handleInprogressSegment() {
    setState(() {
      _selectedSegment = _selectedSegment == 2 ? -1 : 2;
    });
  }

  Widget _buildNoTasksPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE2E8F0),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("👋🏻",
              style: TextStyle(fontSize: 48, color: Color(0xFFFFCC4D))),
          const SizedBox(height: 16),
          const Text(
            'No upcoming tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a task to get started',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskCreationScreen(onSave: _addTask),
                ),
              ).then((_) => _loadTasks());
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Task'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TaskList(
            tasks: tasks,
            onTaskTap: _editTask,
            onTaskToggle: _toggleTask,
            onDeleteTask: (task) => _deleteTask(task.id),
          ),
          TaskList(
            tasks: tasks.where((task) => !task.isCompleted).toList(),
            onTaskTap: _editTask,
            onTaskToggle: _toggleTask,
            onDeleteTask: (task) => _deleteTask(task.id),
          ),
          TaskList(
            tasks: tasks.where((task) => task.isCompleted).toList(),
            onTaskTap: _editTask,
            onTaskToggle: _toggleTask,
            onDeleteTask: (task) => _deleteTask(task.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskCreationScreen(onSave: _addTask),
            ),
          );
          _loadTasks();
        },
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTeamsScreen() {
    return const Center(
      child: Text('Teams Screen - Coming Soon'),
    );
  }

  Widget _buildProfileScreen() {
    return const Center(
      child: Text('Profile Screen - Coming Soon'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardScreen(),
          _buildTasksScreen(),
          _buildTeamsScreen(),
          _buildProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Teams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4F46E5),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedIconTheme: const IconThemeData(color: Color(0xFF4F46E5)),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskCreationScreen(onSave: _addTask),
                  ),
                );
                _loadTasks();
              },
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
