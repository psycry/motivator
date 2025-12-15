from pathlib import Path

path = Path(r"C:\Users\wjlan\Projects\motivator\lib\main.dart")
text = path.read_text()

old_segment = """class MyApp extends StatelessWidget {
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

  Duration _currentTrackedDuration(Task task) {
    if (task.isTracking && task.trackingStart != null) {
      return task.trackedDuration + DateTime.now().difference(task.trackingStart!);
    }
    return task.trackedDuration;
  }

  void _startTracking(Task task) {
    final now = DateTime.now();
    setState(() {
      if (sideTasks.contains(task)) {
        sideTasks.remove(task);
        timelineTasks.add(task);
      }
      task.startTime = now;
      task.trackingStart = now;
      task.isTracking = true;
    });
  }

  void _stopTracking(Task task) {
    if (!task.isTracking) return;
    final now = DateTime.now();
    setState(() {
      final additional = task.trackingStart != null ? now.difference(task.trackingStart!) : Duration.zero;
      task.trackedDuration += additional;
      task.trackingStart = null;
      task.isTracking = false;
    });
  }
}
"""

new_segment = """class MyApp extends StatelessWidget {
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
"""

if old_segment not in text:
  raise SystemExit("old MyApp segment not found")

text = text.replace(old_segment, new_segment, 1)

anchor = """  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

"""

helpers = """  Duration _currentTrackedDuration(Task task) {
    if (task.isTracking && task.trackingStart != null) {
      return task.trackedDuration + DateTime.now().difference(task.trackingStart!);
    }
    return task.trackedDuration;
  }

  void _startTracking(Task task) {
    final now = DateTime.now();
    setState(() {
      if (sideTasks.contains(task)) {
        sideTasks.remove(task);
        timelineTasks.add(task);
      }
      task.startTime = now;
      task.trackingStart = now;
      task.isTracking = true;
    });
  }

  void _stopTracking(Task task) {
    if (!task.isTracking) return;
    final now = DateTime.now();
    setState(() {
      final additional = task.trackingStart != null ? now.difference(task.trackingStart!) : Duration.zero;
      task.trackedDuration += additional;
      task.trackingStart = null;
      task.isTracking = false;
    });
  }

"""

if anchor not in text:
  raise SystemExit("dispose anchor not found")

text = text.replace(anchor, anchor + helpers, 1)

path.write_text(text)
