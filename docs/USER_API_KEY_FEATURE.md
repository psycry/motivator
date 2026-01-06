# User API Key Feature

## Overview

Users can now securely store their own Gemini API key in their account settings. This eliminates the need to hardcode API keys in the source code and allows each user to use their own API quota.

## ✨ Features

- **Secure Storage**: API keys are stored in Firebase with the user's account
- **Easy Setup**: Users can add/update their API key through the Settings dialog
- **Privacy**: API keys are obscured by default (show/hide toggle)
- **Validation**: Chat widget checks for API key before attempting to use Gemini
- **User-Friendly**: Clear instructions on how to get a free API key

## 🔧 How It Works

### 1. User Preferences Model

The `UserPreferences` model now includes:
```dart
final String? geminiApiKey; // User's Gemini API key
bool get hasGeminiApiKey => geminiApiKey != null && geminiApiKey!.isNotEmpty;
```

### 2. Settings Dialog

Users can enter their API key in Settings:
- Text field with show/hide toggle for security
- Helper text with link to get API key
- Stored securely when user clicks Save

### 3. Gemini Chat Widget

The chat widget now:
- Accepts `UserPreferences` as a parameter
- Checks if user has configured an API key
- Shows helpful message if no API key is set
- Uses the user's API key for all Gemini API calls

### 4. Firebase Storage

API keys are stored in Firestore under the user's preferences:
```
users/{userId}/preferences/geminiApiKey
```

## 📱 User Experience

### First Time Setup

1. User opens the app
2. Clicks on Gemini chat icon
3. Sees message: "Please add your Gemini API key in Settings"
4. Clicks Settings (gear icon)
5. Scrolls to "Gemini AI Chat" section
6. Enters their API key
7. Clicks Save
8. Can now use AI chat feature

### Getting an API Key

Users are directed to:
- **URL**: https://makersuite.google.com/app/apikey
- **Steps**:
  1. Sign in with Google account
  2. Click "Create API Key"
  3. Copy the generated key
  4. Paste into Settings

### Updating API Key

Users can update their API key anytime:
1. Open Settings
2. Update the API key field
3. Click Save

## 🔒 Security Benefits

### Before (Hardcoded)
- ❌ API key exposed in source code
- ❌ Single API key shared by all users
- ❌ Risk of quota exhaustion
- ❌ Security risk if code is public

### After (User-Provided)
- ✅ Each user uses their own API key
- ✅ No API keys in source code
- ✅ Users control their own quota
- ✅ API keys stored securely in Firebase
- ✅ Safe to share code publicly

## 🎯 Implementation Details

### Files Modified

1. **`lib/models/user_preferences.dart`**
   - Added `geminiApiKey` field
   - Added `hasGeminiApiKey` getter
   - Updated `toMap()`, `fromMap()`, and `copyWith()`

2. **`lib/widgets/settings_dialog.dart`**
   - Added API key text field
   - Added show/hide toggle
   - Added helper information
   - Updated save logic

3. **`lib/widgets/gemini_chat_widget.dart`**
   - Added `userPreferences` parameter
   - Updated to use user's API key
   - Added helpful message when no key is set

4. **`lib/main.dart`**
   - Pass `_userPreferences` to `GeminiChatWidget`

### Data Flow

```
User enters API key in Settings
         ↓
Settings Dialog saves to UserPreferences
         ↓
UserPreferences saved to Firebase
         ↓
UserPreferences loaded on app start
         ↓
Passed to GeminiChatWidget
         ↓
Used for Gemini API calls
```

## 🧪 Testing

### Test Scenarios

1. **No API Key Set**
   - Open Gemini chat
   - Should see message to add API key in Settings
   - Should not be able to send messages

2. **Add API Key**
   - Open Settings
   - Enter valid API key
   - Save
   - Open Gemini chat
   - Should initialize successfully
   - Should be able to send messages

3. **Invalid API Key**
   - Enter invalid API key in Settings
   - Try to use chat
   - Should show error message from Gemini API

4. **Update API Key**
   - Change API key in Settings
   - Save
   - Gemini chat should use new key

5. **Show/Hide Toggle**
   - Click eye icon in API key field
   - Should toggle between showing and hiding key

## 📊 Firebase Structure

```
users/
  {userId}/
    preferences/
      notificationsEnabled: true
      notificationMinutesBefore: 5
      geminiApiKey: "AIzaSy..." (user's key)
```

## 🔐 Security Considerations

### Current Implementation
- API keys stored in Firestore (encrypted in transit)
- Firestore security rules should restrict access to user's own data
- API keys are obscured in UI by default

### Recommended Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can only read/write their own data
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Future Enhancements
- Encrypt API keys before storing (using Firebase Functions)
- Add API key validation before saving
- Implement key rotation reminders
- Add usage tracking/quota warnings

## 💡 Benefits

### For Users
- ✅ Control over their own API usage
- ✅ No shared quota limits
- ✅ Can use free tier without restrictions
- ✅ Easy to set up and manage

### For Developers
- ✅ No API keys in source code
- ✅ Safe to open source the project
- ✅ No quota management needed
- ✅ Users responsible for their own costs

### For Security
- ✅ No exposed API keys in repository
- ✅ Each user's key is isolated
- ✅ Compromised key only affects one user
- ✅ Easy for users to rotate keys

## 📝 User Documentation

### In-App Instructions

The Settings dialog includes:
- Clear label: "Gemini API Key"
- Helper text: "Required for AI chat feature"
- Link to get API key: "makersuite.google.com/app/apikey"
- Security note: "Your API key is stored securely with your account"

### Chat Widget Message

When no API key is set:
```
Please add your Gemini API key in Settings to use AI chat.

Get your free API key from:
makersuite.google.com/app/apikey

Then go to Settings (gear icon) and enter your API key.
```

## 🚀 Deployment Notes

### Migration
- Existing users will need to add their API key
- No automatic migration needed
- Old hardcoded key removed from code

### Rollout
1. Deploy updated code
2. Notify users about new feature
3. Provide instructions to get API key
4. Monitor for any issues

## ✅ Checklist

- [x] Updated UserPreferences model
- [x] Added API key field to Settings dialog
- [x] Updated GeminiChatWidget to use user's key
- [x] Removed hardcoded API key
- [x] Added show/hide toggle for security
- [x] Added helpful instructions
- [x] Updated .gitignore (already done)
- [x] Created documentation

## 🎉 Summary

Users can now securely manage their own Gemini API keys through the Settings dialog. This provides better security, eliminates shared quota issues, and makes the codebase safe to share publicly.

**No more hardcoded API keys!** 🔒
