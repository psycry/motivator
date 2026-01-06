# Quick Running Guide

## 🚀 How to Run This App

This app uses **product flavors** (free and paid versions). You must specify which version to run.

### ✅ Three Easy Ways to Run

#### 1. Quick Scripts (Easiest)
Just double-click:
- `run_free.bat` - Run free version
- `run_paid.bat` - Run paid version

#### 2. IntelliJ IDEA / Android Studio
1. Click the run configuration dropdown (top right, next to play button)
2. Select "Free (Debug)" or "Paid (Debug)"
3. Click the green play button (or press `Shift+F10`)

#### 3. VS Code
1. Press `Ctrl+Shift+D` (or click Run and Debug icon)
2. Select "Free (Debug)" or "Paid (Debug)" from dropdown
3. Press `F5` or click green play button

#### 4. Terminal Commands
```bash
# Free version
flutter run --flavor free -t lib/main_free.dart

# Paid version
flutter run --flavor paid -t lib/main_paid.dart
```

## ❌ Common Error

If you see:
```
Error: Gradle build failed to produce an .apk file...
```

**You tried to run without specifying a flavor!**

**Fix:** Use one of the three methods above.

## 📚 More Help

- **Detailed troubleshooting:** [docs/GRADLE_BUILD_ERROR_FIX.md](docs/GRADLE_BUILD_ERROR_FIX.md)
- **Complete running instructions:** [docs/IMPORTANT_RUNNING_INSTRUCTIONS.md](docs/IMPORTANT_RUNNING_INSTRUCTIONS.md)
- **Build commands:** [docs/QUICK_BUILD_GUIDE.md](docs/QUICK_BUILD_GUIDE.md)

## 🔧 Building for Release

```bash
# Free version
build_free.bat appbundle

# Paid version
build_paid.bat appbundle
```
