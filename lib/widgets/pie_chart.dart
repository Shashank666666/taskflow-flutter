import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TaskPieChart extends StatelessWidget {
  final int completedTasks;
  final int inProgressTasks;
  final int pendingTasks;
  final int highPriorityTasks;
  final int totalTasks;

  const TaskPieChart({
    super.key,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.pendingTasks,
    required this.highPriorityTasks,
    required this.totalTasks,
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
          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
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
    // Fixed data as per design specification
    const int pendingCount = 4;
    const int inProgressCount = 1;
    const int completedCount = 1;
    const int total = pendingCount + inProgressCount + completedCount;

    return [
      // Pending - Amber
      PieChartSectionData(
        color: const Color(0xFFFFA000),
        value: pendingCount.toDouble(),
        title:
            'Pending: $pendingCount (${(pendingCount / total * 100).round()}%)',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFFFFA000),
        ),
        titlePositionPercentageOffset: 1.5,
        showTitle: true,
      ),
      // In Progress - Blue
      PieChartSectionData(
        color: const Color(0xFF4285F4),
        value: inProgressCount.toDouble(),
        title:
            'In Progress: $inProgressCount (${(inProgressCount / total * 100).round()}%)',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4285F4),
        ),
        titlePositionPercentageOffset: 1.5,
        showTitle: true,
      ),
      // Completed - Green
      PieChartSectionData(
        color: const Color(0xFF0F9D58),
        value: completedCount.toDouble(),
        title:
            'Completed: $completedCount (${(completedCount / total * 100).round()}%)',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F9D58),
        ),
        titlePositionPercentageOffset: 1.5,
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
