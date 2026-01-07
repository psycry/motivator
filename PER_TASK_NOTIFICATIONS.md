# Per-Task Notification Customization

## Overview
In addition to global notification settings, you can now customize notification preferences for individual tasks. This allows you to:
- Disable notifications for specific tasks
- Set custom notification times for important tasks
- Override global settings on a per-task basis

## Features Added

### 1. Task Model Updates
Added two new fields to the `Task` model:
- **`notificationsEnabled`** (bool): Whether notifications are enabled for this specific task
  - Default: `true` (follows global setting)
  - Set to `false` to disable notifications for this task only
  
- **`notificationMinutesBefore`** (int?): Custom notification time in minutes
  - Default: `null` (uses global setting)
  - Set to a specific value (e.g., 5, 10, 30) to override global setting

### 2. Enhanced Notification Service
The `NotificationService` now:
- Checks both global and per-task notification settings
- Uses per-task notification time if set, otherwise falls back to global default
- Logs which settings are being used for debugging

### 3. Task Edit Dialog UI
Added a new "Notifications" section in the task edit dialog with:
- **Enable notifications checkbox**: Toggle notifications on/off for this task
- **Custom notification time checkbox**: Choose to use a custom time
- **Minutes input field**: Set how many minutes before the task to notify
- **Helpful hints**: Shows current global default and common time values

## How to Use

### Disable Notifications for a Specific Task
1. Open a task by tapping on it
2. Scroll down to the "Notifications" section
3. Uncheck "Enable notifications for this task"
4. Click "Save"

The task will no longer trigger notifications, even if global notifications are enabled.

### Set Custom Notification Time
1. Open a task by tapping on it
2. Scroll down to the "Notifications" section
3. Ensure "Enable notifications for this task" is checked
4. Check "Custom notification time"
5. Select a preset time (1, 5, 10, 15, 30, or 60 minutes) or use the slider for any value 1-60
6. Click "Save"

This task will now notify you at the custom time instead of the global default.

### Use Global Default
1. Open a task by tapping on it
2. Scroll down to the "Notifications" section
3. Ensure "Enable notifications for this task" is checked
4. Uncheck "Custom notification time"
5. Click "Save"

The task will use the global notification setting from Settings.

## Examples

### Example 1: Important Meeting
You have a global notification setting of 10 minutes, but you want 30 minutes notice for an important meeting:
1. Edit the meeting task
2. Enable "Custom notification time"
3. Set to 30 minutes
4. Save

Result: You'll get notified 30 minutes before the meeting, while other tasks still use 10 minutes.

### Example 2: Silent Task
You have a recurring "Lunch Break" task that you don't want notifications for:
1. Edit the lunch break task
2. Uncheck "Enable notifications for this task"
3. Save (or "Save for all instances" for recurring tasks)

Result: No notifications for lunch break, but other tasks still notify normally.

### Example 3: Mixed Notification Times
- Morning standup: 5 minutes before (custom)
- Client call: 30 minutes before (custom)
- Code review: 10 minutes before (global default)
- Coffee break: No notifications (disabled)

Each task can have its own notification preference!

## Technical Details

### Notification Priority
The system checks notifications in this order:
1. **Global notifications disabled?** → No notifications for any task
2. **Task notifications disabled?** → No notification for this task
3. **Custom time set?** → Use custom time
4. **No custom time?** → Use global default time

### Recurring Tasks
When you edit a recurring task:
- **"Save"**: Changes apply only to this instance
- **"Save for all instances"**: Changes apply to all future instances

Notification settings are included in both save operations.

### Data Persistence
Notification settings are:
- Saved to Firebase with the task
- Preserved across app restarts
- Synced across devices (if using Firebase sync)

## Console Logs for Debugging

When scheduling notifications, you'll see logs like:
```
📅 Scheduling notification for Task Name at 2026-01-07 11:30:00 (30 min before)
✓ Scheduled notification for task "Task Name" at 2026-01-07 11:30:00 (30 min before)
```

If notifications are disabled for a task:
```
⚠️ Notifications disabled for task: Task Name
```

If using global default:
```
📅 Scheduling notification for Task Name at 2026-01-07 11:50:00 (10 min before)
```

## UI Screenshots Description

### Notifications Section in Task Edit Dialog
```
┌─────────────────────────────────────┐
│ Notifications                       │
├─────────────────────────────────────┤
│ ☑ Enable notifications for this    │
│   task                              │
│   You will be notified before this  │
│   task starts                       │
│                                     │
│ ☑ Custom notification time          │
│   Using custom time for this task   │
│                                     │
│ Notify me before task starts:       │
│                                     │
│ [1 min] [5 min] [10 min] [15 min]  │
│ [30 min] [60 min]                   │
│                                     │
│ Custom: ─────●────────── 30 min     │
└─────────────────────────────────────┘
```

### When Notifications Disabled
```
┌─────────────────────────────────────┐
│ Notifications                       │
├─────────────────────────────────────┤
│ ☐ Enable notifications for this    │
│   task                              │
│   No notifications for this task    │
└─────────────────────────────────────┘
```

### Using Global Default
```
┌─────────────────────────────────────┐
│ Notifications                       │
├─────────────────────────────────────┤
│ ☑ Enable notifications for this    │
│   task                              │
│   You will be notified before this  │
│   task starts                       │
│                                     │
│ ☐ Custom notification time          │
│   Using global default (10 min)     │
└─────────────────────────────────────┘
```

## Common Use Cases

### 1. Work vs Personal Tasks
- Work tasks: 15 minutes notice (custom)
- Personal tasks: 5 minutes notice (custom)
- Breaks: No notifications (disabled)

### 2. Task Importance Levels
- Critical: 60 minutes notice
- Important: 30 minutes notice
- Normal: 10 minutes notice (global default)
- Low priority: No notifications

### 3. Task Types
- Meetings: 30 minutes (need prep time)
- Quick calls: 5 minutes
- Deep work sessions: 15 minutes (time to wrap up current work)
- Reminders: Notifications disabled (just visual cues)

## Troubleshooting

### Notifications Not Working for Specific Task
1. Check if task notifications are enabled in the task edit dialog
2. Check if global notifications are enabled in Settings
3. Check Android notification permissions
4. Look at console logs for error messages

### Custom Time Not Being Used
1. Ensure "Custom notification time" checkbox is checked
2. Verify the minutes value is greater than 0
3. Check that the task start time is in the future
4. Save the task after making changes

### Recurring Task Notifications Inconsistent
- Use "Save for all instances" to apply notification settings to all future instances
- "Save" only affects the current instance

## Best Practices

1. **Set Global Default First**: Choose a reasonable default (10-15 minutes) that works for most tasks
2. **Use Custom Times Sparingly**: Only override for tasks that truly need different timing
3. **Disable for Routine Tasks**: Turn off notifications for tasks you do automatically
4. **Test Your Settings**: Create a test task 5 minutes in the future to verify notifications work
5. **Review Periodically**: Adjust notification settings as your needs change

## Related Documentation
- See `NOTIFICATION_FIXES_APPLIED.md` for Android notification setup and troubleshooting
- See Settings dialog for global notification preferences
- See Task model documentation for technical implementation details
