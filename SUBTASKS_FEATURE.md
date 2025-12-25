# Sub-tasks Feature

## Overview
Tasks now support sub-tasks, allowing you to break down larger tasks into smaller, manageable items.

## How to Use

### Adding Sub-tasks
1. **Open a task**: Click/tap on any task in the timeline or side panel
2. **Scroll down**: In the edit dialog, scroll to the "Sub-tasks" section
3. **Add a sub-task**: Click the "Add Sub-task" button
4. **Enter details**: Type the sub-task description and click "Add"

### Managing Sub-tasks
- **Check off completed sub-tasks**: Click the checkbox next to a sub-task to mark it as complete
- **Delete sub-tasks**: Click the delete icon (trash can) next to any sub-task to remove it
- **View progress**: Completed sub-tasks will show with a strikethrough

### Persistence
- Sub-tasks are automatically saved to Firebase along with the parent task
- Sub-tasks persist across app restarts and sync across devices
- Each sub-task has a unique ID and tracks its completion status independently

### Recurring Tasks with Sub-tasks
When a task with sub-tasks is set to repeat:
- **All sub-tasks are copied** to each recurring instance
- **Each instance is independent**: Completing a sub-task in one instance doesn't affect other instances
- **Fresh start**: All sub-tasks start as uncompleted in each new instance
- **Example**: If you have a "Morning Routine" task with sub-tasks "Brush teeth", "Exercise", "Breakfast", each day's instance will have all three sub-tasks ready to check off

### Editing Recurring Tasks
When you edit a recurring task, you have two save options:

1. **Save** (regular button):
   - Updates only the current instance
   - Changes won't affect other instances of the recurring task
   - Use this when you want to modify just one occurrence

2. **Save for all instances** (appears for recurring tasks):
   - Updates ALL instances of the recurring task (past, present, and future)
   - Changes include: title, time, duration, and sub-tasks
   - Sub-task completion status is preserved where possible
   - Use this when you want to modify the entire series

## Technical Details

### Data Model
- **SubTask class**: Contains `id`, `title`, and `isCompleted` fields
- **Task class**: Now includes a `List<SubTask> subTasks` field
- **Serialization**: Sub-tasks are serialized to/from Firebase using `toMap()` and `fromMap()` methods

### Files Modified
1. `lib/models/task.dart` - Added SubTask class and integrated it into Task model
2. `lib/main.dart` - Updated edit dialog to display and manage sub-tasks, recurring task generation, and bulk update functionality

### Recurring Task Implementation

**Initial Generation** (`_generateRecurringTaskInstances()`):
- Creates independent copies of sub-tasks for each recurring instance
- Each sub-task gets a unique ID combining the original sub-task ID with the instance date
- Sub-tasks are cloned with `isCompleted: false` to ensure fresh state
- Changes to sub-tasks in one instance don't affect other instances

**Bulk Updates** (`_updateAllRecurringInstances()`):
- Updates all instances of a recurring task across all dates
- Preserves sub-task completion status by matching sub-tasks by title
- Adds new sub-tasks to all instances if they were added to the template
- Updates task properties: title, time, duration, and recurring settings
- Automatically saves all affected dates to Firebase

### Firebase Compatibility
Sub-tasks are stored as part of the task document in Firestore, ensuring they sync properly across all devices.
