import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/overlap_segment.dart';
import 'models/task.dart';
import 'widgets/task_item.dart';
import 'widgets/timeline_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Calendar List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: TaskCalendarPage(),
    );
  }
}

class TaskCalendarPage extends StatefulWidget {
  @override
  _TaskCalendarPageState createState() => _TaskCalendarPageState();
}

class _OverlapRange {
  final double start;
  final double end;

  const _OverlapRange(this.start, this.end);
}

class _TaskCalendarPageState extends State<TaskCalendarPage> {
  List<Task> timelineTasks = [
    Task(id: '1', title: 'Meeting', startTime: DateTime.now(), duration: Duration(hours: 1)),
    Task(id: '2', title: 'Project Work', startTime: DateTime.now().add(Duration(hours: 2)), duration: Duration(hours: 3)),
  ];

  List<Task> sideTasks = [
    Task(id: '3', title: 'Lunch Break', startTime: DateTime.now().add(Duration(hours: 6)), duration: Duration(minutes: 30)),
    Task(id: '4', title: 'Email Check', startTime: DateTime.now().add(Duration(hours: 7)), duration: Duration(minutes: 15)),
  ];

  static const double pixelsPerMinute = 4.0;
  final DateTime startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final GlobalKey _stackKey = GlobalKey();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onTick(Timer timer) {
    setState(() {
      final now = DateTime.now();
      for (final task in timelineTasks) {
        if (task.isTracking && task.trackingStart != null) {
          final currentTracked = task.trackedDuration + now.difference(task.trackingStart!);
          final lateSeconds = now.isAfter(task.startTime)
              ? math.max(0, now.difference(task.startTime).inSeconds - task.scheduledDuration.inSeconds)
              : 0;
          task.lateTrackedDuration = Duration(seconds: lateSeconds);
          final currentSeconds = currentTracked.inSeconds;
          final scheduledSeconds = task.scheduledDuration.inSeconds;
          if (currentSeconds > task.duration.inSeconds) {
            final nextSeconds = currentSeconds > scheduledSeconds ? currentSeconds : scheduledSeconds;
            task.duration = Duration(seconds: nextSeconds);
          }
        }
      }
    });
  }

  void _applyStartTracking(Task task, DateTime now, {bool allowListMove = true}) {
    if (allowListMove && sideTasks.contains(task)) {
      sideTasks.remove(task);
      if (!timelineTasks.contains(task)) {
        timelineTasks.add(task);
      }
    }
    task.trackingStart = now;
    task.isTracking = true;
    task.isCompleted = false;
    task.startedLate = now.isAfter(task.startTime);
    if (task.duration.inSeconds < task.scheduledDuration.inSeconds) {
      task.duration = task.scheduledDuration;
    }
    if (now.isAfter(task.startTime)) {
      final overdueSeconds = now.difference(task.startTime).inSeconds;
      task.lateTrackedDuration = Duration(seconds: overdueSeconds);
    } else {
      task.lateTrackedDuration = Duration.zero;
    }
  }

  void _applyStopTracking(Task task, DateTime now) {
    if (task.trackingStart != null) {
      task.trackedDuration += now.difference(task.trackingStart!);
    }
    task.trackingStart = null;
    task.isTracking = false;
    final trackedSeconds = task.trackedDuration.inSeconds;
    final scheduledSeconds = task.scheduledDuration.inSeconds;
    final nextSeconds = trackedSeconds > scheduledSeconds ? trackedSeconds : scheduledSeconds;
    task.duration = Duration(seconds: nextSeconds);
    if (now.isAfter(task.startTime)) {
      final overdueSeconds = now.difference(task.startTime).inSeconds;
      task.lateTrackedDuration = Duration(seconds: overdueSeconds);
    }
    task.startedLate = task.startedLate && task.lateTrackedDuration > Duration.zero;
  }

  Duration _currentTrackedDuration(Task task) {
    if (task.isTracking && task.trackingStart != null) {
      return task.trackedDuration + DateTime.now().difference(task.trackingStart!);
    }
    return task.trackedDuration;
  }

  void _startTracking(Task task) {
    final now = DateTime.now();
    setState(() {
      if (now.isAfter(task.startTime)) {
        final overdueSeconds = now.difference(task.startTime).inSeconds;
        if (overdueSeconds > task.trackedDuration.inSeconds) {
          final missingSeconds = overdueSeconds - task.trackedDuration.inSeconds;
          task.trackedDuration += Duration(seconds: missingSeconds);
        }
        final adjustedStart = now.subtract(task.trackedDuration);
        task.startTime = adjustedStart;
      }
      _applyStartTracking(task, now);
    });
  }

  void _stopTracking(Task task) {
    if (!task.isTracking) return;
    final now = DateTime.now();
    setState(() {
      _applyStopTracking(task, now);
    });
  }

  void _resetTracking(Task task) {
    setState(() {
      task.trackedDuration = Duration.zero;
      task.trackingStart = task.isTracking ? DateTime.now() : null;
      task.isCompleted = false;
      task.duration = task.scheduledDuration;
      task.lateTrackedDuration = Duration.zero;
      task.startedLate = false;
    });
  }

