# Update App Icon to Match Login Screen

## Current Status

The app icon has been updated to match the login screen:
- **Icon**: Check mark in a circle (task_alt icon)
- **Color**: Deep Purple (#673AB7)
- **Theme**: Updated to use `Colors.deepPurple` throughout the app

## Changes Made

### 1. Theme Color Updated
**File**: `lib/main.dart`
- Changed `primarySwatch` from `Colors.blue` to `Colors.deepPurple`
- Added explicit `primaryColor: Colors.deepPurple`

### 2. Launcher Icon Background Color
**File**: `android/app/src/main/res/values/colors.xml`
- Updated `ic_launcher_background` to `#673AB7` (Deep Purple)

### 3. Launcher Icon Foreground
**File**: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- Created vector drawable with white check mark in circle
- Matches the `Icons.task_alt` icon from the login screen

## How to Generate Full Icon Set

The project uses `flutter_launcher_icons` package to generate all icon sizes. To create a complete icon set:

### Option 1: Use the Current Vector Icon (Recommended)
The adaptive icon is already configured and will work on Android 8.0+. For older Android versions and iOS:

1. **Create a PNG icon** (1024x1024px) with:
   - Purple background (#673AB7)
   - White check mark in circle
   - Save as: `assets/icon/app_icon.png`

2. **Generate icons**:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

### Option 2: Use an Icon Generator Tool

**Online Tools:**
- [AppIcon.co](https://appicon.co/) - Upload 1024x1024 PNG
- [Icon Kitchen](https://icon.kitchen/) - Android adaptive icon generator
- [Figma](https://www.figma.com/) - Design custom icon

**Design Specifications:**
- **Size**: 1024x1024px
- **Background**: Deep Purple (#673AB7)
- **Foreground**: White check mark in circle
- **Style**: Material Design, flat, minimal
- **Safe Area**: Keep important elements within 80% of canvas

### Option 3: Create Icon with Figma/Photoshop

1. Create 1024x1024px canvas
2. Fill with purple (#673AB7)
3. Add white circle (stroke or fill)
4. Add white check mark inside circle
5. Export as PNG
6. Save to `assets/icon/app_icon.png`

## Current Icon Configuration

### Adaptive Icon (Android 8.0+)
**File**: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
```xml
<adaptive-icon>
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
```

### Flutter Launcher Icons Config
**File**: `pubspec.yaml`
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
```

## Testing the Icon

### 1. Build and Install
```bash
# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk --release --flavor paid

# Install on device
flutter install
```

### 2. Verify Icon
- Check app drawer - icon should be purple with white check
- Check home screen - icon should match
- Long-press icon - shortcuts should work
- Check notification icon (if applicable)

## Icon Variations by Flavor

If you want different icons for free vs paid versions:

### Update pubspec.yaml
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path_android: "assets/icon/app_icon_android.png"
  image_path_ios: "assets/icon/app_icon_ios.png"
  adaptive_icon_background: "#673AB7"
  adaptive_icon_foreground: "assets/icon/foreground.png"
```

### Separate Flavor Icons
Create different icons in build.gradle.kts:
- Free version: Add "FREE" badge
- Paid version: Clean icon

## Troubleshooting

### Icon Not Updating
1. Uninstall the app completely
2. Clear build cache: `flutter clean`
3. Rebuild: `flutter build apk --release`
4. Reinstall

### Wrong Color
- Check `colors.xml` has correct hex color
- Verify `ic_launcher_foreground.xml` uses correct colors
- Rebuild after changes

### Icon Looks Distorted
- Ensure vector drawable paths are correct
- Check scaling values in foreground XML
- Test on multiple devices/Android versions

## Quick Reference

### Color Codes
- **Deep Purple**: `#673AB7` (Material Design 500)
- **White**: `#FFFFFF`

### Icon Sizes (Auto-generated)
- mdpi: 48x48
- hdpi: 72x72
- xhdpi: 96x96
- xxhdpi: 144x144
- xxxhdpi: 192x192

### Files Modified
1. `lib/main.dart` - Theme color
2. `android/app/src/main/res/values/colors.xml` - Background color
3. `android/app/src/main/res/drawable/ic_launcher_foreground.xml` - Icon design

## Next Steps

1. **Create PNG icon** (if needed for iOS or legacy Android)
2. **Run icon generator**: `flutter pub run flutter_launcher_icons`
3. **Test on device**: Build and install to verify
4. **Update for flavors**: Create separate icons if needed

The adaptive icon is already configured and will display correctly on modern Android devices!
