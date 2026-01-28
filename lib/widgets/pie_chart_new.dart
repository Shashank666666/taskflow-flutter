import 'package:flutter/material.dart';
import 'dart:math';

String _formatPercentage(double ratio) {
  return '${(ratio * 100).round()}%';
}

class TaskStatusPieChart extends StatelessWidget {
  final int completedTasks;
  final int inProgressTasks;
  final int pendingTasks;
  final int totalTasks;

  const TaskStatusPieChart({
    Key? key,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.pendingTasks,
    required this.totalTasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
          Text("Task Status Overview",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF333333))),
          Text("Distribution of tasks by status",
              style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  color: Color(0xFF757575))),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(180, 180),
                  painter: PieChartPainter(
                    completedTasks: completedTasks,
                    inProgressTasks: inProgressTasks,
                    pendingTasks: pendingTasks,
                    totalTasks: totalTasks,
                  ),
                ),
                // Labels Positioned Externally
                if (inProgressTasks > 0)
                  Positioned(
                      top: -10,
                      child: Text("In Progress: ",
                          style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontWeight: FontWeight.bold))),
                if (completedTasks > 0)
                  Positioned(
                      right: -10,
                      top: 40,
                      child: Text("Completed: ",
                          style: TextStyle(
                              color: Color(0xFF34A853),
                              fontWeight: FontWeight.bold))),
                if (pendingTasks > 0)
                  Positioned(
                      left: 10,
                      bottom: 10,
                      child: Text("Pending: ",
                          style: TextStyle(
                              color: Color(0xFFFFA500),
                              fontWeight: FontWeight.bold))),
              ],
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
  final int pendingTasks;
  final int totalTasks;

  PieChartPainter({
    required this.completedTasks,
    required this.inProgressTasks,
    required this.pendingTasks,
    required this.totalTasks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalTasks == 0) return;

    Rect rect = Offset.zero & size;
    Paint paint = Paint()..style = PaintingStyle.fill;
    Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2;

    double total = totalTasks.toDouble();
    double pendingRatio = pendingTasks / total;
    double inProgressRatio = inProgressTasks / total;
    double completedRatio = completedTasks / total;

    // Calculate angles in radians
    double pendingAngle = pendingRatio * 2 * pi;
    double inProgressAngle = inProgressRatio * 2 * pi;
    double completedAngle = completedRatio * 2 * pi;

    // Draw Pending - starts at -pi/2 (top)
    if (pendingTasks > 0) {
      canvas.drawArc(
          rect, -pi / 2, pendingAngle, true, paint..color = Color(0xFFFFA500));
      canvas.drawArc(rect, -pi / 2, pendingAngle, true, borderPaint);
    }

    // Draw In Progress - starts after pending
    if (inProgressTasks > 0) {
      canvas.drawArc(rect, -pi / 2 + pendingAngle, inProgressAngle, true,
          paint..color = Color(0xFF4285F4));
      canvas.drawArc(
          rect, -pi / 2 + pendingAngle, inProgressAngle, true, borderPaint);
    }

    // Draw Completed - starts after pending and in progress
    if (completedTasks > 0) {
      canvas.drawArc(rect, -pi / 2 + pendingAngle + inProgressAngle,
          completedAngle, true, paint..color = Color(0xFF34A853));
      canvas.drawArc(rect, -pi / 2 + pendingAngle + inProgressAngle,
          completedAngle, true, borderPaint);
    }

    // Draw percentage labels inside the pie slices
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double radius = size.width / 2 * 0.7;

    // Draw Pending label
    if (pendingTasks > 0) {
      double midAngle = -pi / 2 + pendingAngle / 2;
      double textX = centerX + radius * 0.6 * cos(midAngle);
      double textY = centerY + radius * 0.6 * sin(midAngle);
      TextPainter(
        text: TextSpan(
          text: _formatPercentage(pendingRatio),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(textX - 15, textY - 10));
    }

    // Draw In Progress label
    if (inProgressTasks > 0) {
      double midAngle = -pi / 2 + pendingAngle + inProgressAngle / 2;
      double textX = centerX + radius * 0.6 * cos(midAngle);
      double textY = centerY + radius * 0.6 * sin(midAngle);
      TextPainter(
        text: TextSpan(
          text: _formatPercentage(inProgressRatio),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(textX - 15, textY - 10));
    }

    // Draw Completed label
    if (completedTasks > 0) {
      double midAngle =
          -pi / 2 + pendingAngle + inProgressAngle + completedAngle / 2;
      double textX = centerX + radius * 0.6 * cos(midAngle);
      double textY = centerY + radius * 0.6 * sin(midAngle);
      TextPainter(
        text: TextSpan(
          text: _formatPercentage(completedRatio),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout()
        ..paint(canvas, Offset(textX - 15, textY - 10));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}