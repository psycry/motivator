class TrackingSegment {
  final DateTime start;
  final DateTime end;

  TrackingSegment({required this.start, required this.end});
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
}
