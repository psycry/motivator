# Firebase Configuration for Product Flavors

## Issue
When using product flavors, each flavor needs its own Firebase configuration because they have different package names:
- Free version: `sh.digitalnomad.motivator.free`
- Paid version: `sh.digitalnomad.motivator`

## Current Setup (Development)

For development purposes, I've created flavor-specific `google-services.json` files that point to the same Firebase project but with different package names:

```
android/app/src/
├── free/
│   └── google-services.json    (package: sh.digitalnomad.motivator.free)
├── paid/
│   └── google-services.json    (package: sh.digitalnomad.motivator)
└── main/
    └── google-services.json    (original - can be removed)
```

**Note:** This is a temporary solution. Both flavors currently share the same Firebase project, which means they share the same database and authentication. This works for development but is **not recommended for production**.

## Recommended Production Setup

For production, you should create **separate Firebase projects** for each flavor:

### Step 1: Create Two Firebase Projects

1. **Free Version Project:**
   - Project name: `motivator-free`
   - Package name: `sh.digitalnomad.motivator.free`

2. **Paid Version Project:**
   - Project name: `motivator-paid`
   - Package name: `sh.digitalnomad.motivator`

### Step 2: Register Android Apps

For each Firebase project:

1. Go to Firebase Console
2. Click "Add app" → Android
3. Enter the package name:
   - Free: `sh.digitalnomad.motivator.free`
   - Paid: `sh.digitalnomad.motivator`
4. Download the `google-services.json` file

### Step 3: Place Configuration Files

Place each `google-services.json` in the correct flavor directory:

```bash
# Free version
android/app/src/free/google-services.json

# Paid version
android/app/src/paid/google-services.json
```

### Step 4: Configure Firebase Services

For each Firebase project, enable the same services:

- **Authentication:**
  - Enable Google Sign-In
  - Add SHA-1 fingerprints for both debug and release keys
  - Configure OAuth consent screen

- **Firestore Database:**
  - Create database
  - Set up security rules (same for both)
  - Create indexes if needed

- **Storage (if used):**
  - Enable Cloud Storage
  - Set up security rules

### Step 5: Update Security Rules

Make sure both Firebase projects have the same Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Your security rules here
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // ... other rules
  }
}
```

## Benefits of Separate Firebase Projects

1. **Data Isolation:**
   - Free and paid users have separate databases
   - No risk of data mixing between versions

2. **Analytics Separation:**
   - Track metrics separately for each version
   - Better understanding of user behavior per version

3. **Independent Scaling:**
   - Different quotas and billing for each version
   - Can upgrade one without affecting the other

4. **Security:**
   - Separate authentication pools
   - Different API keys and credentials

5. **Testing:**
   - Can test paid features without affecting free users
   - Easier to manage different configurations

## Current Workaround (Development Only)

The current setup uses the same Firebase project for both flavors. This means:

- ✅ **Works for development and testing**
- ✅ **Simple to set up initially**
- ❌ **Not recommended for production**
- ❌ **Free and paid users share the same database**
- ❌ **Can't have different configurations per version**

## Migration Path

When ready to move to production:

1. **Create separate Firebase projects** (as described above)
2. **Download new google-services.json files**
3. **Replace the files** in `android/app/src/free/` and `android/app/src/paid/`
4. **Update Firebase configuration** in Flutter code if needed
5. **Test both versions** thoroughly
6. **Migrate existing data** if necessary

## Verification

After setting up Firebase configurations, verify they work:

### Test Free Version
```bash
flutter run --flavor free -t lib/main_free.dart
```

Check the logs for:
```
✓ Firebase initialized successfully
✓ User authenticated: [user-id]
```

### Test Paid Version
```bash
flutter run --flavor paid -t lib/main_paid.dart
```

Check the logs for the same success messages.

## Troubleshooting

### "No matching client found for package name"

This error means the `google-services.json` doesn't have a client with the correct package name.

**Solution:**
1. Check the package name in `google-services.json`:
   ```json
   "android_client_info": {
     "package_name": "sh.digitalnomad.motivator.free"  // Must match flavor
   }
   ```
2. Make sure the file is in the correct location:
   - Free: `android/app/src/free/google-services.json`
   - Paid: `android/app/src/paid/google-services.json`

### "Default Firebase app has not been initialized"

This means Firebase isn't initializing properly.

**Solution:**
1. Verify `google-services.json` exists for the flavor you're building
2. Check that Firebase is initialized in `main.dart`:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

### Different SHA-1 fingerprints needed

Each flavor may need its own SHA-1 fingerprint for Google Sign-In.

**Get debug SHA-1:**
```bash
cd android
./gradlew signingReport
```

**Get release SHA-1:**
```bash
keytool -list -v -keystore your-release-key.jks -alias your-key-alias
```

Add both to Firebase Console → Project Settings → Your apps → SHA certificate fingerprints

## Best Practices

1. **Keep configurations in sync** - Both projects should have similar settings
2. **Document differences** - Note any intentional differences between projects
3. **Use environment variables** - For API keys and sensitive data
4. **Version control** - Don't commit `google-services.json` to public repos
5. **Regular backups** - Export Firestore data regularly

## Additional Resources

- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Multiple Firebase Projects](https://firebase.google.com/docs/projects/multiprojects)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Flutter Flavors with Firebase](https://firebase.flutter.dev/docs/overview#initializing-flutterfire)
