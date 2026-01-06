# Firebase Tasks Not Showing - Fix Applied

## Problem
Tasks were not appearing in the database because the Firebase queries were using the wrong field to filter tasks by date.

## Root Cause
The code was querying on the task's `id` field (which is a timestamp like `1735024801000`), but it should have been querying on a date-specific field. The document IDs were structured as `${dateKey}_${taskId}` (e.g., `20251224_1735024801000`), but the query was looking at the wrong field inside the document.

## Fix Applied
1. **Added `dateKey` field**: Modified `saveTask()` and `saveTasksForDate()` to include a `dateKey` field in each task document
2. **Updated queries**: Changed all queries from filtering on `id` field to filtering on `dateKey` field:
   - `loadTasksForDate()` - now uses `where('dateKey', isEqualTo: dateKey)`
   - `streamTasksForDate()` - now uses `where('dateKey', isEqualTo: dateKey)`
   - `saveTasksForDate()` - now uses `where('dateKey', isEqualTo: dateKey)` to delete old tasks
3. **Added debug logging**: Added print statements to track what's being saved and loaded

## What to Check
1. **Run the app** and check the debug console for logs like:
   - "Saving X tasks for date..."
   - "Loading all tasks from Firebase..."
   - "Found X total task documents"

2. **Create a new task** and verify:
   - You see "Saving 1 tasks for date..." in the console
   - The task appears in the timeline
   - The task persists after restarting the app

3. **Check Firebase Console**:
   - Go to Firestore Database
   - Navigate to: `users/{userId}/tasks`
   - You should see documents with IDs like `20251224_1735024801000`
   - Each document should have a `dateKey` field (e.g., `20251224`)

## Existing Data
⚠️ **Important**: Any tasks saved before this fix will NOT have the `dateKey` field and won't be loaded by the new queries. You have two options:

### Option 1: Clear and Start Fresh (Recommended)
Use the "Clear All Tasks" option in the app menu to delete old data and start fresh.

### Option 2: Migrate Existing Data
If you have important data, you'll need to add the `dateKey` field to existing documents:
1. Go to Firebase Console
2. For each document in `users/{userId}/tasks`:
   - Extract the date from the document ID (first 8 characters)
   - Add a field: `dateKey` = extracted date (e.g., "20251224")

## Testing
1. Clear all tasks (if you have old data without `dateKey`)
2. Create a new task in the side panel
3. Drag it to the timeline
4. Check console logs - you should see "Saving 1 tasks..."
5. Refresh the app (hot reload or restart)
6. Check console logs - you should see "Found X total task documents"
7. Verify the task appears in the timeline

## Firebase Index
The query uses a simple equality check on `dateKey`, which should work without a composite index. If Firebase prompts you to create an index, follow the link it provides.
