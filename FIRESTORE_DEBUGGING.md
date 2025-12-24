# Firestore Tasks Not Showing - Debugging Guide

## Quick Checks

### 1. Check Browser Console
Open your browser's Developer Tools (F12) and look for:

**Success messages:**
```
=== SAVING TASKS TO FIREBASE ===
User ID: abc123...
✓ Batch commit completed successfully
```

**Error messages:**
```
❌ Error saving tasks: ...
❌ Permission denied
```

### 2. Verify You're Signed In
Check the top-right corner of the app - you should see your email address.

### 3. Check Firestore Console
1. Go to: https://console.firebase.google.com/
2. Select project: **motivator-web**
3. Click **Firestore Database** in left sidebar
4. Look for these collections:
   ```
   users/
     └── {your-user-id}/
         ├── tasks/
         └── sideTasks/
   ```

## Common Issues

### Issue 1: No User ID
**Symptom:** Console shows "No authenticated user found"

**Solution:**
1. Sign out and sign back in
2. Check that Firebase Auth is working
3. Verify email/password authentication is enabled in Firebase Console

### Issue 2: Permission Denied
**Symptom:** Console shows "permission-denied" error

**Solution:**
Security rules might not be deployed correctly.

Run this command:
```bash
firebase deploy --only firestore:rules
```

Or manually update rules in Firebase Console:
1. Go to Firestore Database → Rules tab
2. Paste the rules from `firestore.rules` file
3. Click "Publish"

### Issue 3: Tasks Created But Not Visible
**Symptom:** Console shows success but Firestore is empty

**Possible causes:**
1. **Wrong project selected** in Firebase Console
2. **Data in different collection** - Check all collections
3. **Browser cache** - Hard refresh (Ctrl+Shift+R)

### Issue 4: Firebase Service Not Initialized
**Symptom:** Console shows "Firebase service not initialized yet"

**Solution:**
This is normal on first load. Wait a few seconds and try creating a task again.

## Step-by-Step Verification

### Step 1: Create a Test Task
1. Click **"+ Create Task"** button
2. Enter:
   - Title: "Test Task"
   - Time: 12:00 PM
   - Duration: 1 hour
3. Click **"Create"**

### Step 2: Check Console Output
Look for these messages in order:
```
_saveSideTasksToFirebase called for 1 side tasks
=== SAVING SIDE TASKS TO FIREBASE ===
User ID: [your-user-id]
Number of side tasks: 1
  - Adding side task [task-id] (Test Task)
✓ Side tasks batch commit completed successfully
=== SIDE TASKS SAVE COMPLETE ===
```

### Step 3: Drag Task to Timeline
1. Drag "Test Task" from side panel to timeline
2. Drop it on the timeline

### Step 4: Check Console Again
Look for:
```
=== SAVING TASKS TO FIREBASE ===
User ID: [your-user-id]
Date: 2025-12-24
DateKey: 20251224
Number of tasks: 1
  - Adding task [task-id] (Test Task) to document 20251224_[task-id]
✓ Batch commit completed successfully
=== SAVE COMPLETE ===
```

### Step 5: Verify in Firestore
1. Go to Firestore Console
2. Navigate to: `users → [your-user-id] → tasks`
3. You should see a document like: `20251224_1234567890`
4. Click on it to see the task data

## Manual Firestore Check

### Find Your User ID
In browser console, look for:
```
✓ User authenticated: abc123def456...
```

Copy that ID.

### Navigate to Your Data
In Firestore Console:
1. Click on **"users"** collection
2. Find document with your user ID
3. Expand it to see subcollections:
   - **tasks** - Timeline tasks
   - **sideTasks** - Side panel tasks

### What You Should See

**In sideTasks:**
```
sideTasks/
  └── 1735027200000
      ├── id: "1735027200000"
      ├── title: "Test Task"
      ├── startTime: "2025-12-24T12:00:00.000"
      ├── duration: 3600
      ├── isRecurring: false
      └── ...
```

**In tasks:**
```
tasks/
  └── 20251224_1735027200000
      ├── id: "1735027200000"
      ├── title: "Test Task"
      ├── startTime: "2025-12-24T12:00:00.000"
      ├── dateKey: "20251224"
      └── ...
```

## Still Not Working?

### Get Detailed Logs
1. Open browser console (F12)
2. Clear console
3. Create a new task
4. Copy ALL console output
5. Share the output to diagnose the issue

### Check Network Tab
1. Open Developer Tools (F12)
2. Go to **Network** tab
3. Filter by "firestore"
4. Create a task
5. Look for requests to Firestore
6. Check if any show errors (red)

### Verify Project Configuration
Check `firebase.json`:
```json
{
  "firestore": {
    "rules": "firestore.rules"
  }
}
```

Check `firestore.rules` exists and has content.

## Quick Test Commands

### Test Firebase Connection
In browser console, paste:
```javascript
console.log('Firebase Auth:', firebase.auth().currentUser);
console.log('Firestore:', firebase.firestore());
```

### Test Write Permission
In browser console, paste:
```javascript
firebase.firestore()
  .collection('users')
  .doc(firebase.auth().currentUser.uid)
  .collection('test')
  .doc('test')
  .set({test: 'data', timestamp: new Date()})
  .then(() => console.log('✓ Write successful'))
  .catch(err => console.error('✗ Write failed:', err));
```

## Expected Behavior

### When Creating a Task:
1. Task appears in side panel immediately
2. Console shows save messages
3. Task is saved to Firestore within 1-2 seconds
4. Firestore Console shows new document

### When Dragging to Timeline:
1. Task moves from side panel to timeline
2. Console shows save messages for both collections
3. Task removed from sideTasks collection
4. Task added to tasks collection with dateKey

## Contact Information

If still not working, provide:
1. Browser console output (full log)
2. Screenshot of Firestore Console
3. Your user ID (from console)
4. Any error messages

This will help diagnose the specific issue!
