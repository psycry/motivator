# Email/Password Authentication Setup

## What Changed
The app now uses **email/password authentication** instead of anonymous login. This means:
- ✅ Users create accounts with email and password
- ✅ Tasks are tied to user accounts
- ✅ Users can access their tasks from any device by signing in
- ✅ Each user has their own private task list

## Firebase Setup Required

### Step 1: Enable Email/Password Authentication

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**
3. **Click "Authentication"** in the left sidebar
4. **Click "Get Started"** (if not already enabled)
5. **Click "Sign-in method"** tab
6. **Find "Email/Password"** in the list
7. **Click on it**
8. **Toggle "Enable"** to ON
9. **Click "Save"**

### Step 2: Verify Firestore Rules

Your Firestore rules should already be correct, but verify:

1. In Firebase Console, click **"Firestore Database"**
2. Click **"Rules"** tab
3. Ensure rules look like this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

4. Click **"Publish"** if you made changes

## How to Use the App

### First Time Users

1. **Launch the app** - You'll see the login screen
2. **Click "Sign Up"** at the bottom
3. **Enter your email and password**
4. **Confirm your password**
5. **Click "Sign Up"**
6. You'll be automatically signed in and taken to the main app

### Returning Users

1. **Launch the app**
2. **Enter your email and password**
3. **Click "Sign In"**
4. Your tasks will load automatically

### Sign Out

1. Click the **menu (⋮)** in the top right
2. Click **"Sign Out"**
3. You'll be taken back to the login screen

## Features

### Account Management
- **Email validation**: Ensures valid email format
- **Password requirements**: Minimum 6 characters
- **Error handling**: Clear error messages for common issues
- **Auto-login**: Stay signed in across app restarts

### Task Persistence
- Tasks are saved per user account
- Access your tasks from any device by signing in
- Tasks are private to your account
- Sign out to switch accounts

### Security
- Passwords are securely handled by Firebase
- Firestore rules prevent unauthorized access
- Each user can only access their own data

## Common Errors and Solutions

### "No account found with this email"
- You haven't created an account yet
- Click "Sign Up" to create a new account

### "Incorrect password"
- Check your password and try again
- Passwords are case-sensitive

### "An account already exists with this email"
- You already have an account
- Click "Sign In" instead of "Sign Up"
- Or use a different email address

### "Password should be at least 6 characters"
- Choose a longer password
- Firebase requires minimum 6 characters

### "Please enter a valid email address"
- Check your email format
- Must include @ symbol and domain

### "Network error. Please check your connection"
- Check your internet connection
- Try again when connected

## Testing the App

### Create Test Account
1. Hot reload the app: Press `r` in terminal
2. Click "Sign Up"
3. Email: `test@example.com`
4. Password: `test123`
5. Confirm password: `test123`
6. Click "Sign Up"

### Verify Tasks Persist
1. Create a task in the app
2. Click menu → "Sign Out"
3. Sign back in with same credentials
4. Your task should still be there!

### Test Multiple Accounts
1. Create account 1 and add some tasks
2. Sign out
3. Create account 2 and add different tasks
4. Sign out and back into account 1
5. You should only see account 1's tasks

## Console Logs

After enabling auth, you should see:
```
✓ Firebase initialized successfully
=== INITIALIZING FIREBASE SERVICE ===
✓ User authenticated: [user-id]
Initializing Firebase service for user: [user-id]
=== LOADING TASKS FROM FIREBASE ===
Loading all tasks from Firebase...
Found X total task documents
✓ Tasks loaded from Firebase successfully
```

## Troubleshooting

### Login screen doesn't appear
- Check that Firebase is initialized successfully
- Look for errors in console

### Can't create account
- Verify Email/Password auth is enabled in Firebase Console
- Check console for specific error messages

### Tasks don't save
- Verify Firestore rules are correct
- Check that user is authenticated (see console logs)
- Look for permission-denied errors

### Can't sign out
- Check console for errors
- Try refreshing the app

## Next Steps

1. **Hot reload**: Press `r` in terminal
2. **Create an account**: Use the sign-up form
3. **Add tasks**: Create and organize your tasks
4. **Test persistence**: Sign out and back in to verify tasks persist

Enjoy your new authenticated task management app! 🎉
