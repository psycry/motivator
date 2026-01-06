# Firebase Setup Instructions

This application uses Firebase Cloud Firestore as the backend for storing and syncing tasks across devices.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. FlutterFire CLI installed

## Setup Steps

### 1. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 2. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., "motivator-app")
4. Follow the setup wizard
5. Enable Google Analytics (optional)

### 3. Configure Firebase for Your App

Run the FlutterFire configuration command:

```bash
flutterfire configure
```

This will:
- Prompt you to select your Firebase project
- Automatically generate `firebase_options.dart` with your project's configuration
- Register your app with Firebase for all platforms (Android, iOS, Web, etc.)

### 4. Enable Cloud Firestore

1. In Firebase Console, go to "Build" → "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a Cloud Firestore location
5. Click "Enable"

### 5. Set Up Firestore Security Rules

In the Firebase Console, go to Firestore → Rules and update them:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to authenticated users
    match /users/{userId}/{document=**} {
      allow read, write: if true; // Change this for production!
    }
  }
}
```

**Note:** The above rules allow anyone to read/write. For production, implement proper authentication.

### 6. Install Dependencies

```bash
flutter pub get
```

### 7. Run the App

```bash
flutter run
```

## Data Structure

The app stores data in Firestore with the following structure:

```
users/
  └── {userId}/
      ├── tasks/
      │   └── {dateKey}_{taskId}/
      │       ├── id
      │       ├── title
      │       ├── startTime
      │       ├── duration
      │       ├── scheduledDuration
      │       ├── trackedDuration
      │       ├── lateTrackedDuration
      │       ├── startedLate
      │       ├── isTracking
      │       ├── trackingStart
      │       ├── isCompleted
      │       └── trackingSegments[]
      └── sideTasks/
          └── {taskId}/
              └── (same structure as tasks)
```

## User Authentication (Optional)

Currently, the app uses a default user ID (`default_user`). To add proper authentication:

1. Enable Firebase Authentication in the Firebase Console
2. Install `firebase_auth` package:
   ```bash
   flutter pub add firebase_auth
   ```
3. Update `main.dart` to replace `'default_user'` with the actual authenticated user's ID

## Troubleshooting

### "Firebase not initialized" error
- Make sure you ran `flutterfire configure`
- Check that `firebase_options.dart` exists and has valid configuration

### "Permission denied" error
- Check your Firestore security rules
- Ensure you're using the correct user ID

### Data not syncing
- Check your internet connection
- Verify Firestore is enabled in Firebase Console
- Check the browser console or device logs for errors

## Features

- ✅ Automatic data persistence to Firebase
- ✅ Multi-device sync (tasks sync across all devices)
- ✅ Offline support (Firestore caches data locally)
- ✅ Real-time updates (changes sync instantly)
- ✅ Task history preserved across dates
- ✅ Side tasks storage separate from timeline tasks

## Next Steps

1. Implement user authentication
2. Add data validation
3. Implement proper security rules
4. Add error handling UI
5. Add sync status indicators
6. Implement conflict resolution for simultaneous edits
