import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/overlap_segment.dart';
import '../models/task.dart';

// Custom painter for diagonal stripes
class DiagonalStripesPainter extends CustomPainter {
  final Color backgroundColor;
  final Color stripeColor;
  final double stripeWidth;
  final double spacing;

  DiagonalStripesPainter({
    required this.backgroundColor,
    required this.stripeColor,
    this.stripeWidth = 2.0,
    this.spacing = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Paint diagonal stripes
    final stripePaint = Paint()
      ..color = stripeColor
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    final step = spacing + stripeWidth;
    
    for (double i = -diagonal; i < diagonal; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TaskItem extends StatelessWidget {
  final Task task;
  final bool isOverlapping;
  final List<OverlapSegment> overlapSegments;
  final Duration trackedDuration;
  final Duration lateTrackedDuration;
  final bool isTracking;
  final bool isCompleted;
  final bool isPastTask;
  final bool isFutureTask;
  final bool isCurrentTask;
  final VoidCallback onReset;
  final VoidCallback onComplete;

  const TaskItem({
    Key? key,
    required this.task,
    this.isOverlapping = false,
    this.overlapSegments = const [],
    required this.trackedDuration,
    required this.lateTrackedDuration,
    required this.isTracking,
    required this.isCompleted,
    this.isPastTask = false,
    this.isFutureTask = false,
    this.isCurrentTask = false,
    required this.onReset,
    required this.onComplete,
  }) : super(key: key);

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours hr ${minutes.toString().padLeft(2, '0')} min';
    }
    if (hours > 0) {
      return hours == 1 ? '1 hr' : '$hours hrs';
    }
    return '$minutes min';
  }

  String _formatTracked(Duration duration) {
    if (isCompleted) {
      return 'Completed';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _resolveBackground() {
    final now = DateTime.now();
    
    // Completed tasks are always green
    if (isCompleted) {
      return Colors.green.shade300;
    }
    
    // Tasks being tracked are green
    if (isTracking) {
      return Colors.green.shade300;
    }
    
    // Current task logic
    if (isCurrentTask) {
      // Current task is red if it has started but not being tracked
      if (now.isAfter(task.startTime) && !isTracking) {
        return Colors.red.shade300;
      }
      return Colors.blue.shade300;
    }
    
    // Past tasks that weren't completed or tracked are red
    if (isPastTask && !isCompleted) {
      return Colors.red.shade300;
    }
    
    // Default color for future tasks
    return Colors.blue.shade200;
  }

  Color _resolveBorder() {
    final base = _resolveBackground();
    return isOverlapping ? Colors.red.shade400 : base.withOpacity(0.8);
  }

  List<Widget> _buildColorSegments() {
    const unitHeight = 4.0;
    final now = DateTime.now();
    final taskStart = task.startTime;
    final taskEnd = taskStart.add(task.duration);
    final scheduledEnd = taskStart.add(task.scheduledDuration);
    
    List<Widget> segments = [];
    
    // If completed, entire task is green
    if (isCompleted) {
      return [
        Positioned.fill(
          child: Container(color: Colors.green.shade300),
        ),
      ];
    }
    
    // Sort tracking segments by start time
    final sortedSegments = [...task.trackingSegments]..sort((a, b) => a.start.compareTo(b.start));
    
    // Add current tracking segment if actively tracking
    List<TrackingSegment> allSegments = [...sortedSegments];
    if (isTracking && task.trackingStart != null) {
      allSegments.add(TrackingSegment(start: task.trackingStart!, end: now));
    }
    
    // First, paint the base layer based on time
    // Past (before now): red
    if (now.isAfter(taskStart)) {
      final pastEnd = now.isBefore(taskEnd) ? now : taskEnd;
      final topOffset = 0.0;
      final segHeight = pastEnd.difference(taskStart).inMilliseconds / 60000.0 * unitHeight;
      
      if (segHeight > 0) {
        segments.add(
          Positioned(
            top: topOffset,
            left: 0,
            right: 0,
            height: segHeight,
            child: Container(color: Colors.red.shade300),
          ),
        );
      }
    }
    
    // Future (after now): blue
    if (taskEnd.isAfter(now)) {
      final futureStart = taskStart.isAfter(now) ? taskStart : now;
      final topOffset = futureStart.difference(taskStart).inMilliseconds / 60000.0 * unitHeight;
      final segHeight = taskEnd.difference(futureStart).inMilliseconds / 60000.0 * unitHeight;
      
      if (segHeight > 0) {
        segments.add(
          Positioned(
            top: topOffset,
            left: 0,
            right: 0,
            height: segHeight,
            child: Container(color: Colors.blue.shade300),
          ),
        );
      }
    }
    
    // Now overlay green for all tracking segments
    for (final segment in allSegments) {
      final segStart = segment.start.isBefore(taskStart) ? taskStart : segment.start;
      final segEnd = segment.end.isAfter(taskEnd) ? taskEnd : segment.end;
      
      if (segEnd.isAfter(segStart)) {
        final topOffset = segStart.difference(taskStart).inMilliseconds / 60000.0 * unitHeight;
        final segHeight = segEnd.difference(segStart).inMilliseconds / 60000.0 * unitHeight;
        
        if (segHeight > 0) {
          segments.add(
            Positioned(
              top: topOffset,
              left: 0,
              right: 0,
              height: segHeight,
              child: Container(color: Colors.green.shade300),
            ),
          );
        }
      }
    }
    
    // Add overlap indicators on top
    for (final overlapSeg in overlapSegments) {
      if (overlapSeg.height > 0) {
        segments.add(
          Positioned(
            top: overlapSeg.top,
            left: 0,
            right: 0,
            height: overlapSeg.height,
            child: CustomPaint(
              painter: DiagonalStripesPainter(
                backgroundColor: Colors.blue.shade300,
                stripeColor: Colors.red.shade400,
                stripeWidth: 2.0,
                spacing: 6.0,
              ),
            ),
          ),
        );
      }
    }
    
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    const unitHeight = 4.0;
    const minMinutes = 0.25;
    final now = DateTime.now();
    final taskStart = task.startTime;
    final scheduledDuration = task.scheduledDuration;
    final scheduledMinutes = math.max(scheduledDuration.inMinutes.toDouble(), minMinutes);
    final scheduledHeight = scheduledMinutes * unitHeight;

    final height = scheduledHeight;

    final filteredSegments = overlapSegments.where((segment) => segment.height > 0).toList();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      height: height,
      decoration: BoxDecoration(
        color: Colors.blue.shade200, // Base color (will be covered by segments)
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: _resolveBorder()),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            // Color segments
            ..._buildColorSegments(),
            // Content overlay
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  if (task.isRecurring || task.recurringParentId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Icon(
                        Icons.repeat,
                        size: 16,
                        color: Colors.purple,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      '${task.title} · ${_formatTime(task.startTime)} · ${_formatDuration(task.duration)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 4),
                  SizedBox(
                    height: 28,
                    width: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      icon: Icon(Icons.refresh, size: 18),
                      color: Colors.white,
                      onPressed: onReset,
                      tooltip: 'Reset Task',
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    height: 28,
                    width: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      icon: Icon(Icons.check_circle, size: 18),
                      color: isCompleted ? Colors.white70 : Colors.white,
                      onPressed: () {
                        if (!isCompleted) {
                          onComplete();
                        }
                      },
                      tooltip: 'Mark Complete',
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
