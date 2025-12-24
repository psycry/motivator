# User Table Documentation

## Overview
The app now automatically creates and maintains user profiles in Firestore whenever someone signs in or signs up.

## Firestore Structure

```
firestore/
└── users/
    └── {userId}/
        ├── uid: string
        ├── email: string
        ├── displayName: string | null
        ├── photoUrl: string | null
        ├── authProvider: string ('email' | 'google')
        ├── createdAt: ISO8601 timestamp
        └── lastLoginAt: ISO8601 timestamp
```

## User Profile Fields

| Field | Type | Description |
|-------|------|-------------|
| `uid` | String | Firebase Authentication user ID (unique) |
| `email` | String | User's email address |
| `displayName` | String? | User's display name (from Google or can be set manually) |
| `photoUrl` | String? | URL to user's profile photo (from Google) |
| `authProvider` | String | How the user signed in: `'email'` or `'google'` |
| `createdAt` | DateTime | When the user account was first created |
| `lastLoginAt` | DateTime | Last time the user signed in (updated on each login) |

## Automatic Behavior

### On Sign Up (Email/Password)
- Creates new user document in Firestore
- Sets `authProvider` to `'email'`
- Records `createdAt` and `lastLoginAt` timestamps
- Stores email address

### On Sign In (Email/Password)
- Updates `lastLoginAt` timestamp
- Updates email if it changed

### On Sign In (Google)
- Creates user document if first time
- Sets `authProvider` to `'google'`
- Stores Google profile info (name, photo)
- Updates `lastLoginAt` on each login
- Updates display name and photo URL if changed

## Files Created

### 1. `lib/models/user_model.dart`
- Defines the `UserModel` class
- Handles conversion to/from Firestore maps
- Includes `copyWith` method for updates

### 2. `lib/services/user_service.dart`
- Manages all user-related Firestore operations
- Methods:
  - `createOrUpdateUser()` - Create or update user profile
  - `getUserProfile()` - Get user profile by ID
  - `streamUserProfile()` - Real-time user profile updates
  - `updateUserProfile()` - Update display name or photo
  - `deleteUserProfile()` - Delete user account data
  - `getAllUsers()` - Get all users (admin function)
  - `getUserCount()` - Get total user count

### 3. Updated `lib/services/auth_service.dart`
- Automatically calls `UserService` after authentication
- Creates/updates user profile on:
  - Email sign up
  - Email sign in
  - Google sign in

## Usage Examples

### Get Current User Profile
```dart
final userService = UserService();
final authService = AuthService();

final userId = authService.currentUserId;
if (userId != null) {
  final userProfile = await userService.getUserProfile(userId);
  print('User: ${userProfile?.displayName ?? userProfile?.email}');
}
```

### Stream User Profile (Real-time)
```dart
final userService = UserService();
final userId = authService.currentUserId;

if (userId != null) {
  userService.streamUserProfile(userId).listen((userProfile) {
    if (userProfile != null) {
      print('User updated: ${userProfile.displayName}');
    }
  });
}
```

### Update User Profile
```dart
final userService = UserService();
await userService.updateUserProfile(
  uid: userId,
  displayName: 'New Name',
);
```

### Get User Count (Admin)
```dart
final userService = UserService();
final count = await userService.getUserCount();
print('Total users: $count');
```

## Firestore Security Rules

You should add these security rules to your Firestore to protect user data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Users can read their own profile
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Users can create/update their own profile
      allow create, update: if request.auth != null && request.auth.uid == userId;
      
      // Only the user can delete their own profile
      allow delete: if request.auth != null && request.auth.uid == userId;
      
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

## Benefits

✅ **Automatic** - No manual user profile creation needed
✅ **Consistent** - All users have the same data structure
✅ **Trackable** - Know when users joined and last logged in
✅ **Extensible** - Easy to add more fields later
✅ **Secure** - Each user can only access their own data
✅ **Real-time** - Can stream user profile updates
✅ **Google Integration** - Automatically pulls Google profile info

## Future Enhancements

You can easily extend the user model to include:
- User preferences (theme, notifications, etc.)
- User statistics (total tasks completed, streak, etc.)
- User settings (timezone, language, etc.)
- User roles (admin, premium, etc.)
- Social features (friends, sharing, etc.)

Just add fields to `UserModel` and update the `toMap()`/`fromMap()` methods!

## Testing

After restarting your app:
1. Sign up with a new email/password account
2. Check Firestore Console → `users` collection
3. You should see a new document with your user ID
4. Sign out and sign in again
5. Check that `lastLoginAt` timestamp updated
6. Try signing in with Google (if configured)
7. Check that Google profile info is stored

## Notes

- User profiles are created **automatically** on first sign in
- The `users` collection is at the **root level** of Firestore
- Each user's tasks are stored in subcollections: `users/{userId}/tasks` and `users/{userId}/sideTasks`
- User IDs match Firebase Authentication UIDs for consistency
- All timestamps are stored as ISO8601 strings for easy parsing
