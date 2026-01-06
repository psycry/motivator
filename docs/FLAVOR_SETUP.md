# Product Flavors Setup Guide

This project supports two product flavors for Google Play:
- **Free Version**: Limited features with ads support
- **Paid Version**: Full features, no ads

## Architecture Overview

### 1. Android Configuration
- **Build Flavors**: Configured in `android/app/build.gradle.kts`
  - `free`: Application ID suffix `.free`, labeled "Motivator Free"
  - `paid`: Base application ID, labeled "Motivator"
- **Separate App IDs**: Each flavor has its own application ID, allowing both versions on Google Play
- **BuildConfig**: Each flavor has `IS_PAID_VERSION` boolean flag

### 2. Dart Configuration
- **FlavorConfig**: `lib/config/flavor_config.dart` - Central configuration for flavor detection
- **Entry Points**: 
  - `lib/main_free.dart` - Entry point for free version
  - `lib/main_paid.dart` - Entry point for paid version
- **Feature Flags**: `FlavorFeatures` class controls which features are available

## Building the App

### Free Version

**Debug Build:**
```bash
flutter run --flavor free -t lib/main_free.dart
```

**Release APK:**
```bash
flutter build apk --flavor free -t lib/main_free.dart --release
```

**Release App Bundle (for Google Play):**
```bash
flutter build appbundle --flavor free -t lib/main_free.dart --release
```

### Paid Version

**Debug Build:**
```bash
flutter run --flavor paid -t lib/main_paid.dart
```

**Release APK:**
```bash
flutter build apk --flavor paid -t lib/main_paid.dart --release
```

**Release App Bundle (for Google Play):**
```bash
flutter build appbundle --flavor paid -t lib/main_paid.dart --release
```

## Feature Differences

### Free Version Features
- ✅ Basic task management
- ✅ Up to 10 tasks per day
- ✅ Simple notifications
- ❌ No Gemini AI chat
- ❌ No recurring tasks
- ❌ No weather widget
- ❌ Limited customization
- 📱 Shows ads (when implemented)

### Paid Version Features
- ✅ Unlimited task management
- ✅ Gemini AI chat integration
- ✅ Recurring tasks
- ✅ Weather widget
- ✅ Custom notifications
- ✅ Full customization
- ✅ No ads

## Implementation Guide

### Checking Flavor in Code

```dart
import 'package:motivator/config/flavor_config.dart';

// Check if paid version
if (FlavorConfig.instance.isPaid) {
  // Show premium feature
}

// Check if free version
if (FlavorConfig.instance.isFree) {
  // Show ads or upgrade prompt
}

// Use feature flags
final features = FlavorConfig.instance.features;

if (features.hasGeminiChat) {
  // Show Gemini chat widget
}

if (features.maxTasksPerDay != null) {
  // Enforce task limit
  final limit = features.maxTasksPerDay!;
}
```

### Adding Feature Restrictions

Edit `lib/config/flavor_config.dart` and add new feature flags to the `FlavorFeatures` class:

```dart
class FlavorFeatures {
  // Add new feature flag
  bool get hasNewFeature => isPaid;
}
```

## Google Play Setup

### Free Version
1. **Package Name**: `sh.digitalnomad.motivator.free`
2. **App Name**: "Motivator Free"
3. **Pricing**: Free
4. **In-App Purchases**: Optional (upgrade to paid)
5. **Ads**: Yes (when implemented)

### Paid Version
1. **Package Name**: `sh.digitalnomad.motivator`
2. **App Name**: "Motivator"
3. **Pricing**: Paid (one-time purchase)
4. **In-App Purchases**: No
5. **Ads**: No

## Firebase Configuration

Each flavor should have its own Firebase project (optional but recommended):

1. Create two Firebase projects:
   - `motivator-free`
   - `motivator-paid`

2. Download `google-services.json` for each:
   - Free: `android/app/src/free/google-services.json`
   - Paid: `android/app/src/paid/google-services.json`

3. Update Firebase configuration in each flavor directory

## Testing Both Versions

You can install both versions on the same device simultaneously since they have different application IDs:

```bash
# Install free version
flutter install --flavor free -t lib/main_free.dart

# Install paid version (on same device)
flutter install --flavor paid -t lib/main_paid.dart
```

## VS Code Launch Configurations

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Free (Debug)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_free.dart",
      "args": ["--flavor", "free"]
    },
    {
      "name": "Paid (Debug)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_paid.dart",
      "args": ["--flavor", "paid"]
    },
    {
      "name": "Free (Release)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_free.dart",
      "args": ["--flavor", "free", "--release"]
    },
    {
      "name": "Paid (Release)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_paid.dart",
      "args": ["--flavor", "paid", "--release"]
    }
  ]
}
```

## Troubleshooting

### Build Errors

**Error: "No flavor specified"**
- Make sure to include `--flavor free` or `--flavor paid` in your build command

**Error: "Multiple dex files define"**
- Clean the build: `flutter clean && flutter pub get`

**Error: "Duplicate resources"**
- Check that flavor-specific resources don't conflict with main resources

### Runtime Issues

**Wrong flavor detected:**
- Verify you're using the correct entry point (`main_free.dart` or `main_paid.dart`)
- Check that `FlavorConfig.initialize()` is called before `app.main()`

**Features not working as expected:**
- Verify the flavor configuration in `FlavorConfig.instance`
- Check feature flags in `FlavorFeatures`

## Next Steps

1. **Implement Ad Integration** (for free version)
   - Add Google AdMob dependency
   - Show banner/interstitial ads in free version only
   - Check `features.showAds` before displaying ads

2. **Add Upgrade Flow** (free to paid)
   - Implement in-app purchase to unlock paid features
   - Or deep link to paid version on Google Play

3. **Feature Gating**
   - Add UI indicators for premium features in free version
   - Show upgrade prompts when users try to access paid features

4. **Analytics**
   - Track which features are used in each version
   - Monitor conversion from free to paid

## Resources

- [Flutter Flavors Documentation](https://flutter.dev/docs/deployment/flavors)
- [Android Product Flavors](https://developer.android.com/studio/build/build-variants)
- [Google Play Multiple APKs](https://developer.android.com/google/play/publishing/multiple-apks)
