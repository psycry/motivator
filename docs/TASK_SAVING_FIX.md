# Task Saving Fix

## Issues Fixed

### 1. Firebase Service Initialization
**Problem:** `_firebaseService` was declared as `late` but could be accessed before initialization, causing crashes.

**Solution:** Changed to nullable `FirebaseService?` and added null checks before all Firebase operations.

### 2. Enhanced Debug Logging
**Problem:** Hard to diagnose why tasks weren't saving.

**Solution:** Added comprehensive logging in `firebase_service.dart`:
- User ID
- Date and dateKey
- Number of tasks
- Individual task details
- Success/error messages

## Changes Made

### `lib/main.dart`
- Changed `late FirebaseService _firebaseService` → `FirebaseService? _firebaseService`
- Added null checks in `_saveTasksToFirebase()`
- Added null checks in `_saveSideTasksToFirebase()`
- Added null checks in `_clearAllTasks()`
- Increased timeout from 3s to 5s for better reliability

### `lib/services/firebase_service.dart`
- Added detailed logging to `saveTasksForDate()`
- Added detailed logging to `saveSideTasks()`
- Added try-catch blocks with stack traces
- Added task data preview in logs

## How to Test

### 1. Check Browser Console
After hot reload, you should see detailed logs:

**When creating a task:**
```
=== SAVING SIDE TASKS TO FIREBASE ===
User ID: abc123...
Number of side tasks: 1
  - Adding side task 1234567890 (My Task)
✓ Side tasks batch commit completed successfully
=== SIDE TASKS SAVE COMPLETE ===
```

**When moving task to timeline:**
```
=== SAVING TASKS TO FIREBASE ===
User ID: abc123...
Date: 2025-12-24
DateKey: 20251224
Number of tasks: 1
  - Adding task 1234567890 (My Task) to document 20251224_1234567890
    Task data: {id: 1234567890, title: My Task, startTime: 2025-12-24T10:00:00.000...
✓ Batch commit completed successfully
=== SAVE COMPLETE ===
```

### 2. Check Firestore Console
1. Go to Firebase Console → Firestore Database
2. Navigate to: `users → {your-user-id} → tasks` or `sideTasks`
3. You should see documents appearing in real-time

### 3. Test Scenarios

**Create a new task:**
1. Click "+" button in side panel
2. Fill in task details
3. Click "Create"
4. Check console for "SAVING SIDE TASKS" logs
5. Check Firestore for new document in `sideTasks` collection

**Drag task to timeline:**
1. Drag a task from side panel to timeline
2. Check console for "SAVING TASKS" logs
3. Check Firestore for new document in `tasks` collection

**Edit a task:**
1. Click on a task
2. Edit details
3. Save
4. Check console for save logs
5. Verify changes in Firestore

## Common Issues

### "Firebase service not initialized yet"
**Cause:** Trying to save before authentication completes
**Solution:** This is normal on first load - tasks will save once initialized
**Action:** None needed - this is expected behavior

### "Permission denied"
**Cause:** Firestore security rules not deployed
**Solution:** Run `firebase deploy --only firestore:rules`
**Verify:** Check Firebase Console → Firestore → Rules tab

### "Timeout"
**Cause:** Slow network or Firestore connection issues
**Solution:** Increased timeout to 5 seconds
**Action:** Check internet connection

### Tasks not appearing in Firestore
**Check:**
1. User is signed in (check console for user ID)
2. Security rules are deployed
3. No errors in browser console
4. Correct project selected in Firebase Console

## Debugging Commands

### Check if Firebase is initialized:
Look for in console:
```
✓ User authenticated: {user-id}
Initializing Firebase service for user: {user-id}
```

### Check if tasks are being saved:
Look for in console:
```
_saveTasksToFirebase called for X tasks
=== SAVING TASKS TO FIREBASE ===
```

### Check for errors:
Look for in console:
```
❌ Could not save to Firebase: ...
❌ Error saving tasks: ...
```

## Next Steps

1. **Hot reload the app** - Press `r` in terminal
2. **Create a test task** - Use the "+" button
3. **Watch the console** - Look for detailed save logs
4. **Check Firestore** - Verify data appears
5. **Report any errors** - Share console output if issues persist

The enhanced logging will help identify exactly where the save process is failing (if it is).
