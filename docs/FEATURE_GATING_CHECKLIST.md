# Feature Gating Implementation Checklist

Use this checklist to systematically add flavor-based restrictions to your app.

## ✅ Core Features to Gate

### 1. Gemini AI Chat Widget
- [ ] Add feature check before showing chat button
- [ ] Show premium badge on chat button in free version
- [ ] Display upgrade prompt when free users tap chat
- [ ] Test: Verify chat works in paid version
- [ ] Test: Verify upgrade prompt shows in free version

**Location:** Wherever you show the Gemini chat button (likely in main UI)

**Code:**
```dart
if (FlavorConfig.instance.features.hasGeminiChat) {
  // Show chat button
} else {
  // Show locked button with upgrade prompt
}
```

---

### 2. Task Limit (10 per day for free)
- [ ] Count tasks for current day before allowing creation
- [ ] Show limit reached dialog in free version
- [ ] Add upgrade button in limit dialog
- [ ] Test: Create 10 tasks in free version
- [ ] Test: Verify 11th task shows limit dialog
- [ ] Test: Verify unlimited in paid version

**Location:** `_showCreateTaskDialog()` method in main.dart

**Code:**
```dart
final features = FlavorConfig.instance.features;
if (features.maxTasksPerDay != null) {
  final todayTasks = timelineTasks.where((task) {
    // Count tasks for today
  }).length;
  
  if (todayTasks >= features.maxTasksPerDay!) {
    // Show limit dialog
    return;
  }
}
```

---

### 3. Recurring Tasks
- [ ] Disable recurring task checkbox in free version
- [ ] Add premium badge next to recurring option
- [ ] Show upgrade prompt when free users tap disabled option
- [ ] Test: Verify recurring works in paid version
- [ ] Test: Verify disabled in free version

**Location:** `_showCreateTaskDialog()` in the recurring tasks section (around line 887)

**Code:**
```dart
CheckboxListTile(
  enabled: FlavorConfig.instance.features.hasRecurringTasks,
  // ... rest of configuration
)
```

---

### 4. Weather Widget
- [ ] Conditionally show weather widget based on flavor
- [ ] Show upgrade prompt in place of widget for free users
- [ ] Test: Verify weather shows in paid version
- [ ] Test: Verify upgrade prompt in free version

**Location:** Where WeatherWidget is displayed in your UI

**Code:**
```dart
if (FlavorConfig.instance.features.hasWeatherWidget) {
  WeatherWidget()
} else {
  PremiumFeatureGate(
    featureName: 'Weather Widget',
    child: WeatherWidget(),
  )
}
```

---

### 5. Custom Notifications
- [ ] Check feature flag before allowing notification customization
- [ ] Show premium badge on notification settings
- [ ] Limit notification options in free version
- [ ] Test: Verify full customization in paid version
- [ ] Test: Verify limited options in free version

**Location:** Settings dialog or notification configuration

**Code:**
```dart
if (FlavorConfig.instance.features.hasCustomNotifications) {
  // Show full notification settings
} else {
  // Show basic notification settings only
}
```

---

## 📱 UI Enhancements

### 6. Add Premium Badges
- [ ] Import `PremiumBadge` widget
- [ ] Add badge to Gemini chat button
- [ ] Add badge to recurring tasks option
- [ ] Add badge to weather widget
- [ ] Add badge to custom notification settings
- [ ] Test: Verify badges only show in free version

**Code:**
```dart
import 'package:motivator/widgets/premium_feature_gate.dart';

Stack(
  children: [
    YourFeatureButton(),
    if (!FlavorConfig.instance.isPaid)
      Positioned(
        right: 0,
        top: 0,
        child: PremiumBadge(),
      ),
  ],
)
```

---

### 7. Settings Page Updates
- [ ] Show current version (Free/Paid) in settings
- [ ] Add "Upgrade to Premium" option in free version
- [ ] List available vs locked features
- [ ] Add version info
- [ ] Test: Verify correct info shows for each version

**Location:** Settings dialog

---

### 8. Add Upgrade Prompts
- [ ] Create consistent upgrade dialog design
- [ ] List premium features in upgrade prompt
- [ ] Add "Get Premium" button (links to Play Store)
- [ ] Test: Verify upgrade prompts work correctly

---

## 🎨 Optional Enhancements

### 9. Ad Integration (Free Version)
- [ ] Add `google_mobile_ads` dependency to pubspec.yaml
- [ ] Initialize AdMob
- [ ] Create banner ad widget
- [ ] Show ads only when `features.showAds` is true
- [ ] Test: Verify ads show in free version only
- [ ] Test: Verify no ads in paid version

