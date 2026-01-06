class UserPreferences {
  final bool notificationsEnabled;
  final int notificationMinutesBefore; // Minutes before task start to notify
  final String? geminiApiKey; // User's Gemini API key (encrypted in storage)

  UserPreferences({
    this.notificationsEnabled = true,
    this.notificationMinutesBefore = 5,
    this.geminiApiKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'notificationMinutesBefore': notificationMinutesBefore,
      'geminiApiKey': geminiApiKey,
    };
  }

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      notificationMinutesBefore: map['notificationMinutesBefore'] as int? ?? 5,
      geminiApiKey: map['geminiApiKey'] as String?,
    );
  }

  UserPreferences copyWith({
    bool? notificationsEnabled,
    int? notificationMinutesBefore,
    String? geminiApiKey,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationMinutesBefore: notificationMinutesBefore ?? this.notificationMinutesBefore,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }
  
  bool get hasGeminiApiKey => geminiApiKey != null && geminiApiKey!.isNotEmpty;
}
