# ⚠️ IMPORTANT: How to Run Your App with Flavors

## The Key Issue

When using product flavors, you **MUST** specify both the flavor AND the target file when running the app.

## ✅ Correct Commands

### Free Version
```bash
flutter run --flavor free -t lib/main_free.dart
```

### Paid Version
```bash
flutter run --flavor paid -t lib/main_paid.dart
```

### With Specific Device
```bash
# List your devices first
flutter devices

# Then run with device ID
flutter run --flavor free -t lib/main_free.dart -d YOUR_DEVICE_ID
```

## ❌ Common Mistakes

### DON'T do this:
```bash
flutter run                          # ❌ Missing flavor and target
flutter run lib/main_free.dart       # ❌ Missing flavor
flutter run --flavor free            # ❌ Missing target
```

### These will cause errors like:
- "No flavor specified"
- "Gradle build failed to produce an .apk file"
- APK not found errors

## 🎯 Why This Happens

With product flavors:
- The APK is named `app-free-debug.apk` (not `app-debug.apk`)
- Flutter needs to know which flavor to build
- Each flavor has its own entry point (`main_free.dart` or `main_paid.dart`)

## 📱 Using VS Code (Easiest Method)

1. Press `Ctrl+Shift+D` (Run and Debug)
2. Select from dropdown:
   - "Free (Debug)" - for free version
   - "Paid (Debug)" - for paid version
3. Press `F5` to run

This automatically uses the correct flavor and target!

## 🔨 Using Batch Scripts (Windows)

### Run Free Version
```bash
build_free.bat debug
```

### Run Paid Version
```bash
build_paid.bat debug
```

## 📦 Build Outputs

After a successful build, APKs are located at:

**Debug APKs:**
- Free: `build/app/outputs/flutter-apk/app-free-debug.apk`
- Paid: `build/app/outputs/flutter-apk/app-paid-debug.apk`

**Release APKs:**
- Free: `build/app/outputs/flutter-apk/app-free-release.apk`
- Paid: `build/app/outputs/flutter-apk/app-paid-release.apk`

## 🚀 Quick Start Checklist

- [ ] Open terminal in project directory
- [ ] Run: `flutter devices` (to see available devices)
- [ ] Run: `flutter run --flavor free -t lib/main_free.dart`
- [ ] Wait for build to complete
- [ ] App should launch on your device

## 🔧 If Build Fails

1. **Clean the build:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Try again:**
   ```bash
   flutter run --flavor free -t lib/main_free.dart
   ```

3. **Check device connection:**
   ```bash
   flutter devices
   ```

## 📝 Summary

**Remember these two things:**
1. Always use `--flavor free` or `--flavor paid`
2. Always use `-t lib/main_free.dart` or `-t lib/main_paid.dart`

**Or just use VS Code Run and Debug panel - it's configured correctly!**

## ✅ Your App is Ready!

The configuration is complete. Just use the correct command format and your app will run successfully on both free and paid flavors.

**Recommended:** Use VS Code's Run and Debug panel (Ctrl+Shift+D) for the easiest experience.
