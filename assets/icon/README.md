# App Icon Assets

## Current Status

The app uses an **adaptive icon** (Android 8.0+) with:
- **Background**: Deep Purple (#673AB7)
- **Foreground**: White check mark in circle (vector drawable)

## Optional: Add PNG Icon

For legacy Android and iOS support, you can add a PNG icon here:

### File Name
`app_icon.png`

### Specifications
- **Size**: 1024x1024 pixels
- **Format**: PNG with transparency
- **Background**: Deep Purple (#673AB7)
- **Icon**: White check mark in circle
- **Style**: Matches `Icons.task_alt` from Material Design

### Design Tips
1. Keep the check mark centered
2. Use 80% safe area for important elements
3. Ensure good contrast (white on purple)
4. Test on different backgrounds

### Generate Icons
After adding `app_icon.png`:
```bash
flutter pub run flutter_launcher_icons
```

This will generate all required icon sizes for Android and iOS.

## Current Configuration

The adaptive icon is already configured in:
- `android/app/src/main/res/values/colors.xml` - Background color
- `android/app/src/main/res/drawable/ic_launcher_foreground.xml` - Vector icon
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` - Adaptive icon config

**No PNG needed for modern Android devices!** The vector icon works great.

## Tools for Creating PNG Icon

- [Figma](https://www.figma.com/) - Free design tool
- [AppIcon.co](https://appicon.co/) - Icon generator
- [Icon Kitchen](https://icon.kitchen/) - Android icon tool
- Photoshop, GIMP, or any image editor

## Color Reference

```
Deep Purple: #673AB7 (Material Design 500)
White:       #FFFFFF
```
