/// Configuration for different app flavors (free vs paid)
class FlavorConfig {
  final String name;
  final bool isPaidVersion;
  final String appTitle;
  
  FlavorConfig._({
    required this.name,
    required this.isPaidVersion,
    required this.appTitle,
  });
  
  static FlavorConfig? _instance;
  
  static FlavorConfig get instance {
    _instance ??= _createDefault();
    return _instance!;
  }
  
  static void initialize({
    required String flavor,
  }) {
    switch (flavor.toLowerCase()) {
      case 'paid':
        _instance = FlavorConfig._(
          name: 'paid',
          isPaidVersion: true,
          appTitle: 'Motivator',
        );
        break;
      case 'free':
        _instance = FlavorConfig._(
          name: 'free',
          isPaidVersion: false,
          appTitle: 'Motivator Free',
        );
        break;
      default:
        _instance = _createDefault();
    }
  }
  
  static FlavorConfig _createDefault() {
    // Default to free version if not specified
    return FlavorConfig._(
      name: 'free',
      isPaidVersion: false,
      appTitle: 'Motivator Free',
    );
  }
  
  /// Check if this is the paid version
  bool get isPaid => isPaidVersion;
  
  /// Check if this is the free version
  bool get isFree => !isPaidVersion;
  
  /// Get features available in this flavor
  FlavorFeatures get features => FlavorFeatures(isPaidVersion);
}

/// Features available in different flavors
class FlavorFeatures {
  final bool isPaid;
  
  FlavorFeatures(this.isPaid);
  
  /// Whether ads should be shown (free version only)
  bool get showAds => !isPaid;
  
  /// Whether premium features are available
  bool get hasPremiumFeatures => isPaid;
  
  /// Whether Gemini AI chat is available
  bool get hasGeminiChat => isPaid;
  
  /// Whether unlimited tasks are allowed
  bool get hasUnlimitedTasks => isPaid;
  
  /// Maximum number of tasks per day (null = unlimited)
  int? get maxTasksPerDay => isPaid ? null : 10;
  
  /// Whether recurring tasks are available
  bool get hasRecurringTasks => isPaid;
  
  /// Whether weather widget is available
  bool get hasWeatherWidget => isPaid;
  
  /// Whether custom notifications are available
  bool get hasCustomNotifications => isPaid;
}
