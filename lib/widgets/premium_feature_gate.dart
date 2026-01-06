import 'package:flutter/material.dart';
import '../config/flavor_config.dart';

/// Widget that gates premium features and shows upgrade prompts for free users
class PremiumFeatureGate extends StatelessWidget {
  final Widget child;
  final String featureName;
  final VoidCallback? onUpgrade;
  
  const PremiumFeatureGate({
    super.key,
    required this.child,
    required this.featureName,
    this.onUpgrade,
  });
  
  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    
    // If paid version, show the feature directly
    if (config.isPaid) {
      return child;
    }
    
    // For free version, show upgrade prompt
    return _UpgradePrompt(
      featureName: featureName,
      onUpgrade: onUpgrade,
    );
  }
}

class _UpgradePrompt extends StatelessWidget {
  final String featureName;
  final VoidCallback? onUpgrade;
  
  const _UpgradePrompt({
    required this.featureName,
    this.onUpgrade,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 12),
          Text(
            'Premium Feature',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$featureName is available in the paid version',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onUpgrade ?? () => _showUpgradeDialog(context),
            icon: const Icon(Icons.upgrade),
            label: const Text('Upgrade to Premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'Get access to all premium features including:\n\n'
          '• Unlimited tasks\n'
          '• Gemini AI chat\n'
          '• Recurring tasks\n'
          '• Weather widget\n'
          '• Custom notifications\n'
          '• No ads\n\n'
          'Purchase the paid version on Google Play!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Open Google Play store to paid version
              // You can use url_launcher package to open the Play Store
            },
            child: const Text('Get Premium'),
          ),
        ],
      ),
    );
  }
}

/// Widget that shows a badge indicating a feature is premium-only
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});
  
  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    
    // Don't show badge in paid version
    if (config.isPaid) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'PRO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mixin to add flavor-aware functionality to widgets
mixin FlavorAware {
  FlavorConfig get flavorConfig => FlavorConfig.instance;
  FlavorFeatures get features => FlavorConfig.instance.features;
  
  bool get isPaidVersion => flavorConfig.isPaid;
  bool get isFreeVersion => flavorConfig.isFree;
}
