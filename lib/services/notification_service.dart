import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();
    // Set local timezone - use UTC as fallback if local timezone detection fails
    try {
      final locationName = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (e) {
      // Fallback to UTC if we can't determine local timezone
      tz.setLocalLocation(tz.getLocation('UTC'));
      print('⚠️ Could not set local timezone, using UTC: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
    print('✓ NotificationService initialized');
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print('📱 Android notification permission granted: $granted');
      
      // Request exact alarm permission for Android 12+
      final exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();
      print('⏰ Android exact alarm permission granted: $exactAlarmGranted');
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('📱 iOS notification permission granted: $granted');
    }
  }
  
  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) {
      await initialize();
    }
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.areNotificationsEnabled();
      print('📱 Android notifications enabled: $granted');
      return granted ?? false;
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    
    return false;
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap - could navigate to specific task
  }

  /// Schedule a notification for a task
  /// Uses per-task settings if available, otherwise falls back to global settings
  Future<void> scheduleTaskNotification({
    required Task task,
    required int minutesBefore, // Global default
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Check if notifications are enabled globally
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      print('⚠️ Notifications are not enabled globally. Please enable them in settings.');
      return;
    }

    // Check if notifications are enabled for this specific task
    if (!task.notificationsEnabled) {
      print('⚠️ Notifications disabled for task: ${task.title}');
      return;
    }

    // Use per-task notification time if set, otherwise use global setting
    final effectiveMinutesBefore = task.notificationMinutesBefore ?? minutesBefore;
    
    // Calculate notification time
    final notificationTime = task.startTime.subtract(Duration(minutes: effectiveMinutesBefore));
    
    // Don't schedule if notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      print('⚠️ Notification time is in the past for task: ${task.title}');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
    print('📅 Scheduling notification for ${task.title} at $scheduledDate (${effectiveMinutesBefore} min before)');

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        task.id.hashCode, // Use task ID hash as notification ID
        'Task Starting Soon',
        '${task.title} starts in $effectiveMinutesBefore minute${effectiveMinutesBefore != 1 ? 's' : ''}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id,
      );
      
      print('✓ Scheduled notification for task "${task.title}" at $notificationTime (${effectiveMinutesBefore} min before)');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Cancel notification for a specific task
  Future<void> cancelTaskNotification(Task task) async {
    if (!_initialized) return;
    
    await _notifications.cancel(task.id.hashCode);
    print('✓ Cancelled notification for task: ${task.title}');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;
    
    await _notifications.cancelAll();
    print('✓ Cancelled all notifications');
  }

  /// Reschedule all notifications for a list of tasks
  Future<void> rescheduleAllNotifications({
    required List<Task> tasks,
    required int minutesBefore,
    required bool enabled,
  }) async {
    if (!enabled) {
      await cancelAllNotifications();
      return;
    }

    // Cancel all existing notifications first
    await cancelAllNotifications();

    // Schedule new notifications for incomplete tasks
    for (final task in tasks) {
      if (!task.isCompleted && task.startTime.isAfter(DateTime.now())) {
        await scheduleTaskNotification(
          task: task,
          minutesBefore: minutesBefore,
        );
      }
    }
  }

  /// Show an immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
    print('✓ Immediate notification shown: $title');
  }
  
  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) {
      await initialize();
    }
    
    final pending = await _notifications.pendingNotificationRequests();
    print('📋 Pending notifications: ${pending.length}');
    for (final notification in pending) {
      print('  - ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
    }
    return pending;
  }
}