  void _markComplete(Task task) {
    setState(() {
      final now = DateTime.now();
      _applyStopTracking(task, now);
      task.trackedDuration = task.duration;
      task.isCompleted = true;
      task.lateTrackedDuration = Duration.zero;
      task.startedLate = false;
    });
  }

  bool _isOverlapping(Task task) {
    for (var other in timelineTasks) {
      if (other != task &&
          task.startTime.isBefore(other.startTime.add(other.duration)) &&
          other.startTime.isBefore(task.startTime.add(task.duration))) {
        return true;
      }
    }
    return false;
  }

  List<OverlapSegment> _getOverlapSegments(Task task) {
    final taskStart = task.startTime;
    final taskEnd = task.startTime.add(task.duration);
    final List<_OverlapRange> ranges = [];

    for (final other in timelineTasks) {
      if (other == task) continue;
      final otherStart = other.startTime;
      final otherEnd = other.startTime.add(other.duration);
      final overlapStart = taskStart.isAfter(otherStart) ? taskStart : otherStart;
      final overlapEnd = taskEnd.isBefore(otherEnd) ? taskEnd : otherEnd;

      if (overlapEnd.isAfter(overlapStart)) {
        final startMinutes = overlapStart.difference(taskStart).inMinutes.toDouble();
        final endMinutes = overlapEnd.difference(taskStart).inMinutes.toDouble();
        ranges.add(_OverlapRange(startMinutes, endMinutes));
      }
    }

    if (ranges.isEmpty) {
      return const [];
    }

    ranges.sort((a, b) => a.start.compareTo(b.start));
    final List<_OverlapRange> merged = [];
    for (final range in ranges) {
      if (merged.isEmpty || range.start > merged.last.end) {
        merged.add(range);
      } else {
        final last = merged.last;
        merged[merged.length - 1] = _OverlapRange(last.start, range.end > last.end ? range.end : last.end);
      }
    }

    return merged
        .map(
          (range) => OverlapSegment(
            top: range.start * pixelsPerMinute,
            height: (range.end - range.start) * pixelsPerMinute,
          ),
        )
        .toList();
  }

