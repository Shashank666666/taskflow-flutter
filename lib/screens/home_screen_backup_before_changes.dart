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
    setState(() {
      tasks = loadedTasks;
    });
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
    task.isCompleted = !task.isCompleted;
    task.updatedAt = DateTime.now();
    await TaskService.updateTask(task);
    _loadTasks();
  }

  Widget _buildDashboardScreen() {
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final inProgressTasks = tasks.where((task) => !task.isCompleted).length;
    final highPriorityTasks =
        tasks.where((task) => task.priority == 'High').length;
    final totalTasks = tasks.length;

    // Filter tasks for upcoming tasks - only high priority and completed status
    List<Task> filteredTasks = [];
    int highPriorityCount = 0;

    for (var task in tasks) {
      if (highPriorityCount < 3 && task.priority == 'High') {
        filteredTasks.add(task);
        highPriorityCount++;
      }
    }

    if (highPriorityCount < 3) {
      for (var task in tasks) {
        if (highPriorityCount < 3 &&
            !filteredTasks.contains(task) &&
            task.isCompleted) {
          filteredTasks.add(task);
          highPriorityCount++;
        }
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section with waving hand emoji
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFCF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFFECD9F),
                    blurRadius: 20,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text("👋🏻",
                      style: const TextStyle(
                          fontSize: 24, color: Color(0xFFFFCC4D))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${_userName.split(' ').first}!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Here\'s what\'s happening with your tasks today',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
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
                highPriorityTasks: highPriorityTasks,
                totalTasks: totalTasks,
              ),
            ),
            const SizedBox(height: 24),
            // Stat boxes in horizontal layout
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    '$completedTasks',
                    Icons.check_circle_outline,
                    const Color(0xFF10B981), // Emerald-500
                    _handleCompletedSegment,
                    isActive: _selectedSegment == 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Ongoing',
                    '$inProgressTasks',
                    Icons.schedule,
                    const Color(0xFFF59E0B), // Amber-500
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
                    'High Priority',
                    '$highPriorityTasks',
                    Icons.error_outline,
                    const Color(0xFFDC2626), // Red-600
                    _handlePrioritySegment,
                    isActive: _selectedSegment == 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'In Progress',
                    '$inProgressTasks',
                    Icons.play_circle_outline,
                    const Color(0xFF3B82F6), // Blue-500
                    _handleInprogressSegment,
                    isActive: _selectedSegment == 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Upcoming tasks section
            if (filteredTasks.isEmpty)
              _buildNoTasksPlaceholder()
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...filteredTasks.map((task) => _buildTaskCard(task)).toList(),
                ],
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
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE2E8F0),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? color : const Color(0xFF94A3B8),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isActive ? color : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? color : const Color(0xFF64748B),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
          Text("👋🏻",
              style: const TextStyle(fontSize: 48, color: Color(0xFFFFCC4D))),
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
    if (_currentIndex == 0) {
      return _buildDashboardScreen();
    } else if (_currentIndex == 1) {
      return _buildTasksScreen();
    } else if (_currentIndex == 2) {
      return _buildTeamsScreen();
    } else {
      return _buildProfileScreen();
    }
  }
}
