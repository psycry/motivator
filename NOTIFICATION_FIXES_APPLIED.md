# Android Notification Fixes Applied

## Issues Identified
The notifications were not triggering on Android devices due to missing permissions and configuration in the AndroidManifest.xml file.

## ✨ NEW: Per-Task Notification Customization
In addition to the Android fixes below, you can now customize notifications for individual tasks! See `PER_TASK_NOTIFICATIONS.md` for details on:
- Disabling notifications for specific tasks
- Setting custom notification times per task
- Overriding global settings on a per-task basis

## Fixes Applied

### 1. AndroidManifest.xml - Added Required Permissions
Added the following critical permissions:
- `POST_NOTIFICATIONS` - Required for Android 13+ to show notifications
- `SCHEDULE_EXACT_ALARM` - Required for exact scheduled notifications
- `USE_EXACT_ALARM` - Alternative permission for exact alarms
- `RECEIVE_BOOT_COMPLETED` - To reschedule notifications after device reboot
- `VIBRATE` - For notification vibration
- `WAKE_LOCK` - To wake device for notifications

### 2. AndroidManifest.xml - Added Notification Receivers
Added two broadcast receivers:
- `ScheduledNotificationBootReceiver` - Handles notification rescheduling after device reboot
- `ScheduledNotificationReceiver` - Handles the actual scheduled notifications

### 3. NotificationService - Enhanced Permission Handling
- Added explicit permission request for exact alarms (Android 12+)
- Added `areNotificationsEnabled()` method to check notification status
- Added permission check before scheduling notifications
- Added better logging for debugging

### 4. NotificationService - Added Debugging Tools
- Added `getPendingNotifications()` method to list all pending notifications
- Enhanced logging throughout the service
- Added immediate notification test capability

## Testing Instructions

### Step 1: Rebuild the App
Since we modified the AndroidManifest.xml, you need to rebuild the app:
```bash
flutter clean
flutter pub get
flutter run
```

### Step 2: Grant Permissions
When you first open the app after rebuilding:
1. The app will request notification permissions - **GRANT IT**
2. On Android 12+, it may also request exact alarm permissions - **GRANT IT**
3. If you miss the permission prompt, go to:
   - Settings → Apps → Motivator → Permissions
   - Enable "Notifications"
   - Settings → Apps → Motivator → Alarms & reminders → Enable

### Step 3: Test Immediate Notification
To verify notifications work at all, you can test with an immediate notification.
Add this test button temporarily to your UI or call from debug console:
```dart
NotificationService().showImmediateNotification(
  title: 'Test Notification',
  body: 'If you see this, notifications are working!',
);
```

### Step 4: Test Scheduled Notifications
1. Create a task with a start time 5-10 minutes in the future
2. Make sure notifications are enabled in settings
3. Check the console logs for:
   - "✓ Scheduled notification for task..."
   - The scheduled time should be shown
4. Wait for the notification to appear

### Step 5: Verify Pending Notifications
Check what notifications are scheduled:
```dart
final pending = await NotificationService().getPendingNotifications();
print('Pending: ${pending.length} notifications');
```

## Common Issues & Solutions

### Issue: "Notifications are not enabled" message in logs
**Solution**: Go to device Settings → Apps → Motivator → Notifications and enable them

### Issue: Notifications scheduled but never appear
**Solution**: 
1. Check if "Alarms & reminders" permission is granted (Android 12+)
2. Go to Settings → Apps → Motivator → Battery → Unrestricted
3. Disable battery optimization for the app

### Issue: Notifications work but not at exact time
**Solution**: Grant "Alarms & reminders" permission in app settings

### Issue: Notifications stop working after device reboot
**Solution**: This should be fixed with the boot receiver. If still an issue:
1. Check if "Autostart" permission is granted (some manufacturers)
2. Check battery optimization settings

## Verification Checklist
- [ ] App builds without errors after changes
- [ ] Permission dialogs appear on first launch
- [ ] Immediate test notification appears
- [ ] Scheduled notifications appear at correct time
- [ ] Notifications persist after app is closed
- [ ] Notifications work after device reboot
- [ ] Console logs show successful scheduling

## Additional Notes

### Battery Optimization
Some Android manufacturers (Samsung, Xiaomi, Huawei, etc.) have aggressive battery optimization that can kill background tasks. Users may need to:
1. Disable battery optimization for the app
2. Add app to "Protected apps" or "Autostart" list
3. Set battery usage to "Unrestricted"

### Android 13+ Specific
Android 13 introduced runtime notification permissions. The app now properly requests this permission, but users must grant it for notifications to work.

### Exact Alarms
Android 12+ requires explicit permission for exact alarms. The app now requests this permission, which is necessary for notifications to trigger at the precise scheduled time.

## Debug Logs to Watch For

Successful initialization:
```
✓ NotificationService initialized
📱 Android notification permission granted: true
⏰ Android exact alarm permission granted: true
```

Successful scheduling:
```
📅 Scheduling notification for [Task Name] at [Time] (local time)
✓ Scheduled notification for task "[Task Name]" at [Time]
```

Permission issues:
```
⚠️ Notifications are not enabled. Please enable them in settings.
📱 Android notifications enabled: false
```
