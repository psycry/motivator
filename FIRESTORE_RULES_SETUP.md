# Firestore Security Rules Setup

## Problem
Your app can't write data to Firestore because the default security rules **deny all access**.

## Solution
Update your Firestore security rules to allow authenticated users to access their own data.

## Step-by-Step Instructions

### Option 1: Deploy Rules from File (Recommended)

1. **Open Terminal** in your project directory

2. **Deploy the rules** using Firebase CLI:
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Verify deployment** - You should see:
   ```
   ✔  Deploy complete!
   ```

### Option 2: Update Rules in Firebase Console (Manual)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project: **motivator-web**

2. **Navigate to Firestore Database**
   - Click **"Firestore Database"** in the left sidebar
   - Click the **"Rules"** tab at the top

3. **Replace the existing rules** with:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users collection - users can only access their own data
       match /users/{userId} {
         // Allow read/write if the user is authenticated and accessing their own document
         allow read, write: if request.auth != null && request.auth.uid == userId;
         
         // User's tasks subcollection
         match /tasks/{taskId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
         
         // User's side tasks subcollection
         match /sideTasks/{taskId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
   }
   ```

4. **Click "Publish"**

5. **Confirm** - Click "Publish" again in the confirmation dialog

## What These Rules Do

### Security Features:
✅ **Authenticated users only** - Must be signed in to access data
✅ **User isolation** - Users can only access their own data
✅ **No cross-user access** - User A cannot read User B's data
✅ **Subcollection protection** - Tasks and side tasks are also protected

### Data Structure Protected:
```
users/
  └── {userId}/              ← User can only access if userId matches their auth.uid
      ├── (user profile)
      ├── tasks/             ← User's timeline tasks
      │   └── {taskId}
      └── sideTasks/         ← User's side panel tasks
          └── {taskId}
```

## Testing After Setup

1. **Restart your app** (hot reload is fine)

2. **Sign in** with your account

3. **Create a task** in the app

4. **Check Firestore Console**:
   - Go to Firestore Database → Data tab
   - You should see: `users → {your-user-id} → tasks → {task-id}`

5. **Check browser console** for success messages:
   ```
   ✓ _saveTasksToFirebase completed successfully
   ✓ Created new user profile for {user-id}
   ```

## Troubleshooting

### Still getting "permission-denied" errors?

**Check Authentication:**
```dart
// In browser console, check if user is signed in:
// You should see user ID in the logs
```

**Verify Rules Published:**
- Go to Firebase Console → Firestore → Rules tab
- Check that the rules match what you published
- Look for "Last published" timestamp

**Check User ID Match:**
- The `userId` in Firestore path must match `request.auth.uid`
- Your app uses `FirebaseAuth.instance.currentUser?.uid` which is correct

### Rules not deploying?

**Install Firebase CLI:**
```bash
npm install -g firebase-tools
```

**Login to Firebase:**
```bash
firebase login
```

**Initialize Firebase (if needed):**
```bash
firebase init firestore
```

**Deploy again:**
```bash
firebase deploy --only firestore:rules
```

## Current Rules File

The file `firestore.rules` has been created in your project root with the correct rules.

## Security Notes

✅ **Safe for production** - These rules are secure
✅ **User privacy** - Each user can only see their own data
✅ **No public access** - Must be authenticated
✅ **No admin backdoor** - Even you need to sign in to see data

## Next Steps

1. **Deploy the rules** using one of the methods above
2. **Restart your app**
3. **Sign in and create a task**
4. **Verify data appears in Firestore Console**

Once the rules are deployed, your app will be able to write data to Firestore! 🎉
