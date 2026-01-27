import 'package:flutter/material.dart';
import 'dart:math' as math;

class TaskPieChart extends StatelessWidget {
  final int completedTasks;
  final int inProgressTasks;
  final int highPriorityTasks;
  final int totalTasks;

  const TaskPieChart({
    Key? key,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.highPriorityTasks,
    required this.totalTasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
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
          // Pie chart
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: PieChartPainter(
                completedTasks: completedTasks,
                inProgressTasks: inProgressTasks,
                highPriorityTasks: highPriorityTasks,
                totalTasks: totalTasks,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          _buildLegendItem('Completed', completedTasks, const Color(0xFF10B981)),
          _buildLegendItem('In Progress', inProgressTasks, const Color(0xFFF59E0B)),
          _buildLegendItem('High Priority', highPriorityTasks, const Color(0xFFDC2626)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
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
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final int completedTasks;
  final int inProgressTasks;
  final int highPriorityTasks;
  final int totalTasks;

  PieChartPainter({
    required this.completedTasks,
    required this.inProgressTasks,
    required this.highPriorityTasks,
    required this.totalTasks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalTasks == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    
    final paint = Paint()
      ..style = PaintingStyle.fill;

    double startAngle = -math.pi / 2; // Start from top

    // Completed tasks (Green)
    if (completedTasks > 0) {
      final sweepAngle = (completedTasks / totalTasks) * 2 * math.pi;
      paint.color = const Color(0xFF10B981);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // In Progress tasks (Yellow)
    if (inProgressTasks > 0) {
      final sweepAngle = (inProgressTasks / totalTasks) * 2 * math.pi;
      paint.color = const Color(0xFFF59E0B);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // High Priority tasks (Red)
    if (highPriorityTasks > 0) {
      final sweepAngle = (highPriorityTasks / totalTasks) * 2 * math.pi;
      paint.color = const Color(0xFFDC2626);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}