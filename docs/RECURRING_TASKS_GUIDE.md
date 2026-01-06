# Recurring Tasks Feature Guide

## Overview
You can now create tasks that repeat daily and automatically appear on your calendar every day!

## How to Create a Recurring Task

### 1. Click "Create Task" Button
In the right side panel, click the **"+ Create Task"** button.

### 2. Fill in Task Details
- **Title**: Name your task
- **Start Time**: Set the time (hour, minute, AM/PM)
- **Duration**: Set how long the task takes (hours and minutes)

### 3. Enable Daily Repeat
Check the **"Repeat Daily"** checkbox to make the task recurring.

### 4. Choose Recurrence Options

#### Option A: Indefinite Recurrence (Default)
- Leave "Set End Date" unchecked
- Task will repeat every day indefinitely
- You can stop it later by editing or deleting the task

#### Option B: Set an End Date
- Check **"Set End Date"**
- Click on the date field to open calendar picker
- Select when the task should stop repeating
- Task will appear daily from today until the end date

### 5. Create the Task
Click **"Create"** and the task will:
- Be added to your side panel
- Automatically generate instances for the next 60 days (or until end date)
- Appear on every day's timeline

## Visual Indicators

### Recurring Task Icon
Tasks with daily recurrence show a **purple repeat icon** (🔁) next to the title:
```
🔁 Morning Exercise · 7:00 AM · 30m
```

This icon appears on:
- The original recurring task in the side panel
- All generated instances on the timeline

## How It Works

### Automatic Instance Generation
When you create a recurring task:
1. The original task is stored in your side panel
2. Instances are automatically created for each day
3. Each instance has the same:
   - Title
   - Start time (adjusted to that day's date)
   - Duration
4. Each instance can be:
   - Tracked independently
   - Completed independently
   - Modified without affecting other days

### Instance Management
- **Each day is independent**: Completing Monday's instance doesn't affect Tuesday's
- **Tracking is per-instance**: Track time separately for each day
- **Modifications are local**: Editing one instance doesn't change others

## Examples

### Example 1: Morning Routine (Indefinite)
```
Title: Morning Exercise
Time: 7:00 AM
Duration: 30 minutes
Repeat Daily: ✓
Set End Date: ✗

Result: Task appears every day at 7:00 AM forever
```

### Example 2: Project Work (30 Days)
```
Title: Project Development
Time: 9:00 AM
Duration: 2 hours
Repeat Daily: ✓
Set End Date: ✓
End Date: Jan 23, 2026 (30 days from now)

Result: Task appears daily for 30 days, then stops
```

### Example 3: Medication Reminder (90 Days)
```
Title: Take Medication
Time: 8:00 AM
Duration: 5 minutes
Repeat Daily: ✓
Set End Date: ✓
End Date: Mar 24, 2026 (90 days from now)

Result: Daily reminder for 90-day prescription period
```

## Managing Recurring Tasks

### Viewing Recurring Tasks
- **Side Panel**: Shows the original recurring task with 🔁 icon
- **Timeline**: Shows instances for each day with 🔁 icon
- **Calendar**: Days with recurring task instances show orange dots

### Editing a Recurring Task
**Note**: Currently, editing affects only the specific instance, not all future occurrences.

To edit the original recurring task:
1. Find it in the side panel (has 🔁 icon)
2. Click to edit
3. Modify title, time, or duration
4. Changes apply to the template (future instances will need regeneration)

### Stopping a Recurring Task

#### Method 1: Delete from Side Panel
- Find the recurring task in side panel (🔁 icon)
- Delete it
- Existing instances remain, but no new ones are created

#### Method 2: Set an End Date
- Edit the recurring task
- Enable "Set End Date"
- Choose when to stop
- No instances will be created after that date

### Completing Recurring Task Instances
- Drag instance to "Completed Tasks" section
- Only that day's instance is marked complete
- Task still appears on other days
- Each day tracks completion independently

## Technical Details

### Data Storage
- **Original Task**: Stored in side tasks with `isRecurring: true`
- **Instances**: Stored in timeline with `recurringParentId` linking to original
- **Dates**: Each instance has its own date and time
- **Independence**: Each instance tracks its own completion, tracking, and modifications

### Generation Limits
- Instances are generated for the next **60 days** by default
- Or until the specified end date (whichever is sooner)
- This prevents excessive data generation
- New instances can be generated as needed

### Firestore Structure
```
users/
  └── {userId}/
      ├── sideTasks/
      │   └── {taskId}  ← Original recurring task
      │       ├── isRecurring: true
      │       ├── recurringStartDate: "2025-12-24"
      │       └── recurringEndDate: "2026-01-23" (or null)
      └── tasks/
          ├── {date1}_{taskId}  ← Instance for day 1
          │   └── recurringParentId: {taskId}
          ├── {date2}_{taskId}  ← Instance for day 2
          │   └── recurringParentId: {taskId}
          └── ...
```

## Best Practices

### When to Use Recurring Tasks
✅ **Good for:**
- Daily routines (exercise, meditation)
- Regular work blocks (standup meetings, focus time)
- Habit tracking (reading, journaling)
- Medication reminders
- Regular check-ins or reviews

❌ **Not ideal for:**
- One-time events
- Tasks with varying times each day
- Tasks that skip certain days (use manual creation instead)

### Tips
1. **Start with indefinite**: You can always add an end date later
2. **Use descriptive titles**: "Morning Exercise" is better than "Exercise"
3. **Set realistic durations**: Match your actual routine
4. **Review regularly**: Check if recurring tasks still serve you
5. **Complete daily**: Mark each day's instance complete for tracking

## Troubleshooting

### Task not appearing on future dates?
- Check that "Repeat Daily" was checked when creating
- Verify the end date hasn't passed
- Try navigating to future weeks to trigger generation

### Can't edit all instances at once?
- Currently, each instance is independent
- Edit the original in the side panel for future reference
- Existing instances need individual editing

### Too many recurring tasks?
- Delete from side panel to stop new instances
- Existing instances remain until manually removed
- Consider using end dates to auto-stop

### Recurring task disappeared?
- Check side panel for original task
- Verify it wasn't accidentally deleted
- Check if end date was reached

## Future Enhancements (Potential)

- Weekly recurrence (specific days of week)
- Monthly recurrence (specific day of month)
- Custom intervals (every 2 days, every 3 days)
- Bulk edit all instances
- Skip specific dates
- Pause/resume recurrence

## Summary

✅ **Create**: Check "Repeat Daily" when creating a task  
✅ **Customize**: Set an end date or leave indefinite  
✅ **Identify**: Look for the purple 🔁 icon  
✅ **Track**: Each day's instance tracks independently  
✅ **Manage**: Edit or delete from side panel  

Recurring tasks make it easy to maintain daily routines and track habits over time! 🎯
