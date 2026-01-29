import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskPieChart extends StatelessWidget {
  final int completedTasks;
  final int inProgressTasks;
  final int pendingTasks;
  final int highPriorityTasks;
  final int totalTasks;
  final List<Task> tasks;

  const TaskPieChart({
    super.key,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.pendingTasks,
    required this.highPriorityTasks,
    required this.totalTasks,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Task Status Overview",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Distribution of tasks by status",
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              height: 220,
              width: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                  sections: _getSections(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    // Use dynamic data from widget parameters
    final int highPriorityCount = highPriorityTasks;
    final int mediumPriorityCount = tasks
        .where((task) =>
            task != null && !task.isCompleted && task.priority == 'Medium')
        .length;
    final int lowPriorityCount = tasks
        .where((task) =>
            task != null && !task.isCompleted && task.priority == 'Low')
        .length;
    final int completedCount = completedTasks;
    final int total = totalTasks > 0 ? totalTasks : 1; // Avoid division by zero

    return [
      // High Priority - Red
      if (highPriorityCount > 0)
        PieChartSectionData(
          color: const Color(0xFFEF4444),
          value: highPriorityCount.toDouble(),
          title:
              'High Priority\n${highPriorityCount}\n(${(highPriorityCount / total * 100).round()}%)',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titlePositionPercentageOffset: 0.7,
          showTitle: true,
        ),
      // Medium Priority - Blue
      if (mediumPriorityCount > 0)
        PieChartSectionData(
          color: const Color(0xFF3B82F6),
          value: mediumPriorityCount.toDouble(),
          title:
              'Medium\n${mediumPriorityCount}\n(${(mediumPriorityCount / total * 100).round()}%)',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titlePositionPercentageOffset: 0.7,
          showTitle: true,
        ),
      // Low Priority - Amber
      if (lowPriorityCount > 0)
        PieChartSectionData(
          color: const Color(0xFFF59E0B),
          value: lowPriorityCount.toDouble(),
          title:
              'Low\n${lowPriorityCount}\n(${(lowPriorityCount / total * 100).round()}%)',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titlePositionPercentageOffset: 0.7,
          showTitle: true,
        ),
      // Completed - Green
      if (completedCount > 0)
        PieChartSectionData(
          color: const Color(0xFF10B981),
          value: completedCount.toDouble(),
          title:
              'Completed\n${completedCount}\n(${(completedCount / total * 100).round()}%)',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titlePositionPercentageOffset: 0.7,
          showTitle: true,
        ),
    ];
  }

  Widget _buildIconForSegment(int index) {
    switch (index) {
      case 0: // Pending
        return const Icon(
          Icons.hourglass_empty,
          color: Color(0xFFFFA000),
          size: 24,
        );
      case 1: // In Progress
        return const Icon(
          Icons.hourglass_top,
          color: Color(0xFF4285F4),
          size: 24,
        );
      case 2: // Completed
        return const Icon(
          Icons.check_circle,
          color: Color(0xFF0F9D58),
          size: 24,
        );
      default:
        return const Icon(
          Icons.help_outline,
          color: Colors.grey,
          size: 24,
        );
    }
  }
}
