# IntelliJ IDEA / Android Studio Setup

## Run Configurations (Already Set Up!)

This project includes pre-configured run configurations for IntelliJ IDEA and Android Studio.

### Available Configurations

You should see these in the run configuration dropdown (top right toolbar):

- **Free (Debug)** - Run free version in debug mode
- **Paid (Debug)** - Run paid version in debug mode
- **Free (Release)** - Run free version in release mode
- **Paid (Release)** - Run paid version in release mode

### How to Use

1. **Select a configuration:**
   - Click the dropdown next to the play button (top right)
   - Choose "Free (Debug)" or "Paid (Debug)"

2. **Run the app:**
   - Click the green play button, OR
   - Press `Shift+F10`, OR
   - Right-click the configuration and select "Run"

3. **Debug the app:**
   - Click the debug button (bug icon), OR
   - Press `Shift+F9`

## If Configurations Don't Appear

If you don't see the run configurations:

### Option 1: Reload Project
1. File → Invalidate Caches / Restart
2. Select "Invalidate and Restart"
3. Wait for IntelliJ to reindex the project

### Option 2: Manual Import
1. Run → Edit Configurations
2. Click the "+" button
3. Select "Flutter"
4. Configure as follows:

**For Free Version:**
- Name: `Free (Debug)`
- Dart entrypoint: `lib/main_free.dart`
- Additional run args: `--flavor free`

**For Paid Version:**
- Name: `Paid (Debug)`
- Dart entrypoint: `lib/main_paid.dart`
- Additional run args: `--flavor paid`

### Option 3: Check Git Status
The run configurations are stored in `.idea/runConfigurations/`. Make sure these files exist:
- `Free__Debug_.xml`
- `Paid__Debug_.xml`
- `Free__Release_.xml`
- `Paid__Release_.xml`

If they're missing, they may have been gitignored. Check `.gitignore` to ensure these lines exist:
```
!.idea/runConfigurations/
!.idea/runConfigurations/*.xml
```

## Common Issues

### "Gradle build failed to produce an .apk file"

**Cause:** You tried to run `main.dart` directly without specifying a flavor.

**Solution:** Always use one of the pre-configured run configurations listed above.

### Run Configuration Dropdown is Empty

1. Make sure Flutter plugin is installed:
   - File → Settings → Plugins
   - Search for "Flutter"
   - Install if not present
   - Restart IntelliJ

2. Make sure the project is recognized as a Flutter project:
   - Right-click on `pubspec.yaml`
   - Select "Flutter" → "Get Dependencies"

### Device Not Detected

1. Check device connection:
   - View → Tool Windows → Flutter Device Manager
   - OR run `flutter devices` in terminal

2. Enable USB debugging on Android device

3. Restart ADB:
   ```bash
   adb kill-server
   adb start-server
   ```

## Tips

### Set a Default Configuration
1. Run → Edit Configurations
2. Select your preferred configuration (e.g., "Free (Debug)")
3. Click the folder icon → "Save configuration as project default"

### Keyboard Shortcuts
- `Shift+F10` - Run selected configuration
- `Shift+F9` - Debug selected configuration
- `Ctrl+Shift+F10` - Run context configuration (from editor)
- `Alt+Shift+F10` - Show run configurations menu

### Hot Reload
- `Ctrl+\` or `Ctrl+S` - Hot reload
- `Ctrl+Shift+\` - Hot restart

## Related Documentation

- [GRADLE_BUILD_ERROR_FIX.md](GRADLE_BUILD_ERROR_FIX.md) - Fix Gradle build errors
- [IMPORTANT_RUNNING_INSTRUCTIONS.md](IMPORTANT_RUNNING_INSTRUCTIONS.md) - Complete running guide
- [FLAVOR_SETUP_SUMMARY.md](FLAVOR_SETUP_SUMMARY.md) - Understanding flavors
