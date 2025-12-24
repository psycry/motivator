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
  })  : duration = duration,
        scheduledDuration = scheduledDuration ?? duration,
        trackedDuration = trackedDuration ?? Duration.zero,
        lateTrackedDuration = lateTrackedDuration ?? Duration.zero,
        trackingSegments = trackingSegments ?? [];

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
    );
  }
}
