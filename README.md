# Motivator

A Flutter-based task tracking and productivity app with AI-powered assistance.

## 📱 Available Versions

This app supports **two product flavors** for Google Play distribution:

| Version | Package ID | Features | Price |
|---------|-----------|----------|-------|
| **Free** | `sh.digitalnomad.motivator.free` | Basic task management (up to 10 tasks/day) | Free |
| **Paid** | `sh.digitalnomad.motivator` | Unlimited tasks, AI chat, recurring tasks, weather | Paid |

## 🚀 Quick Start

### Running the App

**Option 1: Quick Scripts (Easiest)**
```bash
run_free.bat    # Run free version
run_paid.bat    # Run paid version
```

**Option 2: IntelliJ IDEA / Android Studio**
- Click run configuration dropdown (top right)
- Select "Free (Debug)" or "Paid (Debug)"
- Click play button or press `Shift+F10`

**Option 3: VS Code**
- Press `Ctrl+Shift+D` (Run and Debug)
- Select "Free (Debug)" or "Paid (Debug)"
- Press `F5`

**Option 4: Terminal Commands**
```bash
# Free Version
flutter run --flavor free -t lib/main_free.dart

# Paid Version
flutter run --flavor paid -t lib/main_paid.dart
```

⚠️ **Important:** Do NOT run `flutter run lib/main.dart` - it will fail! See [docs/GRADLE_BUILD_ERROR_FIX.md](docs/GRADLE_BUILD_ERROR_FIX.md)

### Building for Release

**Free Version:**
```bash
build_free.bat appbundle
```

**Paid Version:**
```bash
build_paid.bat appbundle
```

## 📚 Documentation

All documentation has been moved to the [`docs/`](docs/) directory. See [`docs/INDEX.md`](docs/INDEX.md) for a complete list.

### Essential Guides
- **[IMPORTANT_RUNNING_INSTRUCTIONS.md](docs/IMPORTANT_RUNNING_INSTRUCTIONS.md)** ⭐ - How to run with flavors
- **[API_KEY_SETUP.md](docs/API_KEY_SETUP.md)** ⚠️ - API key configuration and security
- **[QUICK_BUILD_GUIDE.md](docs/QUICK_BUILD_GUIDE.md)** - Quick reference for build commands

### Setup & Configuration
- **[FLAVOR_SETUP_SUMMARY.md](docs/FLAVOR_SETUP_SUMMARY.md)** - Quick overview of the dual-version setup
- **[FLAVOR_SETUP.md](docs/FLAVOR_SETUP.md)** - Complete technical documentation
- **[FIREBASE_FLAVORS_SETUP.md](docs/FIREBASE_FLAVORS_SETUP.md)** - Firebase configuration for flavors
- **[FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)** - Firebase setup instructions
- **[GOOGLE_SIGNIN_SETUP.md](docs/GOOGLE_SIGNIN_SETUP.md)** - Google Sign-In configuration
- **[ICON_SETUP.md](docs/ICON_SETUP.md)** - App icon configuration

### Features
- **[GEMINI_CHAT_SETUP.md](docs/GEMINI_CHAT_SETUP.md)** - AI chat setup
- **[WEATHER_SETUP.md](docs/WEATHER_SETUP.md)** - Weather widget setup
- **[NOTIFICATIONS_SETUP.md](docs/NOTIFICATIONS_SETUP.md)** - Notification configuration
- **[RECURRING_TASKS_GUIDE.md](docs/RECURRING_TASKS_GUIDE.md)** - Recurring tasks feature
- **[SUBTASKS_FEATURE.md](docs/SUBTASKS_FEATURE.md)** - Subtasks feature

### Implementation
- **[IMPLEMENTATION_EXAMPLES.md](docs/IMPLEMENTATION_EXAMPLES.md)** - Code examples for feature gating
- **[FEATURE_GATING_CHECKLIST.md](docs/FEATURE_GATING_CHECKLIST.md)** - Implementation checklist

