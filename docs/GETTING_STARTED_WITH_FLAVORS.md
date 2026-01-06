# Getting Started with Product Flavors

Welcome! Your app is now configured to support **two separate versions** from a single codebase. This guide will help you understand what was set up and how to use it.

## 🎯 What You Have Now

Your Motivator app can now be built in two flavors:

### 1. **Free Version** 
- Package: `sh.digitalnomad.motivator.free`
- App Name: "Motivator Free"
- Limited features (10 tasks/day, no AI chat, etc.)
- Can show ads (when implemented)

### 2. **Paid Version**
- Package: `sh.digitalnomad.motivator`
- App Name: "Motivator"
- Full features (unlimited tasks, AI chat, recurring tasks, etc.)
- No ads

**Both versions can be published to Google Play Store separately!**

## 🚀 Try It Now

### Step 1: Run the Free Version

Open a terminal in your project directory and run:

```bash
flutter run --flavor free -t lib/main_free.dart
```

Or use the batch script:
```bash
build_free.bat debug
```

Or use VS Code:
1. Press `Ctrl+Shift+D` (Run and Debug)
2. Select "Free (Debug)" from the dropdown
3. Press F5

### Step 2: Check the App Name

When the app launches, look at:
- The app title in the device launcher - should say "Motivator Free"
- The console output - should print flavor information

### Step 3: Run the Paid Version

In a new terminal (or stop the free version first):

```bash
flutter run --flavor paid -t lib/main_paid.dart
```

Or:
```bash
build_paid.bat debug
```

Or use VS Code "Paid (Debug)" configuration.

### Step 4: Install Both Simultaneously

Both versions can run on the same device at the same time!

```bash
# Install free version
flutter install --flavor free -t lib/main_free.dart

# Install paid version (without removing free)
flutter install --flavor paid -t lib/main_paid.dart
```

Now you'll see two "Motivator" apps in your launcher:
- "Motivator Free" (free version)
- "Motivator" (paid version)

## 📋 What Was Changed

### New Files Created

**Dart/Flutter:**
- `lib/config/flavor_config.dart` - Central configuration for flavors
- `lib/main_free.dart` - Entry point for free version
- `lib/main_paid.dart` - Entry point for paid version
- `lib/widgets/premium_feature_gate.dart` - Widgets for gating features

**Android:**
- `android/app/src/free/res/values/strings.xml` - Free version app name
- `android/app/src/paid/res/values/strings.xml` - Paid version app name

**Build Scripts:**
- `build_free.bat` - Windows script to build free version
- `build_paid.bat` - Windows script to build paid version
- `.vscode/launch.json` - VS Code debug configurations

**Documentation:**
- `FLAVOR_SETUP.md` - Complete technical guide
- `QUICK_BUILD_GUIDE.md` - Quick command reference
- `IMPLEMENTATION_EXAMPLES.md` - Code examples
- `FEATURE_GATING_CHECKLIST.md` - Implementation checklist
- `FLAVOR_SETUP_SUMMARY.md` - Quick overview
- `GETTING_STARTED_WITH_FLAVORS.md` - This file
- Updated `README.md` - Project overview

### Modified Files

**Dart:**
- `lib/main.dart` - Added flavor config import and usage

**Android:**
- `android/app/build.gradle.kts` - Added product flavors configuration
- `android/app/src/main/AndroidManifest.xml` - Uses dynamic app name

## 🎨 How It Works

### 1. Flavor Detection

Each version has its own entry point that initializes the flavor:

**Free Version** (`lib/main_free.dart`):
```dart
void main() {
  FlavorConfig.initialize(flavor: 'free');
  app.main();
}
```

**Paid Version** (`lib/main_paid.dart`):
```dart
void main() {
  FlavorConfig.initialize(flavor: 'paid');
  app.main();
}
```

### 2. Feature Flags

You can check which features are available:

```dart
import 'package:motivator/config/flavor_config.dart';

// Check if paid version
if (FlavorConfig.instance.isPaid) {
  // Show premium feature
}

// Check specific features
if (FlavorConfig.instance.features.hasGeminiChat) {
  // Show Gemini chat
}

// Get task limit
final limit = FlavorConfig.instance.features.maxTasksPerDay;
// Returns 10 for free, null for paid (unlimited)
```

### 3. Build Configuration

The Android build system creates different APKs/bundles:

