# Firebase Setup Required

## Current Issue
```
❌ Error: [firebase_auth/configuration-not-found]
❌ Error: [cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## Root Cause
Firebase Authentication is **not enabled** in your Firebase project. Without authentication, Firestore denies all read/write operations due to security rules.

## Solution: Enable Anonymous Authentication

### Step 1: Go to Firebase Console
1. Open https://console.firebase.google.com/
2. Select your project (the one you're using for this app)

### Step 2: Enable Authentication
1. In the left sidebar, click **"Authentication"**
2. If you see a "Get Started" button, click it
3. Click on the **"Sign-in method"** tab at the top

### Step 3: Enable Anonymous Provider
1. Find **"Anonymous"** in the list of providers
2. Click on it
3. Toggle the **"Enable"** switch to ON
4. Click **"Save"**

### Step 4: Verify Firestore Rules
1. In the left sidebar, click **"Firestore Database"**
2. Click on the **"Rules"** tab
3. Make sure your rules look like this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

4. If different, update them and click **"Publish"**

### Step 5: Test the App
1. Hot reload your app (press `r` in the terminal)
2. Or fully restart (press `R` in the terminal)
3. Check the console logs - you should now see:
```
✓ Signed in anonymously: [user-id]
```

## Why This Is Needed

### Authentication
- Firebase requires users to be authenticated before accessing Firestore
- Anonymous authentication creates a unique user ID without requiring login
- Each device/browser gets its own anonymous user ID

### Security Rules
- Firestore rules prevent unauthorized access to data
- The rules ensure users can only access their own data
- Without authentication, all requests are denied

## Alternative: Test Without Authentication

If you want to test the app without setting up authentication, you can temporarily change the Firestore rules to allow public access (NOT RECOMMENDED for production):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // ⚠️ INSECURE - Anyone can access
    }
  }
}
```

**WARNING**: This makes your database publicly accessible. Only use for testing, and change it back immediately after.

## After Setup

Once authentication is enabled:
1. The app will automatically sign in users anonymously
2. Tasks will be saved to Firestore under `users/{userId}/tasks`
3. Side tasks will be saved under `users/{userId}/sideTasks`
4. Each device will have its own set of tasks (different user IDs)

## Troubleshooting

### Still getting permission denied after enabling auth?
- Make sure you published the Firestore rules
- Try a hard refresh of the app (Ctrl+Shift+R in browser)
- Check the console for the user ID - it should not be 'local_user'

### Want to share tasks across devices?
- You'll need to implement email/password authentication
- Or use Google Sign-In
- Then users can sign in on multiple devices with the same account

### Need help?
Share the console output after enabling anonymous auth, and I can help debug further!