### Troubleshooting
- **[DESUGARING_FIX.md](docs/DESUGARING_FIX.md)** - Core library desugaring configuration
- **[BUILD_FIXES_APPLIED.md](docs/BUILD_FIXES_APPLIED.md)** - Build issue fixes

## ✨ Features

### Free Version
- ✅ Basic task management
- ✅ Up to 10 tasks per day
- ✅ Calendar view
- ✅ Task tracking and completion
- ✅ Basic notifications
- ✅ Notes functionality

### Paid Version (All Free Features Plus)
- ✅ **Unlimited tasks**
- ✅ **Gemini AI chat assistant**
- ✅ **Recurring tasks**
- ✅ **Weather widget**
- ✅ **Custom notifications**
- ✅ **No ads**
- ✅ **Full customization**

## 🛠️ Tech Stack

- **Framework:** Flutter 3.9+
- **Backend:** Firebase (Authentication, Firestore)
- **AI:** Google Gemini API
- **Notifications:** flutter_local_notifications
- **Weather:** OpenWeatherMap API
- **State Management:** StatefulWidget

## 📦 Project Structure

```
lib/
├── config/
│   └── flavor_config.dart          # Flavor configuration
├── main.dart                        # Main app entry
├── main_free.dart                   # Free version entry point
├── main_paid.dart                   # Paid version entry point
├── models/                          # Data models
├── pages/                           # App pages
├── services/                        # Business logic services
└── widgets/                         # Reusable widgets
    └── premium_feature_gate.dart    # Feature gating widget

android/
└── app/
    ├── build.gradle.kts             # Product flavors config
    └── src/
        ├── free/                    # Free version resources
        ├── paid/                    # Paid version resources
        └── main/                    # Shared resources
```

## 🔧 Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd motivator
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Set up Firebase projects for your app
   - Download `google-services.json`
   - Place in `android/app/` directory

4. **Configure API Keys** (See [`docs/API_KEY_SETUP.md`](docs/API_KEY_SETUP.md) for detailed instructions)
   - Add Gemini API key in `lib/widgets/gemini_chat_widget.dart` (for AI chat)
   - Get your key from: https://makersuite.google.com/app/apikey
   - Add OpenWeatherMap API key (for weather widget)

5. **Run the app**
   ```bash
   flutter run --flavor free -t lib/main_free.dart
   ```

## 🧪 Testing

### Test Both Versions Simultaneously
Both versions can be installed on the same device:

```bash
# Install free version
flutter install --flavor free -t lib/main_free.dart

# Install paid version
flutter install --flavor paid -t lib/main_paid.dart
```

### VS Code Launch Configurations
Use the Run and Debug panel (Ctrl+Shift+D) and select:
- "Free (Debug)" - Run free version
- "Paid (Debug)" - Run paid version

## 📱 Building for Production

### Generate Release Builds

**Free Version APK:**
```bash
flutter build apk --flavor free -t lib/main_free.dart --release
```

**Paid Version App Bundle:**
```bash
flutter build appbundle --flavor paid -t lib/main_paid.dart --release
```

### Output Locations
- Free APK: `build/app/outputs/flutter-apk/app-free-release.apk`
- Paid APK: `build/app/outputs/flutter-apk/app-paid-release.apk`
- Free Bundle: `build/app/outputs/bundle/freeRelease/app-free-release.aab`
- Paid Bundle: `build/app/outputs/bundle/paidRelease/app-paid-release.aab`

## 🎯 Implementation Status

- ✅ Product flavors configured
- ✅ Flavor detection system
- ✅ Feature flag framework
- ✅ Premium feature gate widgets
- ✅ Build scripts
- ✅ VS Code configurations
- ⏳ Feature restrictions (see FEATURE_GATING_CHECKLIST.md)
- ⏳ Ad integration for free version
- ⏳ Upgrade flow implementation

## 📄 License

[Your License Here]

## 🤝 Contributing

[Your Contributing Guidelines Here]

## 📧 Contact

[Your Contact Information Here]
