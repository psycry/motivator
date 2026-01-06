# Firestore Security Rules Update

## Issue
You're getting a permission denied error when trying to save/load notes:
```
Error loading notes: [cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## Solution
Update your Firestore security rules to allow access to the `notes` collection.

## How to Update Rules

### **Step 1: Go to Firebase Console**
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on **Firestore Database** in the left menu
4. Click on the **Rules** tab

### **Step 2: Update the Rules**

Replace your current rules with these updated rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User data - only accessible by the user
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Tasks collection
      match /tasks/{taskId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Side tasks collection
      match /sideTasks/{taskId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Notes collection - ADD THIS
      match /notes/{noteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### **Step 3: Publish the Rules**
1. Click **Publish** button
2. Wait a few seconds for changes to propagate
3. Restart your app

## What This Does

The new rule allows authenticated users to:
- ✅ Read their own notes
- ✅ Write/update their own notes
- ❌ Cannot access other users' notes
- ❌ Cannot access notes without authentication

## Current Rules Structure

After this update, your Firestore will have:

```
users/
  {userId}/
    - User profile document
    tasks/
      - Task documents
    sideTasks/
      - Side task documents
    notes/          ← NEW!
      scratch_notes ← Your notes document
```

## Verify It Works

After updating the rules:

1. Restart your app
2. Open the notes widget (bottom middle)
3. Type some notes
4. Should see "Auto-saved" in the footer
5. Refresh the app - notes should persist!

## Alternative: More Permissive Rules (Development Only)

If you're just developing and want to test quickly, you can use these rules (NOT for production):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**⚠️ Warning**: These rules allow any authenticated user to read/write ANY document. Only use for development!

## Troubleshooting

### **Still getting permission denied?**
1. Make sure you clicked "Publish" in Firebase Console
2. Wait 30 seconds for rules to propagate
3. Sign out and sign back in to your app
4. Check that you're signed in (email should show in app bar)

### **Rules not saving?**
1. Check for syntax errors in the rules editor
2. Firebase will highlight any errors
3. Make sure all brackets `{}` are properly closed

### **Want to test rules?**
Firebase Console has a "Rules Playground" where you can test your rules before publishing.

## Security Best Practices

✅ **DO**:
- Use user ID matching: `request.auth.uid == userId`
- Require authentication: `request.auth != null`
- Validate data types and structure
- Use the principle of least privilege

❌ **DON'T**:
- Allow public read/write access in production
- Trust client-side validation only
- Store sensitive data without encryption
- Use `allow read, write: if true;` in production
