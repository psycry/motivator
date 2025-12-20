import 'package:flutter/material.dart';
import '../models/task.dart';
import 'dart:math' as math;

class TimelineProgressIndicator extends StatelessWidget {
  final List<Task> tasks;
  final Task? currentTask;
  final VoidCallback onStartTracking;
  final VoidCallback onStopTracking;
  final DateTime startOfDay;
  final double pixelsPerMinute;

  const TimelineProgressIndicator({
    Key? key,
    required this.tasks,
    required this.currentTask,
    required this.onStartTracking,
    required this.onStopTracking,
    required this.startOfDay,
    required this.pixelsPerMinute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMinute = now.difference(startOfDay).inMinutes;
    final currentPosition = currentMinute * pixelsPerMinute;

    return Container(
      width: 50,
      height: 1440 * pixelsPerMinute, // Full day height
      child: Stack(
        children: [
          // Line representing the full timeline
          Positioned(
            left: 24,
            width: 2,
            top: 0,
            bottom: 0,
            child: Container(
              color: Colors.grey.shade300,
            ),
          ),

        // Past tasks (red if they're not completed and not tracked)
        ...tasks.where((task) =>
            !task.isCompleted &&
                !task.isTracking &&
                task.startTime.isBefore(now) // Task has started
            ).map((task) {
            final taskStart = task.startTime.difference(startOfDay).inMinutes * pixelsPerMinute;
            // For tasks that extend beyond current time, only show the past portion in red
            final taskEnd = math.min(
            taskStart + (task.duration.inMinutes * pixelsPerMinute),
            currentPosition
            );
            return Positioned(
            left: 24,
            width: 2,
            top: taskStart,
            height: taskEnd - taskStart,
            child: Container(
            color: Colors.red,
            ),
            );
            }),
          
          // Tracked tasks (green)
          ...tasks.where((task) => 
            task.isTracking
          ).map((task) {
            final taskStart = task.startTime.difference(startOfDay).inMinutes * pixelsPerMinute;
            final taskEnd = taskStart + (task.duration.inMinutes * pixelsPerMinute);
            return Positioned(
              left: 24,
              width: 2,
              top: taskStart,
              height: taskEnd - taskStart,
              child: Container(
                color: Colors.green,
              ),
            );
          }),
          
          // Current task (blue)
          if (currentTask != null)
            Positioned(
              left: 24,
              width: 2,
              top: currentTask!.startTime.difference(startOfDay).inMinutes * pixelsPerMinute,
              height: currentTask!.duration.inMinutes * pixelsPerMinute,
              child: Container(
                color: Colors.blue,
              ),
            ),
          
          // Current time indicator
          Positioned(
            left: 15,
            width: 20,
            top: currentPosition - 10,
            height: 20,
            child: GestureDetector(
              onTap: () {
                if (currentTask != null && currentTask!.isTracking) {
                  onStopTracking();
                } else {
                  onStartTracking();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: currentTask != null && currentTask!.isTracking ? Colors.red : Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentTask != null && currentTask!.isTracking ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
