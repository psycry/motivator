# Quick Build Guide - Free & Paid Versions

## 🚀 Quick Commands

### Run in Debug Mode

**Free Version:**
```bash
flutter run --flavor free -t lib/main_free.dart
```
Or use the batch script:
```bash
build_free.bat debug
```

**Paid Version:**
```bash
flutter run --flavor paid -t lib/main_paid.dart
```
Or use the batch script:
```bash
build_paid.bat debug
```

### Build Release APK

**Free Version:**
```bash
build_free.bat apk
```

**Paid Version:**
```bash
build_paid.bat apk
```

### Build for Google Play (App Bundle)

**Free Version:**
```bash
build_free.bat appbundle
```

**Paid Version:**
```bash
build_paid.bat appbundle
```

## 📱 App Details

### Free Version
- **Package**: `sh.digitalnomad.motivator.free`
- **Name**: "Motivator Free"
- **Icon**: Same as paid (can be customized)
- **Features**: Limited (see FLAVOR_SETUP.md)

### Paid Version
- **Package**: `sh.digitalnomad.motivator`
- **Name**: "Motivator"
- **Icon**: Same as free (can be customized)
- **Features**: Full access

## 🎯 VS Code

Use the Run and Debug panel (Ctrl+Shift+D) and select:
- "Free (Debug)" - Run free version
- "Paid (Debug)" - Run paid version
- "Free (Release)" - Run free version in release mode
- "Paid (Release)" - Run paid version in release mode

## 🔧 Common Tasks

### Clean Build
```bash
flutter clean
flutter pub get
```

### Install Both Versions on Device
```bash
# Install free
flutter install --flavor free -t lib/main_free.dart

# Install paid (both can coexist)
flutter install --flavor paid -t lib/main_paid.dart
```

### Check Which Version is Running
In your Dart code:
```dart
import 'package:motivator/config/flavor_config.dart';

print('Running: ${FlavorConfig.instance.appTitle}');
print('Is Paid: ${FlavorConfig.instance.isPaid}');
```

## 📦 Output Locations

**APK Files:**
- Free: `build/app/outputs/flutter-apk/app-free-release.apk`
- Paid: `build/app/outputs/flutter-apk/app-paid-release.apk`

**App Bundles (for Google Play):**
- Free: `build/app/outputs/bundle/freeRelease/app-free-release.aab`
- Paid: `build/app/outputs/bundle/paidRelease/app-paid-release.aab`

## 🐛 Troubleshooting

**"Gradle build failed to produce an .apk file":**
- This happens when you don't specify the flavor
- **Solution:** Always use `--flavor free` or `--flavor paid` with `-t lib/main_free.dart` or `-t lib/main_paid.dart`
- The APKs are built as `app-free-debug.apk` and `app-paid-debug.apk`, not `app-debug.apk`

**"No flavor specified" error:**
- Always include `--flavor free` or `--flavor paid`
- Use the provided batch scripts or VS Code launch configs

**Build fails:**
```bash
flutter clean
flutter pub get
flutter run --flavor free -t lib/main_free.dart
```

**Wrong app name showing:**
- Make sure you're using the correct entry point
- Check `FlavorConfig.initialize()` is called in main_free.dart or main_paid.dart

**Multiple devices:**
```bash
# List devices
flutter devices

# Run on specific device
flutter run --flavor free -t lib/main_free.dart -d DEVICE_ID
```

## 📚 More Info

See `FLAVOR_SETUP.md` for detailed documentation.
