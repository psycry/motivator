import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'models/overlap_segment.dart';
import 'models/task.dart';
import 'widgets/task_item.dart';
import 'widgets/timeline_widget.dart';
import 'widgets/timeline_progress_indicator.dart';
import 'widgets/calendar_dialog.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    print('App will run without Firebase backend');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Calendar List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: const TaskCalendarPage(),
    );
  }
}

class TaskCalendarPage extends StatefulWidget {
  const TaskCalendarPage({super.key});

  @override
  _TaskCalendarPageState createState() => _TaskCalendarPageState();
}

class _OverlapRange {
  final double start;
  final double end;

  const _OverlapRange(this.start, this.end);
}

class _TaskCalendarPageState extends State<TaskCalendarPage> {
  // Constants
  static const double pixelsPerMinute = 4.0;
  static const int minutesPerDay = 1440;
  static const double timelineLeftPadding = 60.0;
  static const double timelineRightPadding = 60.0;
  static const double completedTasksSectionHeight = 200.0;
  static const double completedTasksSummarySectionHeight = 150.0;
  static const double dragFeedbackWidth = 300.0;

  // Multi-day task storage: Map of normalized date to tasks
  Map<DateTime, List<Task>> tasksByDate = {};
  late DateTime selectedDate;
  late DateTime startOfDay;
  
  List<Task> get timelineTasks => tasksByDate[_normalizeDate(selectedDate)] ?? [];
  set timelineTasks(List<Task> tasks) {
    tasksByDate[_normalizeDate(selectedDate)] = tasks;
    _saveTasksToFirebase();
  }
  
  List<Task> sideTasks = [];
  final GlobalKey _stackKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  Timer? _timer;
  Task? currentTask;
  
  late FirebaseService _firebaseService;
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    startOfDay = _normalizeDate(selectedDate);
    
    // Initialize authentication and Firebase service
    _initializeAuth();
    
    _timer = Timer.periodic(Duration(seconds: 1), _onTick);
    
    // Center the scroll on the current time after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnCurrentTime();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      // Check if user is already signed in
      if (!_authService.isSignedIn()) {
        // Sign in anonymously for now
        await _authService.signInAnonymously();
        print('Signed in anonymously: ${_authService.currentUserId}');
      } else {
        print('Already signed in: ${_authService.currentUserId}');
      }
      
      // Initialize Firebase service with authenticated user ID
      _firebaseService = FirebaseService(userId: _authService.currentUserId ?? 'default_user');
      
