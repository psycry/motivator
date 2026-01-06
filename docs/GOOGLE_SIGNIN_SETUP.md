# Google Sign-In Setup Guide

## Overview
Google Sign-In has been added to the app! Users can now sign in with their Google account in addition to email/password.

## What Was Added

### 1. Package
- ✅ `google_sign_in: ^6.2.1` added to `pubspec.yaml`

### 2. AuthService Updates
- ✅ `signInWithGoogle()` method
- ✅ Google Sign-In integration with Firebase Auth
- ✅ Proper sign-out handling for both Firebase and Google

### 3. UI Updates
- ✅ "Continue with Google" button on login page
- ✅ Google logo and branding
- ✅ "OR" divider between email and Google sign-in
- ✅ Consistent styling with email/password buttons

## Firebase Console Setup

### Step 1: Enable Google Sign-In Provider

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**
3. **Click "Authentication"** in the left sidebar
4. **Click "Sign-in method"** tab
5. **Find "Google"** in the providers list
6. **Click on it**
7. **Toggle "Enable"** to ON
8. **Enter Project Support Email** (your email)
9. **Click "Save"**

### Step 2: Configure OAuth Consent Screen (For Web)

Since you're running on web, you need to configure the OAuth consent screen:

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your Firebase project** (same project name)
3. **Navigate to**: APIs & Services → OAuth consent screen
4. **Select "External"** user type
5. **Click "Create"**
6. **Fill in required fields**:
   - App name: `Motivator`
   - User support email: Your email
   - Developer contact: Your email
7. **Click "Save and Continue"**
8. **Skip "Scopes"** (click "Save and Continue")
9. **Add test users** (optional, or click "Save and Continue")
10. **Review and click "Back to Dashboard"**

### Step 3: Get OAuth Client ID (For Web)

1. **In Google Cloud Console**, go to: APIs & Services → Credentials
2. **Find "Web client (auto created by Google Service)"**
3. **Click on it to edit**
4. **Add Authorized JavaScript origins**:
   - `http://localhost` (for local testing)
   - Your production domain (when deployed)
5. **Add Authorized redirect URIs**:
   - `http://localhost` (for local testing)
   - Your production domain (when deployed)
6. **Click "Save"**

## Install Dependencies

Run this command to install the new package:

```bash
flutter pub get
```

## How It Works

### User Flow
1. User opens the app → sees login page
2. User clicks **"Continue with Google"**
3. Google Sign-In popup appears
4. User selects their Google account
5. User is automatically signed in
6. App loads their tasks

### Technical Flow
```
User clicks "Continue with Google"
    ↓
GoogleSignIn.signIn() opens popup
    ↓
User selects Google account
    ↓
Get Google authentication tokens
    ↓
Create Firebase credential with tokens
    ↓
Sign in to Firebase with credential
    ↓
AuthWrapper detects auth state change
    ↓
Navigate to main app
    ↓
Load user's tasks from Firestore
```

## Testing

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Hot Reload
Press `r` in your Flutter terminal

### 3. Test Google Sign-In
1. You should see the "Continue with Google" button
2. Click it
3. A Google Sign-In popup should appear
4. Select your Google account
5. You should be signed in automatically

### 4. Verify Task Persistence
1. Create some tasks
2. Sign out (menu → Sign Out)
3. Sign back in with Google
4. Your tasks should still be there

## Platform-Specific Setup

### Web (Current Platform)
✅ Already configured! Just need to:
1. Enable Google provider in Firebase Console
2. Configure OAuth consent screen
3. Add authorized domains

### Android (If Deploying)
1. Get SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. Add SHA-1 to Firebase Console:
   - Project Settings → Your apps → Android app
   - Add SHA-1 fingerprint
3. Download new `google-services.json`
4. Replace in `android/app/`

### iOS (If Deploying)
1. Add URL scheme to `Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
       </array>
     </dict>
   </array>
   ```
2. Download new `GoogleService-Info.plist`
3. Add to Xcode project

### Windows (Current Platform)
✅ Works through web implementation!

## Features

### User Benefits
- 🚀 **One-click sign-in** - No need to remember passwords
- 🔒 **Secure** - Uses Google's authentication
- 📧 **Email verified** - Google accounts are pre-verified
- 🔄 **Seamless** - Same experience across devices

### Developer Benefits
- ✅ **Easy integration** - Just a few lines of code
- 🛡️ **Secure by default** - Google handles security
- 📊 **User info** - Get name, email, profile picture
- 🌐 **Cross-platform** - Works on web, mobile, desktop

## Troubleshooting

### "Google sign-in was canceled"
- User clicked outside the popup or pressed cancel
- This is normal behavior, not an error

### "PlatformException: sign_in_failed"
- OAuth consent screen not configured
- Follow Step 2 in Firebase Console Setup

### "Invalid client ID"
- OAuth client not configured for web
- Add authorized JavaScript origins and redirect URIs

### "Popup blocked"
- Browser is blocking the Google Sign-In popup
- Allow popups for localhost or your domain

### "Network error"
- Check internet connection
- Verify Firebase project is active

### Button doesn't appear
- Run `flutter pub get`
- Hot reload or restart the app
- Check console for errors

## Expected Console Output

### On Google Sign-In Click
```
(Google Sign-In popup opens)
```

### On Successful Sign-In
```
=== INITIALIZING FIREBASE SERVICE ===
✓ User authenticated: [google-user-id]
Initializing Firebase service for user: [google-user-id]
=== LOADING TASKS FROM FIREBASE ===
Loading all tasks from Firebase...
Found X total task documents
✓ Tasks loaded from Firebase successfully
```

### On Sign-Out
```
(Signs out from both Firebase and Google)
(Returns to login page)
```

## Security Notes

### OAuth Consent Screen
- **External** type allows any Google account to sign in
- **Internal** type (Google Workspace only) restricts to your organization
- For public apps, use External

### Authorized Domains
- Only add domains you control
- For local testing: `localhost`
- For production: your actual domain

### User Data
- Google Sign-In provides: email, name, profile picture
- All stored securely in Firebase Auth
- Tasks are still private per user

## Benefits Over Email/Password

### For Users
- ✅ No password to remember
- ✅ No password to forget
- ✅ Faster sign-in process
- ✅ More secure (Google's security)
- ✅ Email already verified

### For You
- ✅ Less support requests (no password resets)
- ✅ Higher conversion (easier sign-up)
- ✅ Better security (Google handles it)
- ✅ User profile info available

## Next Steps

1. **Install dependencies**: `flutter pub get`
2. **Enable Google provider** in Firebase Console
3. **Configure OAuth consent screen** in Google Cloud Console
4. **Hot reload** the app
5. **Test Google Sign-In**

Your app now supports both email/password AND Google Sign-In! 🎉

## Additional Features (Future)

You can easily add more sign-in methods:
- 🍎 Apple Sign-In
- 📘 Facebook Login
- 🐦 Twitter Login
- 📱 Phone Authentication

All follow similar patterns to Google Sign-In!