**Code:**
```dart
if (FlavorConfig.instance.features.showAds) {
  // Show banner ad
}
```

---

### 10. Splash Screen Customization
- [ ] Create flavor-specific splash screens (optional)
- [ ] Different colors/logos for free vs paid
- [ ] Test: Verify correct splash for each version

---

### 11. App Icons
- [ ] Create different icons for free vs paid (optional)
- [ ] Place in `android/app/src/free/res/mipmap-*/`
- [ ] Place in `android/app/src/paid/res/mipmap-*/`
- [ ] Test: Verify correct icon shows for each version

---

## 🧪 Testing Checklist

### Build Tests
- [ ] Build free version APK successfully
- [ ] Build paid version APK successfully
- [ ] Build free version app bundle successfully
- [ ] Build paid version app bundle successfully
- [ ] Verify different package names in builds
- [ ] Verify different app names in builds

### Runtime Tests
- [ ] Install both versions on same device simultaneously
- [ ] Verify free version shows "Motivator Free" name
- [ ] Verify paid version shows "Motivator" name
- [ ] Test all gated features in free version
- [ ] Test all features work in paid version
- [ ] Verify upgrade prompts appear correctly
- [ ] Verify premium badges show correctly

### Feature Tests - Free Version
- [ ] Can create up to 10 tasks per day
- [ ] Cannot create 11th task (shows limit dialog)
- [ ] Gemini chat shows upgrade prompt
- [ ] Recurring tasks option is disabled
- [ ] Weather widget shows upgrade prompt
- [ ] Notification settings are limited
- [ ] Premium badges visible on locked features

### Feature Tests - Paid Version
- [ ] Can create unlimited tasks
- [ ] Gemini chat works fully
- [ ] Recurring tasks work fully
- [ ] Weather widget displays
- [ ] Full notification customization available
- [ ] No premium badges visible
- [ ] No upgrade prompts

---

## 📦 Pre-Release Checklist

### Code Review
- [ ] All feature gates implemented
- [ ] No hardcoded flavor checks (use FlavorConfig)
- [ ] Consistent upgrade prompt messaging
- [ ] All premium badges added
- [ ] Code comments added for flavor-specific logic

### Documentation
- [ ] Update README with flavor information
- [ ] Document any flavor-specific setup steps
- [ ] Create release notes for both versions

### Build Configuration
- [ ] Signing configuration set up for release builds
- [ ] ProGuard rules configured (if using)
- [ ] Version numbers set correctly
- [ ] Firebase projects configured (if using separate projects)

### Google Play Preparation
- [ ] Create two app listings on Play Console
- [ ] Prepare screenshots for both versions
- [ ] Write descriptions highlighting differences
- [ ] Set pricing for paid version
- [ ] Configure in-app products (if offering upgrade from free)

---

## 🚀 Deployment Checklist

### Free Version
- [ ] Build release app bundle
- [ ] Test on multiple devices
- [ ] Upload to Google Play (Internal Testing)
- [ ] Test from Play Store
- [ ] Promote to Production

### Paid Version
- [ ] Build release app bundle
- [ ] Test on multiple devices
- [ ] Upload to Google Play (Internal Testing)
- [ ] Test from Play Store
- [ ] Promote to Production

---

## 📊 Post-Launch Monitoring

- [ ] Monitor crash reports for both versions
- [ ] Track feature usage in each version
- [ ] Monitor conversion rate (free to paid)
- [ ] Collect user feedback
- [ ] Analyze which features drive upgrades

---

## 💡 Tips

1. **Start with one feature** - Implement and test one gated feature at a time
2. **Test frequently** - Build and test both versions after each change
3. **Be consistent** - Use the same upgrade prompt design throughout
4. **Clear messaging** - Make it obvious what users get with premium
5. **Smooth experience** - Don't make free version frustrating, just limited

---

## ✅ Quick Verification

Run this code snippet in your app to verify flavor configuration:

```dart
void _debugFlavorConfig() {
  final config = FlavorConfig.instance;
  final features = config.features;
  
  print('=== FLAVOR DEBUG ===');
  print('App Title: ${config.appTitle}');
  print('Is Paid: ${config.isPaid}');
  print('Has Gemini Chat: ${features.hasGeminiChat}');
  print('Has Recurring Tasks: ${features.hasRecurringTasks}');
  print('Has Weather Widget: ${features.hasWeatherWidget}');
  print('Max Tasks Per Day: ${features.maxTasksPerDay ?? "Unlimited"}');
  print('Show Ads: ${features.showAds}');
  print('==================');
}
```

---

**Good luck with your implementation!** 🎉

Check off items as you complete them. This systematic approach will ensure you don't miss any important features.