- Free version gets package ID: `sh.digitalnomad.motivator.free`
- Paid version gets package ID: `sh.digitalnomad.motivator`
- Each has its own app name and can have different icons

## 📝 Next Steps

### Immediate Next Steps

1. **Test both versions** - Make sure they both run correctly
2. **Verify flavor detection** - Check the console output shows correct flavor
3. **Review the documentation** - Familiarize yourself with the setup

### Implementation Next Steps

1. **Choose features to gate** - Decide what should be premium-only
2. **Implement restrictions** - Use the examples in `IMPLEMENTATION_EXAMPLES.md`
3. **Add premium badges** - Show users what's locked in free version
4. **Create upgrade flow** - Let free users upgrade to paid

See `FEATURE_GATING_CHECKLIST.md` for a systematic implementation guide.

### Before Publishing

1. **Set up signing** - Configure release signing in `build.gradle.kts`
2. **Test thoroughly** - Test all features in both versions
3. **Prepare assets** - Create screenshots, descriptions for both versions
4. **Build release bundles** - Use the build scripts to create final builds

## 🔍 Verification

### Quick Test: Check Flavor Configuration

Add this to your `main()` function temporarily:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... your existing Firebase initialization ...
  
  // Add this debug output
  print('========================================');
  print('FLAVOR: ${FlavorConfig.instance.name}');
  print('APP TITLE: ${FlavorConfig.instance.appTitle}');
  print('IS PAID: ${FlavorConfig.instance.isPaid}');
  print('========================================');
  
  runApp(const MyApp());
}
```

Run both versions and verify the output is different!

### Visual Verification

When you run each version, you should see:

**Free Version:**
- Console: "FLAVOR: free"
- Console: "APP TITLE: Motivator Free"
- Console: "IS PAID: false"
- Device launcher: "Motivator Free"

**Paid Version:**
- Console: "FLAVOR: paid"
- Console: "APP TITLE: Motivator"
- Console: "IS PAID: true"
- Device launcher: "Motivator"

## 🐛 Troubleshooting

### "No flavor specified" error
Make sure you include `--flavor free` or `--flavor paid` in your command.

### Wrong app name showing
Verify you're using the correct entry point:
- Free: `-t lib/main_free.dart`
- Paid: `-t lib/main_paid.dart`

### Build errors
Try cleaning and rebuilding:
```bash
flutter clean
flutter pub get
flutter run --flavor free -t lib/main_free.dart
```

### Both apps have same name
Check that the flavor-specific `strings.xml` files were created correctly in:
- `android/app/src/free/res/values/strings.xml`
- `android/app/src/paid/res/values/strings.xml`

## 📚 Learning Resources

### Start Here
1. Read `FLAVOR_SETUP_SUMMARY.md` - Quick overview
2. Try `QUICK_BUILD_GUIDE.md` - Learn the commands
3. Review `IMPLEMENTATION_EXAMPLES.md` - See code examples

### Deep Dive
1. Read `FLAVOR_SETUP.md` - Complete technical details
2. Follow `FEATURE_GATING_CHECKLIST.md` - Implement restrictions
3. Check Flutter docs on flavors - [flutter.dev/docs/deployment/flavors](https://flutter.dev/docs/deployment/flavors)

## 💡 Pro Tips

1. **Use VS Code configurations** - Easier than typing commands
2. **Test both versions frequently** - Catch issues early
3. **Keep feature flags consistent** - Don't hardcode flavor checks
4. **Document your decisions** - Note which features are premium and why
5. **Start simple** - Gate one feature at a time

## ✅ Success Checklist

- [ ] Successfully ran free version
- [ ] Successfully ran paid version
- [ ] Installed both versions on same device
- [ ] Verified different app names in launcher
- [ ] Checked console output shows correct flavor
- [ ] Read the documentation files
- [ ] Understand how to gate features
- [ ] Ready to implement feature restrictions

## 🎉 You're Ready!

You now have a professional dual-version setup for your app. The infrastructure is in place - now you just need to:

1. Decide which features should be premium
2. Implement the restrictions using the provided tools
3. Test thoroughly
4. Build and publish to Google Play

**Good luck with your app!** 🚀

---

**Questions?** Check the other documentation files or review the code examples.

**Need help?** All the configuration is in `lib/config/flavor_config.dart` - that's your central control point.
