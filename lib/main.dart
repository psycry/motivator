import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/overlap_segment.dart';
import 'models/task.dart';
import 'widgets/task_item.dart';
import 'widgets/timeline_widget.dart';
import 'widgets/timeline_progress_indicator.dart';

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
    // Test task that started 30 minutes ago and runs for 2 hours (spans current time)
    Task(id: '5', title: 'Design Review', startTime: DateTime.now().subtract(Duration(minutes: 30)), duration: Duration(hours: 2)),
    // Test task that started 1 hour ago and runs for 30 minutes (completely in the past)
    Task(id: '6', title: 'Quick Standup', startTime: DateTime.now().subtract(Duration(hours: 1)), duration: Duration(minutes: 30)),
    // Test task that starts in 1 hour and runs for 2 hours (completely in the future)
    Task(id: '7', title: 'Future Planning', startTime: DateTime.now().add(Duration(hours: 1)), duration: Duration(hours: 2)),
  ];

  List<Task> sideTasks = [
    Task(id: '3', title: 'Lunch Break', startTime: DateTime.now().add(Duration(hours: 6)), duration: Duration(minutes: 30)),
    Task(id: '4', title: 'Email Check', startTime: DateTime.now().add(Duration(hours: 7)), duration: Duration(minutes: 15)),
  ];

  static const double pixelsPerMinute = 4.0;
  final DateTime startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final GlobalKey _stackKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  Timer? _timer;
  Task? currentTask;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), _onTick);
    
    // Center the scroll on the current time after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnCurrentTime();
    });
  }

  void _centerOnCurrentTime() {
    final now = DateTime.now();
    final minutesSinceStartOfDay = now.difference(startOfDay).inMinutes;
    final currentTimePosition = minutesSinceStartOfDay * pixelsPerMinute;
    
    // Get the viewport height to center properly
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetScroll = currentTimePosition - (viewportHeight / 2);
    
    // Clamp to valid scroll range
    final maxScroll = _scrollController.position.maxScrollExtent;
    final scrollTo = targetScroll.clamp(0.0, maxScroll);
    
    _scrollController.jumpTo(scrollTo);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTick(Timer timer) {
    setState(() {
      final now = DateTime.now();
      
      // Find the current task based on the current time
      Task? newCurrentTask;
      for (final task in timelineTasks) {
        final taskStart = task.startTime;
        final taskEnd = taskStart.add(task.duration);
        
        if (now.isAfter(taskStart) && now.isBefore(taskEnd) && !task.isCompleted) {
          newCurrentTask = task;
          break;
        }
      }
      
      // Update current task if it has changed
      if (newCurrentTask != currentTask) {
        if (currentTask != null && currentTask!.isTracking) {
          _applyStopTracking(currentTask!, now);
        }
        currentTask = newCurrentTask;
      }
      
      // Update tracking durations for all tasks
      for (final task in timelineTasks) {
        if (task.isTracking && task.trackingStart != null) {
          final scheduledEnd = task.startTime.add(task.duration);
          if (now.isAfter(scheduledEnd)) {
            task.startTime = now;
          }
          final lateSeconds = now.isAfter(task.startTime)
              ? math.max(0, now.difference(task.startTime).inSeconds - task.scheduledDuration.inSeconds)
              : 0;
          task.lateTrackedDuration = Duration(seconds: lateSeconds);
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
      // Record the tracking segment
      task.trackingSegments.add(TrackingSegment(
        start: task.trackingStart!,
        end: now,
      ));
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

  void _startCurrentTask() {
    final now = DateTime.now();
    setState(() {
      if (currentTask != null) {
        _applyStartTracking(currentTask!, now);
      } else {
        // Find the next upcoming task if no current task
        Task? nextTask = _findNextUpcomingTask();
        if (nextTask != null) {
          // If the next task is in the future, adjust its start time to now
          if (nextTask.startTime.isAfter(now)) {
            nextTask.startTime = now;
          }
          currentTask = nextTask;
          _applyStartTracking(currentTask!, now);
        }
      }
    });
  }

  void _stopCurrentTask() {
    if (currentTask != null && currentTask!.isTracking) {
      final now = DateTime.now();
      setState(() {
        _applyStopTracking(currentTask!, now);
      });
    }
  }

  Task? _findNextUpcomingTask() {
    final now = DateTime.now();
    Task? nextTask;
    DateTime? nextStartTime;
    
    for (final task in timelineTasks) {
      if (!task.isCompleted && task.startTime.isAfter(now)) {
        if (nextStartTime == null || task.startTime.isBefore(nextStartTime)) {
          nextTask = task;
          nextStartTime = task.startTime;
        }
      }
    }
    
    return nextTask;
  }

  void _startTracking(Task task) {
    final now = DateTime.now();
    setState(() {
      final scheduledEnd = task.startTime.add(task.duration);
      if (now.isAfter(scheduledEnd)) {
        task.startTime = now;
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

  void _resetTask(Task task) {
    setState(() {
      final now = DateTime.now();
      
      // Stop tracking if active
      task.isTracking = false;
      task.trackingStart = null;
      
      // Reset all tracking data
      task.trackedDuration = Duration.zero;
      task.isCompleted = false;
      task.duration = task.scheduledDuration;
      task.lateTrackedDuration = Duration.zero;
      task.startedLate = false;
      
      // Clear tracking segments - create new list to ensure rebuild
      task.trackingSegments = [];
      
      // Update start time to ensure task shows as blue (future)
      if (timelineTasks.contains(task)) {
        // Timeline tasks: start 1 second in the future
        task.startTime = now.add(Duration(seconds: 1));
      } else if (sideTasks.contains(task)) {
        // Side pane tasks: also set to future time so they show as blue
        task.startTime = now.add(Duration(hours: 1));
      }
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
      // When completed, fill the entire task duration as a tracking segment
      if (task.trackingSegments.isEmpty) {
        task.trackingSegments.add(TrackingSegment(
          start: task.startTime,
          end: task.startTime.add(task.duration),
        ));
      }
      
      // Move from side tasks to timeline tasks if needed
      if (sideTasks.contains(task)) {
        sideTasks.remove(task);
        if (!timelineTasks.contains(task)) {
          timelineTasks.add(task);
        }
      }
    });
  }

  void _uncompleteTask(Task task) {
    setState(() {
      task.isCompleted = false;
      task.trackedDuration = Duration.zero;
      task.lateTrackedDuration = Duration.zero;
      task.startedLate = false;
      task.trackingSegments.clear();
      task.duration = task.scheduledDuration;
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

  bool _isTaskPast(Task task) {
    final now = DateTime.now();
    // A task is past if:
    // 1. It has completely ended and is not completed/tracking, OR
    // 2. It has started but was never tracked and is not currently tracking
    final hasEnded = task.startTime.add(task.duration).isBefore(now);
    final hasStarted = task.startTime.isBefore(now);
    final wasNeverTracked = task.trackedDuration == Duration.zero && !task.isTracking;
    
    return !task.isCompleted && ((hasEnded && !task.isTracking) || (hasStarted && wasNeverTracked));
  }

  bool _isTaskFuture(Task task) {
    final now = DateTime.now();
    return task.startTime.isAfter(now);
  }

  bool _isTaskCurrent(Task task) {
    return task == currentTask && !task.isCompleted;
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

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final hourController = TextEditingController(text: '12');
    final minuteController = TextEditingController(text: '0');
    String selectedPeriod = 'PM';
    final durationHourController = TextEditingController(text: '1');
    final durationMinuteController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Create New Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                    autofocus: true,
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
                    if (titleController.text.isEmpty) return;
                    
                    setState(() {
                      int parsedHour = int.tryParse(hourController.text) ?? 12;
                      parsedHour = parsedHour.clamp(1, 12);
                      if (selectedPeriod == 'AM') {
                        parsedHour = parsedHour % 12;
                      } else {
                        parsedHour = parsedHour % 12 + 12;
                      }

                      final parsedMinute = (int.tryParse(minuteController.text) ?? 0).clamp(0, 59);

                      final startTime = DateTime(
                        startOfDay.year,
                        startOfDay.month,
                        startOfDay.day,
                        parsedHour,
                        parsedMinute,
                      );

                      final parsedDurationHours = (int.tryParse(durationHourController.text) ?? 1).clamp(0, 24 * 7);
                      final parsedDurationMinutes = (int.tryParse(durationMinuteController.text) ?? 0).clamp(0, 59);
                      final totalDurationMinutes = parsedDurationHours * 60 + parsedDurationMinutes;
                      final clampedDuration = totalDurationMinutes.clamp(1, 24 * 60);
                      final duration = Duration(minutes: clampedDuration);

                      final newTask = Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        startTime: startTime,
                        duration: duration,
                      );

                      sideTasks.add(newTask);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
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
    final sortedTimelineTasks = [...timelineTasks]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Separate completed and active tasks
    final activeTasks = sortedTimelineTasks.where((task) => !task.isCompleted).toList();
    final completedTasks = sortedTimelineTasks.where((task) => task.isCompleted).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Calendar List'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Timeline section
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Stack(
                      key: _stackKey,
                      children: [
                        TimelineWidget(pixelsPerMinute: pixelsPerMinute),
                        TimelineProgressIndicator(
                          tasks: activeTasks,
                          currentTask: currentTask,
                          onStartTracking: _startCurrentTask,
                          onStopTracking: _stopCurrentTask,
                          startOfDay: startOfDay,
                          pixelsPerMinute: pixelsPerMinute,
                        ),
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
                          // If task is completed, uncomplete it
                          if (details.data.isCompleted) {
                            _uncompleteTask(details.data);
                          }
                          
                          if (sideTasks.contains(details.data)) {
                            sideTasks.remove(details.data);
                            details.data.startTime = newStartTime;
                            timelineTasks.add(details.data);
                          } else if (timelineTasks.contains(details.data)) {
                            // Dragging within timeline, update time
                            details.data.startTime = newStartTime;
                          } else {
                            // Dragging from completed area
                            details.data.startTime = newStartTime;
                            timelineTasks.add(details.data);
                          }
                        });
                      }
                    },
                  ),
                  ...activeTasks.map((task) {
                    final isOverlapping = _isOverlapping(task);
                    final overlapSegments = _getOverlapSegments(task);
                    final top = task.startTime.difference(startOfDay).inMinutes * pixelsPerMinute;
                    final height = task.duration.inMinutes * pixelsPerMinute;
                    return Positioned(
                      top: top,
                      left: 60,
                      right: 60, // Make space for the timeline progress indicator
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
                            isPastTask: _isTaskPast(task),
                            isFutureTask: _isTaskFuture(task),
                            isCurrentTask: _isTaskCurrent(task),
                            onReset: () => _resetTask(task),
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
                            isPastTask: _isTaskPast(task),
                            isFutureTask: _isTaskFuture(task),
                            isCurrentTask: _isTaskCurrent(task),
                            onReset: () => _resetTask(task),
                            onComplete: () => _markComplete(task),
                          ),
                        ),
                      ),
                    );
                  }),
                  Positioned(
                    left: 60,
                    right: 60, // Make space for the timeline progress indicator
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
                // Completed tasks section
                DragTarget<Task>(
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 2)),
                        color: candidateData.isNotEmpty ? Colors.green.shade100 : Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Completed Tasks (${completedTasks.length})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: completedTasks.length,
                              itemBuilder: (context, index) {
                                final task = completedTasks[index];
                                return Draggable<Task>(
                                  data: task,
                                  feedback: Material(
                                    child: Container(
                                      width: 300,
                                      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      child: TaskItem(
                                        task: task,
                                        trackedDuration: _currentTrackedDuration(task),
                                        lateTrackedDuration: task.lateTrackedDuration,
                                        isTracking: task.isTracking,
                                        isCompleted: task.isCompleted,
                                        isPastTask: _isTaskPast(task),
                                        isFutureTask: _isTaskFuture(task),
                                        isCurrentTask: _isTaskCurrent(task),
                                        onReset: () => _resetTask(task),
                                        onComplete: () => _markComplete(task),
                                      ),
                                    ),
                                    elevation: 4.0,
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      child: TaskItem(
                                        task: task,
                                        trackedDuration: _currentTrackedDuration(task),
                                        lateTrackedDuration: task.lateTrackedDuration,
                                        isTracking: task.isTracking,
                                        isCompleted: task.isCompleted,
                                        isPastTask: _isTaskPast(task),
                                        isFutureTask: _isTaskFuture(task),
                                        isCurrentTask: _isTaskCurrent(task),
                                        onReset: () => _resetTask(task),
                                        onComplete: () => _markComplete(task),
                                      ),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _showEditDialog(context, task),
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      child: TaskItem(
                                        task: task,
                                        trackedDuration: _currentTrackedDuration(task),
                                        lateTrackedDuration: task.lateTrackedDuration,
                                        isTracking: task.isTracking,
                                        isCompleted: task.isCompleted,
                                        isPastTask: _isTaskPast(task),
                                        isFutureTask: _isTaskFuture(task),
                                        isCurrentTask: _isTaskCurrent(task),
                                        onReset: () => _resetTask(task),
                                        onComplete: () => _markComplete(task),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  onAccept: (Task task) {
                    setState(() {
                      // Remove from side tasks if it's there
                      if (sideTasks.contains(task)) {
                        sideTasks.remove(task);
                      }
                      // Ensure it's in timeline tasks before marking complete
                      if (!timelineTasks.contains(task)) {
                        timelineTasks.add(task);
                      }
                      _markComplete(task);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Button section
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateTaskDialog(context),
                          icon: Icon(Icons.add),
                          label: Text('Create Task'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (currentTask != null && currentTask!.isTracking) {
                              _stopCurrentTask();
                            } else {
                              _startCurrentTask();
                            }
                          },
                          icon: Icon(
                            currentTask != null && currentTask!.isTracking 
                                ? Icons.pause 
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            currentTask != null && currentTask!.isTracking 
                                ? 'Stop Work' 
                                : 'Start Work',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: currentTask != null && currentTask!.isTracking 
                                ? Colors.orange 
                                : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Task list section
                Expanded(
                  child: DragTarget<Task>(
                    builder: (context, candidateData, rejectedData) {
                      return ListView.builder(
                        itemCount: sideTasks.length,
                        itemBuilder: (context, index) {
                          final task = sideTasks[index];
                          return Draggable<Task>(
                            data: task,
                            feedback: Material(
                              child: Container(
                                width: 300,
                                child: TaskItem(
                                  task: task,
                                  trackedDuration: _currentTrackedDuration(task),
                                  lateTrackedDuration: task.lateTrackedDuration,
                                  isTracking: task.isTracking,
                                  isCompleted: task.isCompleted,
                                  isPastTask: _isTaskPast(task),
                                  isFutureTask: _isTaskFuture(task),
                                  isCurrentTask: _isTaskCurrent(task),
                                  onReset: () => _resetTask(task),
                                  onComplete: () => _markComplete(task),
                                ),
                              ),
                              elevation: 4.0,
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: TaskItem(
                                task: task,
                                trackedDuration: _currentTrackedDuration(task),
                                lateTrackedDuration: task.lateTrackedDuration,
                                isTracking: task.isTracking,
                                isCompleted: task.isCompleted,
                                isPastTask: _isTaskPast(task),
                                isFutureTask: _isTaskFuture(task),
                                isCurrentTask: _isTaskCurrent(task),
                                onReset: () => _resetTask(task),
                                onComplete: () => _markComplete(task),
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () => _showEditDialog(context, task),
                              child: TaskItem(
                                task: task,
                                trackedDuration: _currentTrackedDuration(task),
                                lateTrackedDuration: task.lateTrackedDuration,
                                isTracking: task.isTracking,
                                isCompleted: task.isCompleted,
                                isPastTask: _isTaskPast(task),
                                isFutureTask: _isTaskFuture(task),
                                isCurrentTask: _isTaskCurrent(task),
                                onReset: () => _resetTask(task),
                                onComplete: () => _markComplete(task),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    onAccept: (Task task) {
                      setState(() {
                        // If task is completed, uncomplete it
                        if (task.isCompleted) {
                          _uncompleteTask(task);
                        }
                        
                        timelineTasks.remove(task);
                        if (!sideTasks.contains(task)) {
                          sideTasks.add(task);
                        }
                        task.duration = task.scheduledDuration;
                      });
                    },
                  ),
                ),
                // Completed tasks summary section
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300, width: 2)),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Completed (${completedTasks.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: completedTasks.length,
                          itemBuilder: (context, index) {
                            final task = completedTasks[index];
                            return InkWell(
                              onTap: () => _showEditDialog(context, task),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${task.title} · ${_formatTime(task.startTime)} · ${_formatDuration(task.duration)}',
                                        style: TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

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
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return hours == 1 ? '1h' : '${hours}h';
    }
    return '${minutes}m';
  }
}


