import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/overlap_segment.dart';
import '../models/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final bool isOverlapping;
  final List<OverlapSegment> overlapSegments;
  final Duration trackedDuration;
  final Duration lateTrackedDuration;
  final bool isTracking;
  final bool isCompleted;
  final VoidCallback onStart;
  final VoidCallback onStop;
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
    required this.onStart,
    required this.onStop,
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
    if (isCompleted) {
      return Colors.green.shade500;
    }

    if (task.duration.inSeconds == 0) {
      return Colors.green.shade400;
    }

    final planned = task.duration.inSeconds;
    final actual = trackedDuration.inSeconds;
    final ratio = actual / planned;

    if (ratio <= 1) {
      return Color.lerp(Colors.blue.shade100, Colors.green.shade400, ratio) ?? Colors.green.shade200;
    }

    final overRatio = math.min(ratio - 1, 1.0);
    return Color.lerp(Colors.green.shade400, Colors.red.shade400, overRatio) ?? Colors.red.shade400;
  }

  Color _resolveBorder() {
    final base = _resolveBackground();
    return isOverlapping ? Colors.red.shade400 : base.withOpacity(0.8);
  }

  @override
  Widget build(BuildContext context) {
    const unitHeight = 4.0;
    const minMinutes = 0.25;
    final plannedMinutes = task.duration.inMinutes.toDouble();
    final now = DateTime.now();
    final scheduledMinutes = math.max(task.scheduledDuration.inMinutes.toDouble(), minMinutes);
    final trackedMinutes = trackedDuration.inSeconds / 60.0;
    final trackedWithinScheduled = math.min(trackedMinutes, scheduledMinutes);
    final remainingMinutes = math.max(0.0, scheduledMinutes - trackedWithinScheduled);
    final overrunMinutes = math.max(0.0, trackedMinutes - scheduledMinutes);

    final isLate = task.startedLate;
    double redMinutes = isLate ? trackedWithinScheduled : 0.0;
    if (!isLate && !isTracking && !isCompleted) {
      redMinutes = 0.0;
    }
    double greenMinutes = !isLate ? trackedWithinScheduled : 0.0;
    if ((!isTracking && !isCompleted) || isLate) {
      greenMinutes = 0.0;
    }
    final futureMinutes = remainingMinutes;

    final height = (scheduledMinutes + overrunMinutes) * unitHeight;
    final scheduledHeight = scheduledMinutes * unitHeight;
    final redHeight = redMinutes * unitHeight;
    final greenHeight = greenMinutes * unitHeight;
    final futureHeight = futureMinutes * unitHeight;
    final overrunHeight = overrunMinutes * unitHeight;

    final filteredSegments = overlapSegments.where((segment) => segment.height > 0).toList();
    final backgroundColor = _resolveBackground();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: _resolveBorder()),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          children: [
            if (redHeight > 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: redHeight,
                child: Container(
                  color: Colors.red.withOpacity(0.25),
                ),
              ),
            if (greenHeight > 0)
              Positioned(
                top: redHeight,
                left: 0,
                right: 0,
                height: greenHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(isCompleted ? 0.5 : 0.25),
                  ),
                ),
              ),
            if (futureHeight > 0)
              Positioned(
                top: redHeight + greenHeight,
                left: 0,
                right: 0,
                height: futureHeight,
                child: Container(
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
            if (overrunHeight > 0)
              Positioned(
                top: scheduledHeight,
                left: 0,
                right: 0,
                height: overrunHeight,
                child: Container(
                  color: Colors.red.withOpacity(0.35),
                ),
              ),
            ...filteredSegments.map((segment) {
              final double overlayTop = math.max(0, math.min(segment.top, scheduledHeight));
              final double overlayHeight = math.max(0, math.min(segment.height, scheduledHeight - overlayTop));
              if (overlayHeight <= 0) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: overlayTop,
                left: 0,
                right: 0,
                height: overlayHeight,
                child: Container(
                  color: Colors.red.withOpacity(0.4),
                ),
              );
            }),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    alignment: Alignment.topLeft,
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(task.title, style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('${_formatTime(task.startTime)} · ${_formatDuration(task.duration)}'),
                          SizedBox(height: 4.0),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  _formatTracked(trackedDuration),
                                  style: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                                ),
                              ),
                              SizedBox(width: 12),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  icon: Icon(Icons.refresh, size: 18),
                                  color: Colors.white,
                                  onPressed: task.startTime.isAfter(DateTime.now()) ? null : onReset,
                                  tooltip: 'Reset Timer',
                                ),
                              ),
                              SizedBox(width: 8),
                              SizedBox(
                                height: 28,
                                width: 28,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  icon: Icon(isTracking ? Icons.stop : Icons.play_arrow, size: 18),
                                  color: Colors.white,
                                  onPressed: task.startTime.isAfter(DateTime.now())
                                      ? null
                                      : isTracking
                                          ? onStop
                                          : onStart,
                                  tooltip: isTracking ? 'Stop Tracking' : 'Start Tracking',
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
