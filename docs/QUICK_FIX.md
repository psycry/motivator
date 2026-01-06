# Quick Fix - Enable Firebase Authentication

## The Problem
Your app logs show:
```
❌ Error: [firebase_auth/configuration-not-found]
❌ Error: [cloud_firestore/permission-denied]
```

This means **Firebase Authentication is not enabled** in your Firebase Console.

## The Solution (5 minutes)

### 1. Open Firebase Console
Go to: https://console.firebase.google.com/

### 2. Select Your Project
Click on your project name

### 3. Enable Authentication
- Click **"Authentication"** in the left sidebar
- Click **"Get Started"** (if shown)
- Click **"Sign-in method"** tab
- Find **"Anonymous"** in the list
- Click on it
- Toggle **"Enable"** to ON
- Click **"Save"**

### 4. Reload Your App
Press `r` in your Flutter terminal to hot reload

### 5. Verify It Works
You should now see in the console:
```
✓ Signed in anonymously: [user-id]
✓ _saveSideTasksToFirebase completed successfully
✓ _saveTasksToFirebase completed successfully
```

## That's It!

Once anonymous auth is enabled:
- ✅ Tasks will save to Firebase
- ✅ Tasks will persist across app restarts
- ✅ Each device gets its own set of tasks
- ✅ Your data is secure (only you can access it)

## Still Having Issues?

If you still see permission errors after enabling auth:
1. Make sure you clicked "Save" in the Firebase Console
2. Try a full restart: Press `R` (capital R) in the terminal
3. Check that Firestore rules allow authenticated users (see FIREBASE_SETUP_REQUIRED.md)

## Need More Details?

See `FIREBASE_SETUP_REQUIRED.md` for:
- Detailed screenshots
- Firestore rules configuration
- Troubleshooting steps
- Alternative testing options
