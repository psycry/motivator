# API Key Setup Guide

## ✨ NEW: User-Based API Keys

**Good news!** This app now uses **user-provided API keys** instead of hardcoded keys. Each user enters their own Gemini API key through the Settings dialog.

### Benefits
- ✅ No API keys in source code
- ✅ Each user controls their own quota
- ✅ Safe to share code publicly
- ✅ Better security

## 🔑 For End Users

### Google Gemini API Key (for AI Chat)

**How to get your free API key:**
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key

**How to add it to the app:**
1. Open the Motivator app
2. Click the Settings icon (gear icon)
3. Scroll to "Gemini AI Chat" section
4. Paste your API key in the text field
5. Click "Save"

**That's it!** Your API key is securely stored with your account and you can now use the AI chat feature.

### If You Don't Have an API Key Yet

When you try to use the Gemini chat without an API key, you'll see a helpful message with instructions on how to get one.

### 2. OpenWeatherMap API Key (for Weather Widget)

**Location:** `lib/widgets/weather_widget.dart`

**How to get it:**
1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Go to API Keys section
4. Copy your API key

**How to add it:**
1. Open `lib/widgets/weather_widget.dart`
2. Find the API key constant
3. Replace with your actual API key
4. Save the file

## 🔒 Best Practices for API Keys

### DO:
- ✅ Keep API keys in a separate configuration file (not committed to git)
- ✅ Use environment variables for production
- ✅ Add API key files to `.gitignore`
- ✅ Rotate API keys regularly
- ✅ Use different API keys for development and production
- ✅ Set up API key restrictions in the provider's console

### DON'T:
- ❌ Commit API keys to version control
- ❌ Share API keys in public repositories
- ❌ Hardcode API keys in production code
- ❌ Use the same API key across multiple projects
- ❌ Share screenshots containing API keys

## 🛡️ Recommended: Use Environment Variables

For better security, use environment variables instead of hardcoding:

### Step 1: Create a config file (not committed)

Create `lib/config/api_keys.dart`:

```dart
class ApiKeys {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
  );
  
  static const String weatherApiKey = String.fromEnvironment(
    'WEATHER_API_KEY',
    defaultValue: 'YOUR_WEATHER_API_KEY_HERE',
  );
}
```

### Step 2: Add to .gitignore

Add this line to `.gitignore`:
```
lib/config/api_keys.dart
```

### Step 3: Use in your code

In `gemini_chat_widget.dart`:
```dart
import '../config/api_keys.dart';

void _initializeGemini() {
  const apiKey = ApiKeys.geminiApiKey;
  // ... rest of code
}
```

### Step 4: Run with environment variables

```bash
flutter run --dart-define=GEMINI_API_KEY=your-key-here --dart-define=WEATHER_API_KEY=your-key-here
```

## 📝 .gitignore Setup

Make sure your `.gitignore` includes:

```gitignore
# API Keys and sensitive data
lib/config/api_keys.dart
*.env
.env
.env.local

# Google Services (contains sensitive data)
google-services.json
GoogleService-Info.plist
```

## 🔐 API Key Restrictions

### Google Gemini API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to "APIs & Services" → "Credentials"
4. Click on your API key
5. Add restrictions:
   - **Application restrictions:** Android apps
   - **API restrictions:** Generative Language API
   - **Android app restrictions:** Add your app's package name and SHA-1 fingerprint

### OpenWeatherMap API
1. Go to your [OpenWeatherMap account](https://home.openweathermap.org/api_keys)
2. Click on your API key
3. Set usage limits to prevent abuse

## 🚨 If Your API Key is Exposed

If you accidentally commit an API key:

1. **Immediately revoke the key** in the provider's console
2. **Generate a new API key**
3. **Update your code** with the new key
4. **Remove the key from git history:**
   ```bash
   # This is complex - consider creating a new repository
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch path/to/file" \
     --prune-empty --tag-name-filter cat -- --all
   ```
5. **Force push** (if working with a remote repository)
6. **Notify your team** if working collaboratively

## 📚 Additional Resources

- [Google AI Studio API Keys](https://makersuite.google.com/app/apikey)
- [OpenWeatherMap API](https://openweathermap.org/api)
- [Flutter Environment Variables](https://flutter.dev/docs/deployment/flavors#using-environment-variables)
- [Git Secrets Tool](https://github.com/awslabs/git-secrets)

## ✅ Checklist

Before committing code:
- [ ] No API keys in source files
- [ ] API key files added to `.gitignore`
- [ ] Using environment variables or config files
- [ ] Config files not committed to repository
- [ ] API keys have proper restrictions set
- [ ] Different keys for dev and production

## 🔄 Current Status

**Gemini API Key:** ⚠️ Placeholder - needs to be added
**Weather API Key:** ⚠️ Check if configured

To enable AI chat, add your Gemini API key following the instructions above.
