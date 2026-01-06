# Notifications Setup

## Overview
The Motivator app now includes a comprehensive notification system that alerts you before tasks start. You can customize when you receive notifications through the Settings menu.

## Features

### 1. **Settings Menu**
- Access via the menu icon (three dots) in the top-right corner of the app
- Select "Settings" to open the notification preferences dialog

### 2. **Notification Options**
- **Enable/Disable Notifications**: Toggle notifications on or off
- **Notification Timing**: Set how many minutes before a task starts you want to be notified
  - Quick select options: 1, 5, 10, 15, 30, or 60 minutes
  - Custom slider: Fine-tune anywhere from 1 to 60 minutes

### 3. **Automatic Scheduling**
- Notifications are automatically scheduled when:
  - Tasks are created
  - Tasks are modified
  - Tasks are loaded from Firebase
  - Notification settings are changed

### 4. **Smart Notification Management**
- Only schedules notifications for incomplete tasks
- Only schedules notifications for tasks in the future
- Automatically cancels notifications when tasks are completed or deleted
- Reschedules all notifications when settings change

## How It Works

### Architecture
1. **UserPreferences Model** (`lib/models/user_preferences.dart`)
   - Stores notification settings (enabled/disabled, minutes before)
   - Synced to Firebase for persistence across devices

2. **NotificationService** (`lib/services/notification_service.dart`)
   - Handles all notification scheduling and cancellation
   - Uses `flutter_local_notifications` for cross-platform support
   - Manages timezone-aware scheduling

3. **UserService** (`lib/services/user_service.dart`)
   - Saves and loads user preferences from Firebase
   - Provides real-time streaming of preference updates

4. **SettingsDialog** (`lib/widgets/settings_dialog.dart`)
   - User-friendly interface for managing notification settings
   - Visual feedback with chips and slider

### Notification Flow
```
User Creates/Modifies Task
    ↓
Task Saved to Firebase
    ↓
_rescheduleAllNotifications() called
    ↓
NotificationService schedules notification
    ↓
System shows notification X minutes before task
```

## Platform-Specific Setup

### Android
- Notifications work out of the box
- For Android 13+, permission is automatically requested
- Uses exact alarm scheduling for precise timing

### iOS
- Permissions are requested on first use
- Supports alert, badge, and sound notifications
- Follows iOS notification best practices

### Windows/Linux/macOS
- Desktop notifications supported via platform-specific implementations
- May require additional system permissions

## Usage Examples

### Example 1: Enable 5-Minute Reminders
1. Tap menu (⋮) → Settings
2. Enable "Enable Notifications" toggle
3. Select "5 mins" chip or use slider
4. Tap "Save"
5. You'll receive notifications 5 minutes before each task

### Example 2: Disable Notifications
1. Tap menu (⋮) → Settings
2. Disable "Enable Notifications" toggle
3. Tap "Save"
4. All scheduled notifications are cancelled

### Example 3: Custom 20-Minute Warning
1. Tap menu (⋮) → Settings
2. Ensure notifications are enabled
3. Use the slider to set 20 minutes
4. Tap "Save"

## Technical Details

### Dependencies
- `flutter_local_notifications: ^17.2.3` - Cross-platform notification support
- `timezone: ^0.9.4` - Timezone-aware scheduling

### Firebase Integration
User preferences are stored in Firestore under:
```
users/{userId}/preferences
```

Structure:
```json
{
  "notificationsEnabled": true,
  "notificationMinutesBefore": 5
}
```

### Notification Channels (Android)
- **Channel ID**: `task_reminders`
- **Channel Name**: Task Reminders
- **Importance**: High
- **Priority**: High

## Troubleshooting

### Notifications Not Appearing
1. Check that notifications are enabled in Settings
2. Verify system notification permissions are granted
3. Ensure tasks are scheduled in the future
4. Check that tasks are not already completed

### Notifications Appearing Late
- The app uses exact alarm scheduling, but some Android manufacturers may delay notifications
- Check battery optimization settings for the app

### Settings Not Saving
- Ensure you're logged in with a valid Firebase account
- Check Firestore security rules allow user preference writes
- Verify internet connectivity

## Future Enhancements
- Custom notification sounds
- Different notification times for different task types
- Snooze functionality
- Multiple notification reminders per task
- Rich notifications with task details and quick actions
