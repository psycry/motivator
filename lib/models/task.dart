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
  })  : duration = duration,
        scheduledDuration = scheduledDuration ?? duration,
        trackedDuration = trackedDuration ?? Duration.zero,
        lateTrackedDuration = lateTrackedDuration ?? Duration.zero;
}
