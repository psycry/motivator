# Debug Steps - Tasks Not Saving to Firebase

## Changes Made
1. ✅ Fixed Firebase queries to use `dateKey` field instead of task `id`
2. ✅ Added `_saveSideTasksToFirebase()` call when creating new tasks
3. ✅ Added comprehensive debug logging throughout save/load operations
4. ✅ Enhanced startup logging to track Firebase initialization and data loading

## How to Test

### Step 0: Check Startup Logs
When the app starts, you should see:
```
========================================
MOTIVATOR APP STARTING
========================================
Initializing Firebase...
✓ Firebase initialized successfully
=== INITIALIZING AUTH ===
Signing in anonymously...
✓ Signed in anonymously: [user-id]
Initializing Firebase service for user: [user-id]
=== LOADING TASKS FROM FIREBASE ===
Calling loadAllTasks()...
Loading all tasks from Firebase...
Found 0 total task documents
✓ loadAllTasks() returned 0 date(s)
Calling loadSideTasks()...
Loading side tasks from Firebase...
Found 0 side tasks
✓ loadSideTasks() returned 0 tasks
=== LOAD COMPLETE ===
✓ Tasks loaded from Firebase successfully
✓ Total: 0 date(s) with tasks, 0 side tasks
```

### Step 1: Hot Reload
Press `r` in the terminal where Flutter is running to hot reload the changes.

### Step 2: Create a New Task
1. Click the **+** button in the app
2. Enter a task title (e.g., "Test Task")
3. Set a time and duration
4. Click **Create**

### Step 3: Check Console Output
You should see logs like:
```
_saveSideTasksToFirebase called for 1 side tasks
Batch saving 1 side tasks
Deleting 0 existing side tasks
  - Adding side task 1735024801000 (Test Task)
Side tasks batch commit completed
_saveSideTasksToFirebase completed successfully
```

### Step 4: Drag Task to Timeline
1. Drag the task from the side panel to the timeline
2. Check console for:
```
_saveTasksToFirebase called for 1 tasks
Saving 1 tasks for date 2025-12-24 (dateKey: 20251224)
Deleting 0 existing tasks
  - Adding task 1735024801000 (Test Task) to document 20251224_1735024801000
Batch commit completed
_saveTasksToFirebase completed successfully
```

### Step 5: Verify Persistence
1. Press `R` in terminal (capital R) to restart the app
2. Check console for:
```
Loading all tasks from Firebase...
Found 1 total task documents
  - Document: 20251224_1735024801000
Loaded tasks for 1 dates
Loading side tasks from Firebase...
Found 0 side tasks
```

### Step 6: Check Firebase Console
1. Go to Firebase Console → Firestore Database
2. Navigate to: `users/{your-user-id}/tasks`
3. You should see a document with ID like: `20251224_1735024801000`
4. The document should contain:
   - `dateKey: "20251224"`
   - `title: "Test Task"`
   - `id: "1735024801000"`
   - All other task fields

## If Still Not Working

### Check for Errors
Look for any error messages in the console, especially:
- Permission denied errors
- Network errors
- Timeout errors

### Verify Firebase Connection
The console should show at startup:
```
Firebase initialized successfully
Signed in anonymously: [user-id]
```

### Check User ID
The user ID in the logs should match the path in Firebase Console.

### Common Issues
1. **No logs appearing**: The hot reload didn't work - try full restart (press `R`)
2. **Permission denied**: Check Firebase rules allow write access
3. **Timeout errors**: Network issue or Firebase not configured properly
4. **No user ID**: Authentication failed - check Firebase Auth is enabled

## Firebase Rules
Make sure your Firestore rules allow authenticated users to write:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