      // Load tasks from Firebase
      await _loadTasksFromFirebase();
    } catch (e) {
      print('Error initializing auth: $e');
      // Fallback to default user
      _firebaseService = FirebaseService(userId: 'default_user');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTasksFromFirebase() async {
    try {
      // Add timeout to prevent infinite loading
      final loadedTasks = await _firebaseService.loadAllTasks()
          .timeout(const Duration(seconds: 5));
      final loadedSideTasks = await _firebaseService.loadSideTasks()
          .timeout(const Duration(seconds: 5));
      
      setState(() {
        tasksByDate = loadedTasks;
        sideTasks = loadedSideTasks;
        _isLoading = false;
      });
      
      print('Tasks loaded from Firebase successfully');
      print('Loaded ${tasksByDate.length} date(s) with tasks, ${sideTasks.length} side tasks');
    } catch (e) {
      print('Error loading tasks from Firebase: $e');
      print('Starting with empty task list');
      
      // Start with empty tasks - don't initialize sample tasks
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeSampleTasks() {
    final now = DateTime.now();
    final todayNormalized = _normalizeDate(now);
    
    tasksByDate[todayNormalized] = [
      Task(id: '1', title: 'Meeting', startTime: now, duration: Duration(hours: 1)),
      Task(id: '2', title: 'Project Work', startTime: now.add(Duration(hours: 2)), duration: Duration(hours: 3)),
      Task(id: '5', title: 'Design Review', startTime: now.subtract(Duration(minutes: 30)), duration: Duration(hours: 2)),
      Task(id: '6', title: 'Quick Standup', startTime: now.subtract(Duration(hours: 1)), duration: Duration(minutes: 30)),
      Task(id: '7', title: 'Future Planning', startTime: now.add(Duration(hours: 1)), duration: Duration(hours: 2)),
    ];
    
    sideTasks = [
      Task(id: '3', title: 'Lunch Break', startTime: now.add(Duration(hours: 6)), duration: Duration(minutes: 30)),
      Task(id: '4', title: 'Email Check', startTime: now.add(Duration(hours: 7)), duration: Duration(minutes: 15)),
    ];
    
    // Save sample tasks to Firebase
    _saveTasksToFirebase();
    _saveSideTasksToFirebase();
  }

  Future<void> _saveTasksToFirebase() async {
    try {
      await _firebaseService.saveTasksForDate(selectedDate, timelineTasks)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      // Silently fail - app works without Firebase
      print('Could not save to Firebase: $e');
    }
  }

  Future<void> _saveSideTasksToFirebase() async {
    try {
      await _firebaseService.saveSideTasks(sideTasks)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      // Silently fail - app works without Firebase
      print('Could not save side tasks to Firebase: $e');
    }
  }

  void _centerOnCurrentTime() {
    // Check if scroll controller is attached
    if (!_scrollController.hasClients) {
      return;
    }
    
    final now = DateTime.now();
    final minutesSinceStartOfDay = now.difference(startOfDay).inMinutes;
    final currentTimePosition = minutesSinceStartOfDay * pixelsPerMinute;
    
    // Get the viewport height to center properly
    final viewportHeight = _scrollController.position.viewportDimension;
    final targetScroll = currentTimePosition - (viewportHeight / 2);
    
    // Clamp to valid scroll range
    final maxScroll = _scrollController.position.maxScrollExtent;
    final minScroll = _scrollController.position.minScrollExtent;
    final clampedScroll = targetScroll.clamp(minScroll, maxScroll);
    
    _scrollController.jumpTo(clampedScroll);
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
        final dateKey = _normalizeDate(selectedDate);
        if (!tasksByDate.containsKey(dateKey)) {
          tasksByDate[dateKey] = [];
        }
        tasksByDate[dateKey]!.add(task);
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
    _saveTasksToFirebase();
    _saveSideTasksToFirebase();
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
          final dateKey = _normalizeDate(selectedDate);
          if (!tasksByDate.containsKey(dateKey)) {
            tasksByDate[dateKey] = [];
          }
          tasksByDate[dateKey]!.add(task);
        }
      }
    });
    _saveTasksToFirebase();
    _saveSideTasksToFirebase();
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
    _saveTasksToFirebase();
  }

  Future<void> _clearAllTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Tasks'),
        content: const Text(
          'This will permanently delete all tasks from all dates and the side panel. This action cannot be undone.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        tasksByDate.clear();
        sideTasks.clear();
        currentTask = null;
      });
      
      // Clear from Firebase
      try {
        await _firebaseService.clearAllTasks();
        print('All tasks cleared successfully');
      } catch (e) {
        print('Error clearing tasks from Firebase: $e');
      }
    }
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
              title: const Text('Create New Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
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
                  child: const Text('Create'),
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
              title: const Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
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
                  child: const Text('Save'),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task Calendar List'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final sortedTimelineTasks = [...timelineTasks]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Separate completed and active tasks
    final activeTasks = sortedTimelineTasks.where((task) => !task.isCompleted).toList();
    final completedTasks = sortedTimelineTasks.where((task) => task.isCompleted).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Calendar List'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearAllTasks();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Tasks'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Weekday selector section
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _showCalendarBottomSheet(context),
                            icon: const Icon(Icons.calendar_month),
                            tooltip: 'Open Calendar',
                            color: Colors.purple,
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                selectedDate = selectedDate.subtract(const Duration(days: 7));
                                startOfDay = _normalizeDate(selectedDate);
                                currentTask = null;
                                if (!tasksByDate.containsKey(_normalizeDate(selectedDate))) {
                                  tasksByDate[_normalizeDate(selectedDate)] = [];
                                }
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _centerOnCurrentTime();
                              });
                            },
                            icon: const Icon(Icons.chevron_left),
                            tooltip: 'Previous Week',
                          ),
                          Expanded(
                            child: Text(
                              _getWeekRangeText(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                selectedDate = selectedDate.add(const Duration(days: 7));
                                startOfDay = _normalizeDate(selectedDate);
                                currentTask = null;
                                if (!tasksByDate.containsKey(_normalizeDate(selectedDate))) {
                                  tasksByDate[_normalizeDate(selectedDate)] = [];
                                }
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _centerOnCurrentTime();
                              });
                            },
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Next Week',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _buildWeekdayButtons(),
                      ),
                    ],
                  ),
                ),
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
                        height: minutesPerDay * pixelsPerMinute,
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
                          
                          // Ensure the date key exists in the map
                          final dateKey = _normalizeDate(selectedDate);
                          if (!tasksByDate.containsKey(dateKey)) {
                            tasksByDate[dateKey] = [];
                          }
                          
                          if (sideTasks.contains(details.data)) {
                            sideTasks.remove(details.data);
                            details.data.startTime = newStartTime;
                            tasksByDate[dateKey]!.add(details.data);
                            _saveSideTasksToFirebase();
                          } else if (timelineTasks.contains(details.data)) {
                            // Dragging within timeline, update time
                            details.data.startTime = newStartTime;
                          } else {
                            // Dragging from completed area
                            details.data.startTime = newStartTime;
                            tasksByDate[dateKey]!.add(details.data);
                          }
                          _saveTasksToFirebase();
                        });
                      }
                    },
                  ),
                  ...activeTasks.map((task) {
                    final top = task.startTime.difference(startOfDay).inMinutes * pixelsPerMinute;
                    final height = task.duration.inMinutes * pixelsPerMinute;
                    return Positioned(
                      top: top,
                      left: timelineLeftPadding,
                      right: timelineRightPadding,
                      height: height,
                      child: Draggable<Task>(
                        data: task,
                        feedback: Material(
                          child: _buildTaskItem(task),
                          elevation: 4.0,
                        ),
                        childWhenDragging: Container(),
                        child: GestureDetector(
                          onTap: () => _showEditDialog(context, task),
                          child: _buildTaskItem(task),
                        ),
                      ),
                    );
                  }),
                  Positioned(
                    left: timelineLeftPadding,
                    right: timelineRightPadding,
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
                      height: completedTasksSectionHeight,
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 2)),
                        color: candidateData.isNotEmpty ? Colors.green.shade100 : Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Completed Tasks (${completedTasks.length})',
                              style: const TextStyle(
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
                                      width: dragFeedbackWidth,
                                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      child: _buildTaskItem(task),
                                    ),
                                    elevation: 4.0,
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      child: _buildTaskItem(task),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _showEditDialog(context, task),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                      child: _buildTaskItem(task),
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
                        final dateKey = _normalizeDate(selectedDate);
                        if (!tasksByDate.containsKey(dateKey)) {
                          tasksByDate[dateKey] = [];
                        }
                        tasksByDate[dateKey]!.add(task);
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: currentTask != null && currentTask!.isTracking 
                                ? Colors.orange 
                                : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateTaskDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Task'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                                width: dragFeedbackWidth,
                                child: _buildTaskItem(task),
                              ),
                              elevation: 4.0,
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildTaskItem(task),
                            ),
                            child: GestureDetector(
                              onTap: () => _showEditDialog(context, task),
                              child: _buildTaskItem(task),
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
                        
                        // Remove from timeline tasks
                        final dateKey = _normalizeDate(selectedDate);
                        if (tasksByDate.containsKey(dateKey)) {
                          tasksByDate[dateKey]!.remove(task);
                        }
                        
                        if (!sideTasks.contains(task)) {
                          sideTasks.add(task);
                        }
                        task.duration = task.scheduledDuration;
                      });
                      _saveTasksToFirebase();
                      _saveSideTasksToFirebase();
                    },
                  ),
                ),
                // Completed tasks summary section
                Container(
                  height: completedTasksSummarySectionHeight,
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300, width: 2)),
                    color: Colors.grey.shade100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Completed (${completedTasks.length})',
                          style: const TextStyle(
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
                                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${task.title} · ${_formatTime(task.startTime)} · ${_formatDuration(task.duration)}',
                                        style: const TextStyle(fontSize: 12),
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

  String _formatSelectedDate() {
    final now = DateTime.now();
    final today = _normalizeDate(now);
    final selected = _normalizeDate(selectedDate);
    
    if (selected == today) {
      return 'Today';
    } else if (selected == today.add(Duration(days: 1))) {
      return 'Tomorrow';
    } else if (selected == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${selected.month}/${selected.day}/${selected.year}';
    }
  }

  Map<DateTime, int> _getTaskCountByDate() {
    final Map<DateTime, int> counts = {};
    for (final entry in tasksByDate.entries) {
      counts[entry.key] = entry.value.length;
    }
    return counts;
  }

  String _getWeekRangeText() {
    return '${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.year}';
  }

  List<Widget> _buildWeekdayButtons() {
    final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = _normalizeDate(DateTime.now());
    
    return List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final normalizedDate = _normalizeDate(date);
      final isSelected = normalizedDate == _normalizeDate(selectedDate);
      final isToday = normalizedDate == today;
      final hasTask = tasksByDate.containsKey(normalizedDate) && 
                      tasksByDate[normalizedDate]!.isNotEmpty;
      
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekdays[index],
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Stack(
                alignment: Alignment.center,
                children: [
                  Material(
                    color: isSelected
                        ? Colors.purple
                        : isToday
                            ? Colors.blue.shade100
                            : Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                          startOfDay = _normalizeDate(selectedDate);
                          currentTask = null;
                          if (!tasksByDate.containsKey(_normalizeDate(selectedDate))) {
                            tasksByDate[_normalizeDate(selectedDate)] = [];
                          }
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _centerOnCurrentTime();
                        });
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? Colors.blue.shade700
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (hasTask && !isSelected)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showCalendarBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: CalendarDialog(
                selectedDate: selectedDate,
                taskCountByDate: _getTaskCountByDate(),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        selectedDate = result;
        startOfDay = _normalizeDate(selectedDate);
        currentTask = null;
        
        if (!tasksByDate.containsKey(_normalizeDate(selectedDate))) {
          tasksByDate[_normalizeDate(selectedDate)] = [];
        }
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnCurrentTime();
      });
    }
  }

  /// Helper method to build TaskItem widget with common parameters
  Widget _buildTaskItem(Task task) {
    return TaskItem(
      task: task,
      isOverlapping: _isOverlapping(task),
      overlapSegments: _getOverlapSegments(task),
      trackedDuration: _currentTrackedDuration(task),
      lateTrackedDuration: task.lateTrackedDuration,
      isTracking: task.isTracking,
      isCompleted: task.isCompleted,
      isPastTask: _isTaskPast(task),
      isFutureTask: _isTaskFuture(task),
      isCurrentTask: _isTaskCurrent(task),
      onReset: () => _resetTask(task),
      onComplete: () => _markComplete(task),
    );
  }
}