  void _showEditDialog(BuildContext context, Task task) {
    final titleController = TextEditingController(text: task.title);
    final initialHour24 = task.startTime.hour;
    final initialHour12 = initialHour24 % 12 == 0 ? 12 : initialHour24 % 12;
    String selectedPeriod = initialHour24 >= 12 ? 'PM' : 'AM';

    final hourController = TextEditingController(text: initialHour12.toString());
    final minuteController = TextEditingController(text: task.startTime.minute.toString());
    final durationHours = task.duration.inMinutes ~/ 60;
    final durationMinutes = task.duration.inMinutes % 60;
    final durationHourController = TextEditingController(text: durationHours.toString());
    final durationMinuteController = TextEditingController(text: durationMinutes.toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hourController,
                          decoration: InputDecoration(labelText: 'Start Hour'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: minuteController,
                          decoration: InputDecoration(labelText: 'Start Minute'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedPeriod,
                        items: const [
                          DropdownMenuItem(value: 'AM', child: Text('AM')),
                          DropdownMenuItem(value: 'PM', child: Text('PM')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedPeriod = value);
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: durationHourController,
                          decoration: InputDecoration(labelText: 'Duration Hours'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: durationMinuteController,
                          decoration: InputDecoration(labelText: 'Duration Minutes'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      task.title = titleController.text;

                      int parsedHour = int.tryParse(hourController.text) ?? initialHour12;
                      parsedHour = parsedHour.clamp(1, 12);
                      if (selectedPeriod == 'AM') {
                        parsedHour = parsedHour % 12;
                      } else {
                        parsedHour = parsedHour % 12 + 12;
                      }

                      final parsedMinute = (int.tryParse(minuteController.text) ?? task.startTime.minute).clamp(0, 59);

                      task.startTime = DateTime(
                        startOfDay.year,
                        startOfDay.month,
                        startOfDay.day,
                        parsedHour,
                        parsedMinute,
                      );

                      final parsedDurationHours = (int.tryParse(durationHourController.text) ?? durationHours).clamp(0, 24 * 7);
                      final parsedDurationMinutes = (int.tryParse(durationMinuteController.text) ?? durationMinutes).clamp(0, 59);
                      final totalDurationMinutes = parsedDurationHours * 60 + parsedDurationMinutes;
                      final clampedDuration = totalDurationMinutes.clamp(1, 24 * 60);
                      final newDuration = Duration(minutes: clampedDuration);

                      if (task.duration != newDuration) {
                        task.duration = newDuration;
                        task.scheduledDuration = newDuration;
                        task.trackedDuration = Duration.zero;
                        task.trackingStart = task.isTracking ? DateTime.now() : null;
                        task.isCompleted = false;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Calendar List'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Stack(
                key: _stackKey,
                children: [
                  TimelineWidget(pixelsPerMinute: pixelsPerMinute),
                  DragTarget<Task>(
                    builder: (context, candidateData, rejectedData) {
                      return Container(
                        height: 1440 * pixelsPerMinute,
                        width: double.infinity,
                      );
                    },
                    onAcceptWithDetails: (DragTargetDetails<Task> details) {
                      final RenderBox? stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
                      if (stackBox != null) {
                        final localPosition = stackBox.globalToLocal(details.offset);
                        final newStartMinute = (localPosition.dy / pixelsPerMinute).floor().clamp(0, 1439);
                        final newStartTime = startOfDay.add(Duration(minutes: newStartMinute));
                        setState(() {
                          if (details.data.isTracking || details.data.trackingStart != null) {
                            _applyStopTracking(details.data, DateTime.now());
                          }
                          if (sideTasks.contains(details.data)) {
                            sideTasks.remove(details.data);
                            details.data.startTime = newStartTime;
                            timelineTasks.add(details.data);
                          } else if (timelineTasks.contains(details.data)) {
                            // Dragging within timeline, update time
                            details.data.startTime = newStartTime;
                          }
                        });
                      }
                    },
                  ),
                  ...timelineTasks.map((task) {
                    final isOverlapping = _isOverlapping(task);
                    final overlapSegments = _getOverlapSegments(task);
                    final top = task.startTime.difference(startOfDay).inMinutes * pixelsPerMinute;
                    final height = task.duration.inMinutes * pixelsPerMinute;
                    return Positioned(
                      top: top,
                      left: 60,
                      right: 0,
                      height: height,
                      child: Draggable<Task>(
                        data: task,
                        feedback: Material(
                          child: TaskItem(
                            task: task,
                            isOverlapping: isOverlapping,
                            overlapSegments: overlapSegments,
                            trackedDuration: _currentTrackedDuration(task),
                            lateTrackedDuration: task.lateTrackedDuration,
                            isTracking: task.isTracking,
                            isCompleted: task.isCompleted,
                            onStart: () => _startTracking(task),
                            onStop: () => _stopTracking(task),
                            onReset: () => _resetTracking(task),
                            onComplete: () => _markComplete(task),
                          ),
                          elevation: 4.0,
                        ),
                        childWhenDragging: Container(),
                        child: GestureDetector(
                          onTap: () => _showEditDialog(context, task),
                          child: TaskItem(
                            task: task,
                            isOverlapping: isOverlapping,
                            overlapSegments: overlapSegments,
                            trackedDuration: _currentTrackedDuration(task),
                            lateTrackedDuration: task.lateTrackedDuration,
                            isTracking: task.isTracking,
                            isCompleted: task.isCompleted,
                            onStart: () => _startTracking(task),
                            onStop: () => _stopTracking(task),
                            onReset: () => _resetTracking(task),
                            onComplete: () => _markComplete(task),
                          ),
                        ),
                      ),
                    );
                  }),
                  Positioned(
                    left: 60,
                    right: 0,
                    top: DateTime.now().difference(startOfDay).inMinutes * pixelsPerMinute,
                    height: 2,
                    child: Container(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: DragTarget<Task>(
              builder: (context, candidateData, rejectedData) {
                return ReorderableListView(
                  onReorder: (int oldIndex, int newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final Task item = sideTasks.removeAt(oldIndex);
                      if (item.isTracking || item.trackingStart != null) {
                        _applyStopTracking(item, DateTime.now());
                      }
                      sideTasks.insert(newIndex, item);
                    });
                  },
                  children: sideTasks.map((task) {
                    return Draggable<Task>(
                      key: ValueKey(task.id),
                      data: task,
                      feedback: Material(
                        child: TaskItem(
                          task: task,
                          trackedDuration: _currentTrackedDuration(task),
                            lateTrackedDuration: task.lateTrackedDuration,
                          isTracking: task.isTracking,
                          isCompleted: task.isCompleted,
                          onStart: () => _startTracking(task),
                          onStop: () => _stopTracking(task),
                          onReset: () => _resetTracking(task),
                          onComplete: () => _markComplete(task),
                        ),
                        elevation: 4.0,
                      ),
                      childWhenDragging: Container(),
                      child: GestureDetector(
                        onTap: () => _showEditDialog(context, task),
                        child: TaskItem(
                          task: task,
                          trackedDuration: _currentTrackedDuration(task),
                            lateTrackedDuration: task.lateTrackedDuration,
                          isTracking: task.isTracking,
                          isCompleted: task.isCompleted,
                          onStart: () => _startTracking(task),
                          onStop: () => _stopTracking(task),
                          onReset: () => _resetTracking(task),
                          onComplete: () => _markComplete(task),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              onAccept: (Task task) {
                setState(() {
                  if (task.isTracking || task.trackingStart != null) {
                    _applyStopTracking(task, DateTime.now());
                  }
                  timelineTasks.remove(task);
                  sideTasks.add(task);
                  task.duration = task.scheduledDuration;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
