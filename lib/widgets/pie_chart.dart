import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskPieChart extends StatefulWidget {
  final int completedTasks;
  final int inProgressTasks;
  final int pendingTasks;
  final int highPriorityTasks;
  final int totalTasks;
  final List<Task> tasks;

  const TaskPieChart({
    Key? key,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.pendingTasks,
    required this.highPriorityTasks,
    required this.totalTasks,
    required this.tasks,
  }) : super(key: key);

  @override
  _TaskPieChartState createState() => _TaskPieChartState();
}

class _TaskPieChartState extends State<TaskPieChart> {
  @override
  Widget build(BuildContext context) {
    // Calculate actual counts
    final int completedCount = widget.completedTasks;
    final int inProgressCount = widget.inProgressTasks;
    final int highPriorityCount = widget.highPriorityTasks;
    final int totalTasks = widget.totalTasks;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Task Status Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          // Status labels at the top with percentages and counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusLegendWithStats('Completed', const Color(0xFF10B981),
                  completedCount, totalTasks),
              _buildStatusLegendWithStats('In Progress',
                  const Color(0xFFF59E0B), inProgressCount, totalTasks),
              _buildStatusLegendWithStats('High Priority',
                  const Color(0xFFEF4444), highPriorityCount, totalTasks),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 200,
              width: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                  sections: _getSectionsWithoutLabels(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegendWithStats(
      String label, Color color, int count, int total) {
    final double percentage = total > 0 ? (count / total) * 100 : 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}% ($count)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _getSectionsWithoutLabels() {
    // Use dynamic data from widget parameters
    final int highPriorityCount = widget.highPriorityTasks;
    final int completedCount = widget.completedTasks;
    final int inProgressCount = widget.inProgressTasks;

    // Only include non-zero sections
    List<PieChartSectionData> sections = [];

    if (completedCount > 0) {
      sections.add(
        PieChartSectionData(
          color: const Color(0xFF10B981), // Green for completed
          value: completedCount.toDouble(),
          radius: 60,
          showTitle: false,
        ),
      );
    }

    if (inProgressCount > 0) {
      sections.add(
        PieChartSectionData(
          color: const Color(0xFFF59E0B), // Yellow for in progress
          value: inProgressCount.toDouble(),
          radius: 60,
          showTitle: false,
        ),
      );
    }

    if (highPriorityCount > 0) {
      sections.add(
        PieChartSectionData(
          color: const Color(0xFFEF4444), // Red for high priority
          value: highPriorityCount.toDouble(),
          radius: 60,
          showTitle: false,
        ),
      );
    }

    // If no tasks, show a gray section
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: const Color(0xFF9CA3AF), // Gray for empty
          value: 1.0,
          radius: 60,
          showTitle: false,
        ),
      );
    }

    return sections;
  }
}
