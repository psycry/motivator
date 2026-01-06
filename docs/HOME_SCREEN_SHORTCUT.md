# Home Screen Shortcut Configuration

## Overview
The Motivator app is configured to automatically create a home screen shortcut when installed on Android devices.

## What's Configured

### 1. **Automatic Launcher Icon** (Default Behavior)
When you install the app on any Android device, a launcher icon is **automatically created** on the home screen or app drawer. This is the standard Android behavior.

**Configuration:**
- Located in: `android/app/src/main/AndroidManifest.xml`
- The `LAUNCHER` category in the intent filter ensures the app appears in the launcher
- Icon is defined by `@mipmap/ic_launcher`

### 2. **App Name Display**
The app name shown under the icon is configured in:
- `android/app/build.gradle.kts` - Product flavors define:
  - **Paid version**: "Motivator"
  - **Free version**: "Motivator Free"
- `android/app/src/main/res/values/strings.xml` - Default fallback name

### 3. **App Shortcuts** (Long-Press Menu)
When users long-press the app icon on Android 7.1+, they can:
- Pin a shortcut to the home screen
- Access quick actions

**Configuration:**
- Located in: `android/app/src/main/res/xml/shortcuts.xml`
- Referenced in: `AndroidManifest.xml` via `android.app.shortcuts` metadata

## How It Works

### Installation
1. User installs the APK or downloads from Play Store
2. Android automatically creates a launcher icon
3. Icon appears in:
   - Home screen (on most launchers)
   - App drawer (always)

### Long-Press Shortcuts (Android 7.1+)
1. User long-presses the app icon
2. A menu appears with app shortcuts
3. User can drag shortcuts to home screen for quick access

## Testing

### Test on Physical Device
```bash
# Build and install the app
flutter build apk --release
flutter install
```

### Test on Emulator
```bash
# Run the app
flutter run
```

After installation, check:
1. ✅ App icon appears in app drawer
2. ✅ App icon can be dragged to home screen
3. ✅ Long-press shows app shortcuts (Android 7.1+)
4. ✅ Correct app name is displayed

## Icon Customization

To customize the app icon:
1. Generate icons using [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)
2. Place icons in appropriate mipmap folders
3. Update `ic_launcher.xml` for adaptive icons

## Troubleshooting

### Icon Not Appearing
- Check that `android:exported="true"` is set in MainActivity
- Verify LAUNCHER category is present in intent filter
- Reinstall the app completely

### Wrong App Name
- Check product flavor configuration in `build.gradle.kts`
- Verify `strings.xml` has correct default name
- Clean and rebuild: `flutter clean && flutter build apk`

### Shortcuts Not Working
- Requires Android 7.1 (API 25) or higher
- Check `shortcuts.xml` is properly formatted
- Verify metadata is added to AndroidManifest.xml

## References
- [Android App Shortcuts](https://developer.android.com/guide/topics/ui/shortcuts)
- [Android Launcher Icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_launcher)
- [Flutter App Icons](https://docs.flutter.dev/deployment/android#adding-a-launcher-icon)
