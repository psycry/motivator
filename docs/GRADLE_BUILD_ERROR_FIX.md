# Gradle Build Error Fix

## The Problem

If you see this error:
```
Error: Gradle build failed to produce an .apk file. It's likely that this file was 
generated under C:\Users\...\build, but the tool couldn't find it.
```

**Root Cause:** You're trying to run `lib/main.dart` directly, but this app uses **product flavors** (free and paid versions). Gradle doesn't know which variant to build without a flavor specified.

## The Solution

### Option 1: Use IDE Run Configurations (Recommended)

**IntelliJ IDEA / Android Studio:**
1. Click the run configuration dropdown (top right toolbar)
2. Select "Free (Debug)" or "Paid (Debug)"
3. Click the green play button (or press `Shift+F10`)

**VS Code:**
1. Press `Ctrl+Shift+D` (or click Run and Debug icon)
2. Select "Free (Debug)" or "Paid (Debug)" from dropdown
3. Press `F5` or click the green play button

### Option 2: Use Quick Run Scripts

Double-click one of these batch files in the project root:
- `run_free.bat` - Run free version
- `run_paid.bat` - Run paid version

### Option 3: Use Terminal Commands

**Free Version:**
```bash
flutter run --flavor free -t lib/main_free.dart
```

**Paid Version:**
```bash
flutter run --flavor paid -t lib/main_paid.dart
```

## Why This Happens

The app is configured with two product flavors in `android/app/build.gradle.kts`:
- **free** - Free version with limited features
- **paid** - Paid version with all features

When you run without specifying a flavor, Gradle tries to build all variants and fails to determine which APK to use.

## Automatic Fix (No Manual Intervention Needed)

The following has been set up to prevent this issue:

1. **Warning in `lib/main.dart`** - Clear comment at the top explaining the issue
2. **VS Code launch configurations** - Pre-configured run options
3. **Quick run scripts** - `run_free.bat` and `run_paid.bat`
4. **Launch configuration for main.dart** - Redirects to free version automatically

## Making It Default in VS Code

To always use a specific flavor by default:

1. Open `.vscode/launch.json`
2. The first configuration in the list is the default
3. Currently set to "Free (Debug)"

## For New Developers

Add this to your team documentation:

> ⚠️ **Important:** This app uses product flavors. Never run `flutter run` without specifying a flavor. Always use:
> - VS Code: Run and Debug panel → Select "Free (Debug)" or "Paid (Debug)"
> - Terminal: `flutter run --flavor free -t lib/main_free.dart`
> - Scripts: `run_free.bat` or `run_paid.bat`

## Troubleshooting

### Still Getting the Error?

1. **Clean the build:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Try again with flavor:**
   ```bash
   flutter run --flavor free -t lib/main_free.dart
   ```

3. **Check you're not running main.dart directly:**
   - In VS Code, check the file name in the debug console
   - Should be `main_free.dart` or `main_paid.dart`, NOT `main.dart`

### VS Code Not Showing Launch Configurations?

1. Reload VS Code: `Ctrl+Shift+P` → "Developer: Reload Window"
2. Check `.vscode/launch.json` exists
3. Install Flutter and Dart extensions if missing

## Related Documentation

- [IMPORTANT_RUNNING_INSTRUCTIONS.md](IMPORTANT_RUNNING_INSTRUCTIONS.md) - Complete running guide
- [FLAVOR_SETUP_SUMMARY.md](FLAVOR_SETUP_SUMMARY.md) - Flavor system overview
- [QUICK_BUILD_GUIDE.md](QUICK_BUILD_GUIDE.md) - Build commands reference
