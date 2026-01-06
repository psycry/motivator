# IntelliJ Quick Start

## ✅ You're All Set!

The Gradle build error has been fixed. IntelliJ run configurations are now properly set up.

## How to Run (IntelliJ/Android Studio)

1. **Look at the top right toolbar** - you'll see a dropdown with run configurations
2. **Select one of these:**
   - `Free (Debug)` - Run free version
   - `Paid (Debug)` - Run paid version
   - `main.dart (→ Free)` - Redirects to free version
3. **Click the green play button** or press `Shift+F10`

## What Was Fixed

✅ Modified `.gitignore` to allow run configurations to be committed
✅ Created 4 IntelliJ run configurations:
   - Free (Debug)
   - Paid (Debug)
   - Free (Release)
   - Paid (Release)
✅ Updated existing `main.dart` configuration to redirect to free version with proper flavor
✅ Added warning comments in `lib/main.dart`
✅ Created quick run scripts (`run_free.bat`, `run_paid.bat`)

## If It Still Doesn't Work

1. **Restart IntelliJ:**
   - File → Invalidate Caches / Restart
   - Select "Invalidate and Restart"

2. **Check the run configuration dropdown:**
   - Should show "Free (Debug)", "Paid (Debug)", etc.
   - If empty, see [docs/INTELLIJ_SETUP.md](docs/INTELLIJ_SETUP.md)

3. **Use the batch scripts as backup:**
   - Double-click `run_free.bat` or `run_paid.bat`

## Why This Happened

The app uses **product flavors** (free and paid versions). When you tried to run `main.dart` without specifying a flavor, Gradle didn't know which variant to build, causing the error.

Now, all run configurations automatically include the correct flavor and target file.

## More Help

- **Complete IntelliJ setup:** [docs/INTELLIJ_SETUP.md](docs/INTELLIJ_SETUP.md)
- **Detailed troubleshooting:** [docs/GRADLE_BUILD_ERROR_FIX.md](docs/GRADLE_BUILD_ERROR_FIX.md)
- **Running instructions:** [RUNNING_GUIDE.md](RUNNING_GUIDE.md)
