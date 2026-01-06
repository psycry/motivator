# Implementation Examples - Feature Gating

This document shows how to implement flavor-based feature restrictions in your app.

## Example 1: Gating Gemini Chat Widget

### Before (No Restrictions)
```dart
// In your main UI, you might have:
IconButton(
  icon: Icon(Icons.chat),
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => GeminiChatWidget(),
    );
  },
)
```

### After (With Feature Gate)
```dart
import 'package:motivator/config/flavor_config.dart';
import 'package:motivator/widgets/premium_feature_gate.dart';

// Option 1: Hide the button in free version
if (FlavorConfig.instance.features.hasGeminiChat) {
  IconButton(
    icon: Icon(Icons.chat),
    onPressed: () {
      showDialog(
        context: context,
        builder: (context) => GeminiChatWidget(),
      );
    },
  )
}

// Option 2: Show button with premium badge
Stack(
  children: [
    IconButton(
      icon: Icon(Icons.chat),
      onPressed: () {
        if (FlavorConfig.instance.features.hasGeminiChat) {
          showDialog(
            context: context,
            builder: (context) => GeminiChatWidget(),
          );
        } else {
          // Show upgrade dialog
          showDialog(
            context: context,
            builder: (context) => PremiumFeatureGate(
              featureName: 'Gemini AI Chat',
              child: GeminiChatWidget(),
            ),
          );
        }
      },
    ),
    if (!FlavorConfig.instance.features.hasGeminiChat)
      Positioned(
        right: 0,
        top: 0,
        child: PremiumBadge(),
      ),
  ],
)
```

## Example 2: Limiting Tasks Per Day (Free Version)

### In your task creation logic:

```dart
import 'package:motivator/config/flavor_config.dart';

void _showCreateTaskDialog(BuildContext context) {
  final features = FlavorConfig.instance.features;
  
  // Check task limit for free version
  if (features.maxTasksPerDay != null) {
    final todayTasks = timelineTasks.where((task) {
      return task.startTime.day == selectedDate.day &&
             task.startTime.month == selectedDate.month &&
             task.startTime.year == selectedDate.year;
    }).length;
    
    if (todayTasks >= features.maxTasksPerDay!) {
      // Show limit reached dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Task Limit Reached'),
          content: Text(
            'You\'ve reached the limit of ${features.maxTasksPerDay} tasks per day.\n\n'
            'Upgrade to the premium version for unlimited tasks!'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navigate to upgrade
              },
              child: Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }
  }
  
  // Continue with task creation...
  showDialog(
    context: context,
    builder: (context) {
      // Your existing task creation dialog
    },
  );
}
```

## Example 3: Gating Weather Widget

### In your main UI where you show the weather widget:

```dart
import 'package:motivator/config/flavor_config.dart';
import 'package:motivator/widgets/premium_feature_gate.dart';
import 'package:motivator/widgets/weather_widget.dart';

// Conditional rendering
Widget _buildWeatherSection() {
  final features = FlavorConfig.instance.features;
  
  if (features.hasWeatherWidget) {
    return WeatherWidget();
  } else {
    return PremiumFeatureGate(
      featureName: 'Weather Widget',
      child: WeatherWidget(),
    );
  }
}
```

## Example 4: Disabling Recurring Tasks

### In your task creation dialog where you have the recurring option:

```dart
import 'package:motivator/config/flavor_config.dart';

// In your StatefulBuilder or State class:
final features = FlavorConfig.instance.features;

CheckboxListTile(
  title: Row(
    children: [
      Text('Repeat Task'),
      if (!features.hasRecurringTasks) ...[
        SizedBox(width: 8),
        PremiumBadge(),
      ],
    ],
  ),
  subtitle: Text('Choose how often this repeats'),
  value: isRecurring,
  enabled: features.hasRecurringTasks, // Disable in free version
  onChanged: features.hasRecurringTasks
      ? (value) {
          setState(() {
            isRecurring = value ?? false;
          });
        }
      : (value) {
          // Show upgrade prompt
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Premium Feature'),
              content: Text('Recurring tasks are available in the premium version.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        },
)
```

## Example 5: Settings Page with Flavor Info

### Add flavor information to your settings:

```dart
import 'package:motivator/config/flavor_config.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    
    return ListView(
      children: [
        // Version info
        ListTile(
          title: Text('Version'),
          subtitle: Text(config.appTitle),
          trailing: config.isPaid 
              ? Chip(
                  label: Text('Premium'),
                  backgroundColor: Colors.amber,
                )
              : Chip(
                  label: Text('Free'),
                  backgroundColor: Colors.grey,
                ),
        ),
        
        // Show upgrade option in free version
        if (config.isFree) ...[
          Divider(),
          ListTile(
            leading: Icon(Icons.upgrade, color: Colors.amber),
            title: Text('Upgrade to Premium'),
            subtitle: Text('Unlock all features'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to upgrade flow
            },
          ),
        ],
        
        Divider(),
        
        // Feature list
        ListTile(
          title: Text('Available Features'),
        ),
        _buildFeatureItem('Unlimited Tasks', config.features.hasUnlimitedTasks),
        _buildFeatureItem('Gemini AI Chat', config.features.hasGeminiChat),
        _buildFeatureItem('Recurring Tasks', config.features.hasRecurringTasks),
        _buildFeatureItem('Weather Widget', config.features.hasWeatherWidget),
        _buildFeatureItem('Custom Notifications', config.features.hasCustomNotifications),
      ],
    );
  }
  
  Widget _buildFeatureItem(String name, bool available) {
    return ListTile(
      leading: Icon(
        available ? Icons.check_circle : Icons.lock,
        color: available ? Colors.green : Colors.grey,
      ),
      title: Text(name),
      trailing: available ? null : PremiumBadge(),
    );
  }
}
```

## Example 6: Using the FlavorAware Mixin

### In any StatefulWidget or StatelessWidget:

```dart
import 'package:motivator/widgets/premium_feature_gate.dart';

class MyCustomWidget extends StatelessWidget with FlavorAware {
  @override
  Widget build(BuildContext context) {
    // Access flavor config directly
    if (isPaidVersion) {
      return Text('Welcome to ${flavorConfig.appTitle}!');
    }
    
    // Use feature flags
    if (features.hasGeminiChat) {
      return ChatButton();
    }
    
    return UpgradePrompt();
  }
}
```

## Example 7: Showing Ads (Free Version Only)

### When you implement ads:

```dart
import 'package:motivator/config/flavor_config.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // Add this dependency

class MyHomePage extends StatefulWidget {
  // ...
}

class _MyHomePageState extends State<MyHomePage> {
  // BannerAd? _bannerAd;
  
  @override
  void initState() {
    super.initState();
    _loadAds();
  }
  
  void _loadAds() {
    final features = FlavorConfig.instance.features;
    
    // Only load ads in free version
    if (features.showAds) {
      // TODO: Initialize and load banner ad
      // _bannerAd = BannerAd(...)
      // _bannerAd?.load();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: YourMainContent(),
        ),
        
        // Show ad banner only in free version
        if (FlavorConfig.instance.features.showAds)
          Container(
            height: 50,
            color: Colors.grey[300],
            child: Center(
              child: Text('Ad Space (TODO: Implement)'),
            ),
          ),
      ],
    );
  }
}
```

## Testing Both Versions

### Quick test to verify flavor configuration:

```dart
// Add this to your main.dart temporarily
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... Firebase initialization ...
  
  // Print flavor info
  print('========================================');
  print('FLAVOR CONFIGURATION');
  print('========================================');
  print('App Title: ${FlavorConfig.instance.appTitle}');
  print('Is Paid: ${FlavorConfig.instance.isPaid}');
  print('Is Free: ${FlavorConfig.instance.isFree}');
  print('Has Gemini Chat: ${FlavorConfig.instance.features.hasGeminiChat}');
  print('Max Tasks Per Day: ${FlavorConfig.instance.features.maxTasksPerDay ?? "Unlimited"}');
  print('========================================');
  
  runApp(const MyApp());
}
```

## Next Steps

1. **Choose which features to gate** - Decide what should be premium-only
2. **Implement the restrictions** - Use the examples above as templates
3. **Test both versions** - Build and run both flavors to verify
4. **Add upgrade flow** - Implement in-app purchase or Play Store link
5. **Implement ads** - Add AdMob for the free version
6. **Update UI** - Add premium badges and upgrade prompts throughout the app

## Resources

- `lib/config/flavor_config.dart` - Main configuration
- `lib/widgets/premium_feature_gate.dart` - Ready-to-use gating widgets
- `FLAVOR_SETUP.md` - Complete setup documentation
- `QUICK_BUILD_GUIDE.md` - Quick reference for building
