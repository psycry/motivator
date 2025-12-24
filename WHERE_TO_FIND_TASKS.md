# Where to Find Your Tasks in Firestore

## Important: Tasks are NOT in a "tasks" collection at root level!

### ❌ WRONG - Don't look here:
```
Firestore Database
├── tasks/          ← NOT HERE!
└── sideTasks/      ← NOT HERE!
```

### ✅ CORRECT - Look here:
```
Firestore Database
└── users/                    ← Start here
    └── {your-user-id}/       ← Your specific user document
        ├── tasks/            ← Timeline tasks are HERE
        └── sideTasks/        ← Side panel tasks are HERE
```

## Step-by-Step: How to Find Your Tasks

### Step 1: Go to Firestore Console
https://console.firebase.google.com/project/motivator-web/firestore

### Step 2: Look for "users" Collection
In the left panel, you should see:
- **Start collection** button (if empty)
- OR a list of collections including **"users"**

### Step 3: Click on "users"
This opens the users collection showing all user documents.

### Step 4: Find YOUR User Document
Look for a document with a long ID like:
- `abc123def456ghi789...`
- This is your Firebase Auth user ID

**How to find your user ID:**
1. Look at top-right of the app - you'll see your email
2. Open browser console (F12)
3. Look for: `✓ User authenticated: [YOUR-USER-ID]`
4. Copy that ID

### Step 5: Click on Your User Document
Once you click on your user ID document, you'll see:
- Document fields (uid, email, displayName, etc.)
- **Subcollections** section below

### Step 6: Look in Subcollections
You should see:
- **tasks** - Click to see timeline tasks
- **sideTasks** - Click to see side panel tasks

## Visual Guide

```
Firebase Console
│
└─ Firestore Database
   │
   └─ users (collection)
      │
      ├─ abc123... (your user document)
      │  │
      │  ├─ Fields:
      │  │  ├─ uid: "abc123..."
      │  │  ├─ email: "you@example.com"
      │  │  ├─ createdAt: "2025-12-24..."
      │  │  └─ lastLoginAt: "2025-12-24..."
      │  │
      │  └─ Subcollections:
      │     │
      │     ├─ tasks (subcollection) ← YOUR TIMELINE TASKS
      │     │  ├─ 20251224_1234567890
      │     │  ├─ 20251224_9876543210
      │     │  └─ ...
      │     │
      │     └─ sideTasks (subcollection) ← YOUR SIDE PANEL TASKS
      │        ├─ 1735027200000
      │        ├─ 1735113600000
      │        └─ ...
      │
      └─ xyz789... (another user's document)
         └─ ... (their tasks)
```

## What Each Document Contains

### tasks/ (Timeline Tasks)
Document ID format: `{dateKey}_{taskId}`
Example: `20251224_1735027200000`

Fields:
- `id`: Task ID
- `title`: Task name
- `startTime`: When task starts
- `duration`: How long (in seconds)
- `dateKey`: Date in YYYYMMDD format
- `isCompleted`: true/false
- `isRecurring`: true/false
- etc.

### sideTasks/ (Side Panel Tasks)
Document ID format: `{taskId}`
Example: `1735027200000`

Fields:
- `id`: Task ID
- `title`: Task name
- `startTime`: When task starts
- `duration`: How long (in seconds)
- `isRecurring`: true/false
- `recurringStartDate`: If recurring
- `recurringEndDate`: If recurring
- etc.

## Common Mistakes

### ❌ Mistake 1: Looking at Root Level
Don't look for a "tasks" collection at the root of Firestore.
Tasks are inside `users/{userId}/tasks`

### ❌ Mistake 2: Wrong User ID
Make sure you're looking at YOUR user document.
Check the console for your actual user ID.

### ❌ Mistake 3: Not Expanding Subcollections
User documents have fields AND subcollections.
Scroll down to see the "Subcollections" section.

### ❌ Mistake 4: Wrong Project
Make sure you're in the **motivator-web** project.
Check the project name at the top of Firebase Console.

## Quick Check

### In Your App:
1. Create a test task: "Find Me"
2. Note the time you created it
3. Drag it to the timeline

### In Firestore Console:
1. Go to `users` collection
2. Find your user ID document
3. Click on it
4. Scroll to "Subcollections"
5. Click "tasks"
6. Look for a document with today's date
7. Click on it - you should see "Find Me" in the title field

## Still Can't Find It?

### Check Console Output
Open browser console and look for:
```
=== SAVING TASKS TO FIREBASE ===
User ID: abc123def456...        ← Copy this ID
Date: 2025-12-24
DateKey: 20251224
Number of tasks: 1
  - Adding task 1735027200000 (Find Me) to document 20251224_1735027200000
✓ Batch commit completed successfully
```

Then in Firestore:
1. Go to `users` collection
2. Find document `abc123def456...` (the User ID from console)
3. Click on it
4. Look in subcollections → tasks
5. Find document `20251224_1735027200000`

## Summary

**Path to your tasks:**
```
users → {your-user-id} → tasks (subcollection)
```

**NOT:**
```
tasks (at root level) ← Wrong!
```

Your tasks are **nested inside your user document** for security and organization! 🔒
