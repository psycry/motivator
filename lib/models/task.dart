class TrackingSegment {
  final DateTime start;
  final DateTime end;

  TrackingSegment({required this.start, required this.end});

  Map<String, dynamic> toMap() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
  }

  factory TrackingSegment.fromMap(Map<String, dynamic> map) {
    return TrackingSegment(
      start: DateTime.parse(map['start'] as String),
      end: DateTime.parse(map['end'] as String),
    );
  }
}

class SubTask {
  final String id;
  String title;
  bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] as String,
      title: map['title'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

class Task {
  final String id;
  String title;
  DateTime startTime;
  Duration duration;
  Duration scheduledDuration;
  Duration trackedDuration;
  Duration lateTrackedDuration;
  bool startedLate;
  bool isTracking;
  DateTime? trackingStart;
  bool isCompleted;
  List<TrackingSegment> trackingSegments;
  List<SubTask> subTasks;
  
  // Recurring task properties
  bool isRecurring;
  DateTime? recurringStartDate;
  DateTime? recurringEndDate; // null means indefinite
  String? recurringParentId; // ID of the original recurring task
  List<int> recurringWeekdays;
  
  // Notification settings (per-task)
  bool notificationsEnabled; // Override global setting
  int? notificationMinutesBefore; // null means use global setting

  Task({
    required this.id,
    required this.title,
    required this.startTime,
    required Duration duration,
    Duration? scheduledDuration,
    Duration? trackedDuration,
    Duration? lateTrackedDuration,
    this.startedLate = false,
    this.isTracking = false,
    this.trackingStart,
    this.isCompleted = false,
    List<TrackingSegment>? trackingSegments,
    List<SubTask>? subTasks,
    this.isRecurring = false,
    this.recurringStartDate,
    this.recurringEndDate,
    this.recurringParentId,
    List<int>? recurringWeekdays,
    this.notificationsEnabled = true,
    this.notificationMinutesBefore,
  })  : duration = duration,
        scheduledDuration = scheduledDuration ?? duration,
        trackedDuration = trackedDuration ?? Duration.zero,
        lateTrackedDuration = lateTrackedDuration ?? Duration.zero,
        trackingSegments = trackingSegments ?? [],
        subTasks = subTasks ?? [],
        recurringWeekdays = recurringWeekdays ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'duration': duration.inSeconds,
      'scheduledDuration': scheduledDuration.inSeconds,
      'trackedDuration': trackedDuration.inSeconds,
      'lateTrackedDuration': lateTrackedDuration.inSeconds,
      'startedLate': startedLate,
      'isTracking': isTracking,
      'trackingStart': trackingStart?.toIso8601String(),
      'isCompleted': isCompleted,
      'trackingSegments': trackingSegments.map((s) => s.toMap()).toList(),
      'subTasks': subTasks.map((s) => s.toMap()).toList(),
      'isRecurring': isRecurring,
      'recurringStartDate': recurringStartDate?.toIso8601String(),
      'recurringEndDate': recurringEndDate?.toIso8601String(),
      'recurringParentId': recurringParentId,
      'recurringWeekdays': recurringWeekdays,
      'notificationsEnabled': notificationsEnabled,
      'notificationMinutesBefore': notificationMinutesBefore,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      duration: Duration(seconds: map['duration'] as int),
      scheduledDuration: Duration(seconds: map['scheduledDuration'] as int),
      trackedDuration: Duration(seconds: map['trackedDuration'] as int),
      lateTrackedDuration: Duration(seconds: map['lateTrackedDuration'] as int),
      startedLate: map['startedLate'] as bool,
      isTracking: map['isTracking'] as bool,
      trackingStart: map['trackingStart'] != null 
          ? DateTime.parse(map['trackingStart'] as String)
          : null,
      isCompleted: map['isCompleted'] as bool,
      trackingSegments: (map['trackingSegments'] as List<dynamic>?)
          ?.map((s) => TrackingSegment.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
      subTasks: (map['subTasks'] as List<dynamic>?)
          ?.map((s) => SubTask.fromMap(s as Map<String, dynamic>))
          .toList() ?? [],
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurringStartDate: map['recurringStartDate'] != null
          ? DateTime.parse(map['recurringStartDate'] as String)
          : null,
      recurringEndDate: map['recurringEndDate'] != null
          ? DateTime.parse(map['recurringEndDate'] as String)
          : null,
      recurringParentId: map['recurringParentId'] as String?,
      recurringWeekdays: (map['recurringWeekdays'] as List<dynamic>?)
              ?.map((value) => (value as num).toInt())
              .toList() ??
          [],
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      notificationMinutesBefore: map['notificationMinutesBefore'] as int?,
    );
  }
}
