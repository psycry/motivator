# Google Sign-In SecurityException Fix

## Error
```
E/GoogleApiManager: Failed to get service from broker.
E/GoogleApiManager: java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'.
```

## Root Cause
The `google-services.json` file is missing OAuth client configuration. This happens when:
1. SHA-1 certificate fingerprint is not registered in Firebase Console
2. Google Sign-In is not properly configured in Firebase

## Solution

### Step 1: Get Your SHA-1 Fingerprint

**For Debug Build** (what you're using now):
```bash
cd android
./gradlew signingReport
```

Or on Windows:
```bash
cd android
gradlew.bat signingReport
```

Look for the **debug** variant and copy the **SHA-1** fingerprint. It will look like:
```
SHA-1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
```

**Alternative Method** (using keytool):
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **motivator-web**
3. Click the gear icon ⚙️ → **Project settings**
4. Scroll down to **Your apps**
5. Find your Android app: `sh.digitalnomad.motivator`
6. Click **Add fingerprint**
7. Paste your SHA-1 fingerprint
8. Click **Save**

### Step 3: Enable Google Sign-In

1. In Firebase Console, go to **Authentication**
2. Click **Sign-in method** tab
3. Find **Google** in the list
4. Click **Enable**
5. Set a project support email
6. Click **Save**

### Step 4: Download New google-services.json

1. In Firebase Console → **Project settings**
2. Scroll to **Your apps**
3. Click **Download google-services.json**
4. Replace the file at: `android/app/google-services.json`

The new file will have OAuth client entries like:
```json
"oauth_client": [
  {
    "client_id": "xxx.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

### Step 5: Rebuild the App

```bash
flutter clean
flutter pub get
flutter run --flavor free -t lib/main_free.dart
```

## Verification

After completing these steps:
1. The SecurityException should disappear
2. Google Sign-In should work properly
3. You should see OAuth client entries in `google-services.json`

## For Production Release

When you're ready to release:
1. Generate a release keystore
2. Get the SHA-1 from the release keystore
3. Add the release SHA-1 to Firebase Console
4. Download updated `google-services.json`

## Quick Fix (Temporary)

If you just want to test without Google Sign-In for now, the error won't prevent the app from running. The notification features will still work fine. The error is only related to Google Sign-In authentication.

## Additional Notes

### Multiple Flavors
Since you have `free` and `paid` flavors with different package names:
- Free: `sh.digitalnomad.motivator.free`
- Paid: `sh.digitalnomad.motivator`

You may need to:
1. Register both package names in Firebase
2. Add SHA-1 for each
3. Download separate `google-services.json` files (or use one with both apps configured)

### Current Configuration
Your current `google-services.json` only has the paid version configured:
```json
"package_name": "sh.digitalnomad.motivator"
```

If you're running the free flavor, you'll need to add it to Firebase as well.

## Testing Without Google Sign-In

If you want to bypass this error temporarily:
1. The app will still work
2. Notifications will function normally
3. Only Google Sign-In will be affected
4. You can use email/password authentication instead

The error is non-fatal and won't crash the app.
