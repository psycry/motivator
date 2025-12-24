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
import 'pages/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('========================================');
  print('MOTIVATOR APP STARTING');
  print('========================================');
  
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('App will run without Firebase backend');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motivator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Show login page if not authenticated
        if (!snapshot.hasData || snapshot.data == null) {
          return const AuthPage();
        }
        
        // Show main app if authenticated
        return const TaskCalendarPage();
      },
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
  
  FirebaseService? _firebaseService;
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
      print('=== INITIALIZING FIREBASE SERVICE ===');
      
      // Get current authenticated user
      final userId = _authService.currentUserId;
      if (userId == null) {
        print('❌ No authenticated user found');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print('✓ User authenticated: $userId');
      print('Initializing Firebase service for user: $userId');
      _firebaseService = FirebaseService(userId: userId);
      
      // Load tasks from Firebase
      print('=== LOADING TASKS FROM FIREBASE ===');
      await _loadTasksFromFirebase();
    } catch (e) {
      print('❌ Error initializing Firebase service: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTasksFromFirebase() async {
    try {
      print('Calling loadAllTasks()...');
      // Add timeout to prevent infinite loading
      final loadedTasks = await _firebaseService!.loadAllTasks()
          .timeout(const Duration(seconds: 5));
      print('✓ loadAllTasks() returned ${loadedTasks.length} date(s)');
      
      print('Calling loadSideTasks()...');
      final loadedSideTasks = await _firebaseService!.loadSideTasks()
          .timeout(const Duration(seconds: 5));
      print('✓ loadSideTasks() returned ${loadedSideTasks.length} tasks');
      
      setState(() {
        tasksByDate = loadedTasks;
        sideTasks = loadedSideTasks;
        _isLoading = false;
      });
      
      print('=== LOAD COMPLETE ===');
      print('✓ Tasks loaded from Firebase successfully');
      print('✓ Total: ${tasksByDate.length} date(s) with tasks, ${sideTasks.length} side tasks');
      
      // Log details of what was loaded
      tasksByDate.forEach((date, tasks) {
        print('  - Date $date: ${tasks.length} tasks');
        for (var task in tasks) {
          print('    • ${task.title} (${task.id})');
        }
      });
      if (sideTasks.isNotEmpty) {
        print('  - Side tasks:');
        for (var task in sideTasks) {
          print('    • ${task.title} (${task.id})');
        }
      }
    } catch (e) {
      print('❌ Error loading tasks from Firebase: $e');
      print('Stack trace: ${StackTrace.current}');
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
    if (_firebaseService == null) {
      print('⚠️ Firebase service not initialized yet, skipping save');
      return;
    }
    
    try {
      print('_saveTasksToFirebase called for ${timelineTasks.length} tasks');
      await _firebaseService!.saveTasksForDate(selectedDate, timelineTasks)
          .timeout(const Duration(seconds: 5));
      print('✓ _saveTasksToFirebase completed successfully');
    } catch (e) {
      // Silently fail - app works without Firebase
      print('❌ Could not save to Firebase: $e');
      if (e.toString().contains('permission-denied')) {
        print('⚠️ Permission denied - check Firestore security rules');
      }
    }
  }

  Future<void> _saveSideTasksToFirebase() async {
    if (_firebaseService == null) {
      print('⚠️ Firebase service not initialized yet, skipping side tasks save');
      return;
    }
    
    try {
      print('_saveSideTasksToFirebase called for ${sideTasks.length} side tasks');
      await _firebaseService!.saveSideTasks(sideTasks)
          .timeout(const Duration(seconds: 5));
      print('✓ _saveSideTasksToFirebase completed successfully');
    } catch (e) {
      // Silently fail - app works without Firebase
      print('❌ Could not save side tasks to Firebase: $e');
      if (e.toString().contains('permission-denied')) {
        print('⚠️ Permission denied - check Firestore security rules');
      }
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
      if (_firebaseService != null) {
        try {
          await _firebaseService!.clearAllTasks();
          print('All tasks cleared successfully');
        } catch (e) {
          print('Error clearing tasks from Firebase: $e');
        }
      }
    }
  }

  bool _isOverlapping(Task task) {
    for (var other in timelineTasks) {
      if (other != task &&
          !other.isCompleted && // Exclude completed tasks from overlap detection
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
      if (other == task || other.isCompleted) continue; // Exclude completed tasks
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
    bool isRecurring = false;
    DateTime? recurringEndDate;
    bool hasEndDate = false;
    String recurrenceType = 'daily';
    Set<int> selectedWeekdays = {startOfDay.weekday};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            const weekdayValues = [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
              DateTime.saturday,
              DateTime.sunday,
            ];
            return AlertDialog(
              title: const Text('Create New Task'),
              content: SingleChildScrollView(
                child: Column(
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
                              setModalState(() {
                                selectedPeriod = value;
                              });
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
                    SizedBox(height: 16),
                    Divider(),
                    CheckboxListTile(
                      title: const Text('Repeat Task'),
                      subtitle: const Text('Choose how often this repeats'),
                      value: isRecurring,
                      onChanged: (value) {
                        setModalState(() {
                          isRecurring = value ?? false;
                          if (isRecurring) {
                            if (selectedWeekdays.isEmpty) {
                              selectedWeekdays = {startOfDay.weekday};
                            }
                          } else {
                            hasEndDate = false;
                            recurringEndDate = null;
                            recurrenceType = 'daily';
                            selectedWeekdays = {startOfDay.weekday};
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (isRecurring) ...[
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Repeat pattern',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButton<String>(
                        value: recurrenceType,
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              recurrenceType = value;
                              if (recurrenceType == 'weekly' && selectedWeekdays.isEmpty) {
                                selectedWeekdays = {startOfDay.weekday};
                              }
                              if (recurrenceType == 'daily') {
                                selectedWeekdays = {startOfDay.weekday};
                              }
                            });
                          }
                        },
                      ),
                      if (recurrenceType == 'weekly') ...[
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<Widget>.generate(7, (index) {
                            final label = weekdayLabels[index];
                            final value = weekdayValues[index];
                            final isSelected = selectedWeekdays.contains(value);
                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedWeekdays = {...selectedWeekdays, value};
                                  } else if (selectedWeekdays.length > 1) {
                                    final updated = {...selectedWeekdays};
                                    updated.remove(value);
                                    selectedWeekdays = updated;
                                  }
                                });
                              },
                            );
                          }),
                        ),
                      ],
                      SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Set End Date'),
                        subtitle: Text(hasEndDate && recurringEndDate != null
                            ? 'Ends: ${_formatDate(recurringEndDate!)}'
                            : 'Repeats indefinitely'),
                        value: hasEndDate,
                        onChanged: (value) {
                          setModalState(() {
                            hasEndDate = value ?? false;
                            if (hasEndDate && recurringEndDate == null) {
                              recurringEndDate = DateTime.now().add(const Duration(days: 30));
                            } else if (!hasEndDate) {
                              recurringEndDate = null;
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (hasEndDate)
                        ListTile(
                          title: const Text('End Date'),
                          subtitle: Text(recurringEndDate != null
                              ? _formatDate(recurringEndDate!)
                              : 'Select date'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: recurringEndDate ?? DateTime.now().add(Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                recurringEndDate = picked;
                              });
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (titleController.text.isEmpty) {
                      print('⚠️ Task title is empty, not creating');
                      return;
                    }
                    
                    print('=== CREATING NEW TASK ===');
                    print('Title: ${titleController.text}');
                    print('Is Recurring: $isRecurring');
                    print('Recurrence Type: $recurrenceType');
                    print('Recurring Weekdays: $selectedWeekdays');
                    print('Has End Date: $hasEndDate');
                    
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

                      final List<int> recurringWeekdayList = isRecurring && recurrenceType == 'weekly'
                          ? (selectedWeekdays.isEmpty
                              ? [startTime.weekday]
                              : (selectedWeekdays.toList()..sort()))
                          : <int>[];

                      final parsedDurationHours = (int.tryParse(durationHourController.text) ?? 1).clamp(0, 24 * 7);
                      final parsedDurationMinutes = (int.tryParse(durationMinuteController.text) ?? 0).clamp(0, 59);
                      final totalDurationMinutes = parsedDurationHours * 60 + parsedDurationMinutes;
                      final clampedDuration = totalDurationMinutes.clamp(1, 24 * 60);
                      final duration = Duration(minutes: clampedDuration);

                      final taskId = DateTime.now().millisecondsSinceEpoch.toString();
                      final newTask = Task(
                        id: taskId,
                        title: titleController.text,
                        startTime: startTime,
                        duration: duration,
                        isRecurring: isRecurring,
                        recurringStartDate: isRecurring ? _normalizeDate(startTime) : null,
                        recurringEndDate: hasEndDate ? recurringEndDate : null,
                        recurringWeekdays: recurringWeekdayList,
                      );

                      print('✓ Task created with ID: $taskId');
                      sideTasks.add(newTask);
                      print('✓ Task added to sideTasks (count: ${sideTasks.length})');
                      
                      // If recurring, generate instances for visible dates
                      if (isRecurring) {
                        print('Generating recurring instances...');
                        _generateRecurringTaskInstances(newTask);
                      }
                      
                      _saveSideTasksToFirebase();
                      print('=== TASK CREATION COMPLETE ===');
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

    final hourController = TextEditingController(text: initialHour12.toString());
    final minuteController = TextEditingController(text: task.startTime.minute.toString());
    final durationHours = task.duration.inMinutes ~/ 60;
    final durationMinutes = task.duration.inMinutes % 60;
    final durationHourController = TextEditingController(text: durationHours.toString());
    final durationMinuteController = TextEditingController(text: durationMinutes.toString());

    showDialog(
      context: context,
      builder: (context) {
        // Use a map to maintain state across rebuilds
        final dialogState = <String, dynamic>{
          'selectedPeriod': initialHour24 >= 12 ? 'PM' : 'AM',
          'isRecurring': task.isRecurring,
          'hasEndDate': task.recurringEndDate != null,
          'recurringEndDate': task.recurringEndDate,
          'recurrenceType': task.recurringWeekdays.isNotEmpty ? 'weekly' : 'daily',
          'recurringWeekdays': List<int>.from(
            task.recurringWeekdays.isNotEmpty
                ? task.recurringWeekdays
                : [task.startTime.weekday],
          ),
        };

        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedPeriod = dialogState['selectedPeriod'] as String;
            final isRecurring = dialogState['isRecurring'] as bool;
            final hasEndDate = dialogState['hasEndDate'] as bool;
            final recurringEndDate = dialogState['recurringEndDate'] as DateTime?;
            final recurrenceType = dialogState['recurrenceType'] as String;
            final recurringWeekdays = List<int>.from(dialogState['recurringWeekdays'] as List<int>);
            final recurringWeekdaySet = recurringWeekdays.toSet();
            const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            const weekdayValues = [
              DateTime.monday,
              DateTime.tuesday,
              DateTime.wednesday,
              DateTime.thursday,
              DateTime.friday,
              DateTime.saturday,
              DateTime.sunday,
            ];
            
            return AlertDialog(
              title: const Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
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
                              setModalState(() {
                                dialogState['selectedPeriod'] = value;
                              });
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
                    SizedBox(height: 16),
                    Divider(),
                    CheckboxListTile(
                      title: const Text('Repeat Task'),
                      subtitle: const Text('Choose how often this repeats'),
                      value: isRecurring,
                      onChanged: (value) {
                        setModalState(() {
                          final updatedValue = value ?? false;
                          dialogState['isRecurring'] = updatedValue;
                          if (updatedValue) {
                            final currentWeekdays = List<int>.from(dialogState['recurringWeekdays'] as List<int>);
                            if (currentWeekdays.isEmpty) {
                              dialogState['recurringWeekdays'] = [task.startTime.weekday];
                            }
                          } else {
                            dialogState['hasEndDate'] = false;
                            dialogState['recurringEndDate'] = null;
                            dialogState['recurrenceType'] = 'daily';
                            dialogState['recurringWeekdays'] = [task.startTime.weekday];
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (isRecurring) ...[
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Repeat pattern',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(height: 8),
                      DropdownButton<String>(
                        value: recurrenceType,
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              dialogState['recurrenceType'] = value;
                              if (value == 'weekly') {
                                final currentWeekdays = List<int>.from(dialogState['recurringWeekdays'] as List<int>);
                                if (currentWeekdays.isEmpty) {
                                  dialogState['recurringWeekdays'] = [task.startTime.weekday];
                                }
                              } else {
                                dialogState['recurringWeekdays'] = [task.startTime.weekday];
                              }
                            });
                          }
                        },
                      ),
                      if (recurrenceType == 'weekly') ...[
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<Widget>.generate(7, (index) {
                            final label = weekdayLabels[index];
                            final value = weekdayValues[index];
                            final isSelected = recurringWeekdaySet.contains(value);
                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  final updated = recurringWeekdaySet.toSet();
                                  if (selected) {
                                    updated.add(value);
                                  } else if (updated.length > 1) {
                                    updated.remove(value);
                                  }
                                  dialogState['recurringWeekdays'] = updated.toList()..sort();
                                });
                              },
                            );
                          }),
                        ),
                      ],
                      SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Set End Date'),
                        subtitle: Text(hasEndDate && recurringEndDate != null
                            ? 'Ends: ${_formatDate(recurringEndDate!)}'
                            : 'Repeats indefinitely'),
                        value: hasEndDate,
                        onChanged: (value) {
                          setModalState(() {
                            final updatedValue = value ?? false;
                            dialogState['hasEndDate'] = updatedValue;
                            final currentEndDate = dialogState['recurringEndDate'] as DateTime?;
                            if (updatedValue && currentEndDate == null) {
                              dialogState['recurringEndDate'] = DateTime.now().add(Duration(days: 30));
                            } else if (!updatedValue) {
                              dialogState['recurringEndDate'] = null;
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (hasEndDate)
                        ListTile(
                          title: const Text('End Date'),
                          subtitle: Text(recurringEndDate != null
                              ? _formatDate(recurringEndDate!)
                              : 'Select date'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: recurringEndDate ?? DateTime.now().add(Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                dialogState['recurringEndDate'] = picked;
                              });
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final confirmed = await _confirmDeleteTask(context, task);
                    if (!confirmed) return;

                    await _deleteTaskSeries(task);
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final selectedPeriodValue = dialogState['selectedPeriod'] as String;
                    final isRecurringValue = dialogState['isRecurring'] as bool;
                    final hasEndDateValue = dialogState['hasEndDate'] as bool;
                    final recurringEndDateValue = dialogState['recurringEndDate'] as DateTime?;
                    final recurrenceTypeValue = dialogState['recurrenceType'] as String;
                    final recurringWeekdaysValue = List<int>.from(dialogState['recurringWeekdays'] as List<int>);

                    setState(() {
                      task.title = titleController.text;

                      int parsedHour = int.tryParse(hourController.text) ?? initialHour12;
                      parsedHour = parsedHour.clamp(1, 12);
                      if (selectedPeriodValue == 'AM') {
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
                      
                      // Update recurring properties
                      task.isRecurring = isRecurringValue;

                      if (!isRecurringValue) {
                        task.recurringStartDate = null;
                        task.recurringEndDate = null;
                        task.recurringWeekdays = [];
                        task.recurringParentId = null;
                        _clearRecurringInstances(task.id);
                      } else {
                        task.recurringEndDate = hasEndDateValue ? recurringEndDateValue : null;
                        task.recurringStartDate ??= _normalizeDate(task.startTime);

                        if (recurrenceTypeValue == 'weekly') {
                          final effectiveWeekdays = recurringWeekdaysValue.isEmpty
                              ? [task.startTime.weekday]
                              : (List<int>.from(recurringWeekdaysValue)..sort());
                          task.recurringWeekdays = effectiveWeekdays;
                        } else {
                          task.recurringWeekdays = [];
                        }
                      }

                      if (task.isRecurring) {
                        _generateRecurringTaskInstances(task);
                      }
                      
                      // Save changes
                      if (sideTasks.contains(task)) {
                        _saveSideTasksToFirebase();
                      } else {
                        _saveTasksToFirebase();
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

  Future<bool> _confirmDeleteTask(BuildContext context, Task task) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: Text(
              task.isRecurring || task.recurringParentId != null
                  ? 'Delete the entire series for "${task.title}"? This cannot be undone.'
                  : 'Delete "${task.title}"? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteTaskSeries(Task task) async {
    final seriesId = task.recurringParentId ?? task.id;
    final affectedDates = <DateTime>{};
    var sideTasksChanged = false;

    // Remove from UI immediately
    setState(() {
      final entries = tasksByDate.entries.toList();
      for (final entry in entries) {
        final beforeLength = entry.value.length;
        entry.value.removeWhere(
          (t) => t.id == seriesId || t.recurringParentId == seriesId,
        );
        if (entry.value.isEmpty) {
          tasksByDate.remove(entry.key);
        }
        if (entry.value.length != beforeLength) {
          affectedDates.add(entry.key);
        }
      }

      final previousSideLength = sideTasks.length;
      sideTasks.removeWhere((t) => t.id == seriesId || t.recurringParentId == seriesId);
      sideTasksChanged = sideTasksChanged || previousSideLength != sideTasks.length;

      if (currentTask != null &&
          (currentTask!.id == seriesId || currentTask!.recurringParentId == seriesId)) {
        currentTask = null;
      }
      
      final currentDateKey = _normalizeDate(selectedDate);
      if (!tasksByDate.containsKey(currentDateKey)) {
        tasksByDate[currentDateKey] = [];
      }
    });

    // Save to Firebase asynchronously
    Future.delayed(Duration.zero, () async {
      if (_firebaseService != null) {
        for (final date in affectedDates) {
          await _firebaseService!.saveTasksForDate(date, tasksByDate[date] ?? []);
        }
      }

      if (sideTasksChanged) {
        await _saveSideTasksToFirebase();
      }
    });
  }

  void _clearRecurringInstances(String parentId) {
    final entries = tasksByDate.entries.toList();
    for (final entry in entries) {
      entry.value.removeWhere((task) => task.recurringParentId == parentId);
      if (entry.value.isEmpty) {
        tasksByDate.remove(entry.key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Motivator'),
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
        title: const Text('Motivator'),
        actions: [
          // User email display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                _authService.currentUser?.email ?? '',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'clear_all') {
                _clearAllTasks();
              } else if (value == 'logout') {
                await _authService.signOut();
                // Navigation will happen automatically via auth state listener
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
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getWeekRangeText(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showCalendarBottomSheet(context),
                                  icon: const Icon(Icons.calendar_month, size: 20),
                                  tooltip: 'Open Calendar',
                                  color: Colors.purple,
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
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
                          elevation: 4.0,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width - timelineLeftPadding - timelineRightPadding,
                            height: height,
                            child: _buildTaskItem(task),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: _buildTaskItem(task),
                        ),
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
                // Completed tasks section - under timeline only
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
                                      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(4),
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
                                    elevation: 4.0,
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
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
                                  ),
                                  child: InkWell(
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
                                child: _buildTaskItem(task, isOnTimeline: false),
                              ),
                              elevation: 4.0,
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildTaskItem(task, isOnTimeline: false),
                            ),
                            child: GestureDetector(
                              onTap: () => _showEditDialog(context, task),
                              child: _buildTaskItem(task, isOnTimeline: false),
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _generateRecurringTaskInstances(Task recurringTask) {
    if (!recurringTask.isRecurring || recurringTask.recurringParentId != null) {
      return;
    }

    try {
      print('=== GENERATING RECURRING TASK INSTANCES ===');
      print('Task: ${recurringTask.title}');

      final startDate = recurringTask.recurringStartDate ?? _normalizeDate(recurringTask.startTime);
      final endDate = recurringTask.recurringEndDate;
      final now = _normalizeDate(DateTime.now());
      final weeklyPattern = List<int>.from(recurringTask.recurringWeekdays);
      final effectiveWeeklyPattern = weeklyPattern.isEmpty ? <int>[] : (List<int>.from(weeklyPattern)..sort());

      // Determine generation horizon: at least 60 days or until end date
      final horizonDate = endDate ?? now.add(const Duration(days: 60));
      final totalDays = horizonDate.difference(startDate).inDays + 1;

      print('Start date: $startDate');
      print('End date: ${endDate ?? "indefinite"}');
      print('Weekly pattern: ${effectiveWeeklyPattern.isEmpty ? "daily" : effectiveWeeklyPattern}');

      // Remove existing instances for this recurring parent before regenerating
      _clearRecurringInstances(recurringTask.id);

      for (int i = 0; i < totalDays; i++) {
        final candidateDate = startDate.add(Duration(days: i));
        final normalizedDate = _normalizeDate(candidateDate);

        if (normalizedDate.isBefore(startDate)) {
          continue;
        }
        if (endDate != null && normalizedDate.isAfter(endDate)) {
          break;
        }

        // Weekly recurrence filter
        if (effectiveWeeklyPattern.isNotEmpty && !effectiveWeeklyPattern.contains(normalizedDate.weekday)) {
          continue;
        }

        tasksByDate.putIfAbsent(normalizedDate, () => []);

        final instanceStart = DateTime(
          normalizedDate.year,
          normalizedDate.month,
          normalizedDate.day,
          recurringTask.startTime.hour,
          recurringTask.startTime.minute,
        );

        final instance = Task(
          id: '${recurringTask.id}_${normalizedDate.millisecondsSinceEpoch}',
          title: recurringTask.title,
          startTime: instanceStart,
          duration: recurringTask.duration,
          scheduledDuration: recurringTask.scheduledDuration,
          recurringParentId: recurringTask.id,
          isRecurring: true,
          recurringStartDate: recurringTask.recurringStartDate,
          recurringEndDate: recurringTask.recurringEndDate,
          recurringWeekdays: effectiveWeeklyPattern,
        );

        tasksByDate[normalizedDate]!.add(instance);
        print('  - Created instance for ${_formatDate(normalizedDate)}');
      }

      // Ensure current timeline cache reflects updates
      if (tasksByDate.containsKey(_normalizeDate(selectedDate))) {
        timelineTasks = tasksByDate[_normalizeDate(selectedDate)] ?? [];
      }

      _saveTasksToFirebase();
      print('=== RECURRENCE GENERATION COMPLETE ===');
    } catch (e) {
      print('❌ Error generating recurring task instances: $e');
      print('Stack trace: ${StackTrace.current}');
    }
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
  Widget _buildTaskItem(Task task, {bool isOnTimeline = true}) {
    return TaskItem(
      task: task,
      isOverlapping: isOnTimeline ? _isOverlapping(task) : false,
      overlapSegments: isOnTimeline ? _getOverlapSegments(task) : const [],
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


