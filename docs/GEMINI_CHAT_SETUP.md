# Gemini Chat Widget Setup Guide

## Overview
A floating AI chat assistant powered by Google's Gemini AI has been added to the bottom right corner of the app. It provides an expandable/collapsible chat interface.

## Features

### **Visual Design**
- **Collapsed State**: Beautiful gradient circular button (60x60px) with chat icon
- **Expanded State**: Full chat interface (400x500px) with smooth animations
- **Position**: Bottom right corner, aligned with the bottom left task panel
- **Gradient Theme**: Blue to purple gradient matching modern UI trends

### **Functionality**
- ✅ Click to expand/collapse the chat widget
- ✅ Send messages to Gemini AI
- ✅ Receive AI-generated responses
- ✅ Scrollable message history
- ✅ Loading indicator while AI is thinking
- ✅ Beautiful message bubbles (user vs AI)

## Setup Instructions

### **Step 1: Get a Gemini API Key**

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy your API key

### **Step 2: Add Your API Key**

Open `lib/widgets/gemini_chat_widget.dart` and replace the placeholder:

```dart
// Line 26 - Replace this:
const apiKey = 'YOUR_GEMINI_API_KEY_HERE';

// With your actual API key:
const apiKey = 'AIzaSy...your-actual-key-here';
```

**Security Note**: For production apps, store the API key in environment variables or secure storage, not hardcoded in the source code.

### **Step 3: Test the Chat**

1. Run the app: `flutter run`
2. Look for the gradient chat button in the bottom right corner
3. Click it to expand the chat
4. Type a message and press Enter or click Send
5. Watch Gemini respond!

## Usage Examples

Try asking Gemini:
- "Help me organize my tasks for today"
- "What's a good time management technique?"
- "Suggest a morning routine"
- "How can I be more productive?"

## Technical Details

### **Files Modified**
1. `pubspec.yaml` - Added `google_generative_ai: ^0.4.0` dependency
2. `lib/main.dart` - Wrapped body in Stack and added positioned chat widget
3. `lib/widgets/gemini_chat_widget.dart` - New file with chat UI and AI integration

### **Widget Structure**
```
Stack
├── Column (existing app content)
└── Positioned (bottom-right)
    └── GeminiChatWidget
        ├── Collapsed: Gradient button
        └── Expanded: Chat interface
            ├── Header (with close button)
            ├── Message list
            ├── Loading indicator
            └── Input field with send button
```

### **State Management**
- `_isExpanded`: Controls collapsed/expanded state
- `_messages`: List of chat messages
- `_isLoading`: Shows loading indicator
- `_chat`: Gemini chat session

### **Animations**
- Smooth expand/collapse with `AnimatedContainer` (300ms)
- Auto-scroll to bottom when new messages arrive
- Gradient animations on buttons

## Customization

### **Change Position**
Edit `lib/main.dart` line 2175-2177:
```dart
Positioned(
  right: 20,  // Distance from right edge
  bottom: 20, // Distance from bottom edge
  child: const GeminiChatWidget(),
),
```

### **Change Size**
Edit `lib/widgets/gemini_chat_widget.dart` line 105-106:
```dart
width: _isExpanded ? 400 : 60,  // Expanded width : Collapsed width
height: _isExpanded ? 500 : 60, // Expanded height : Collapsed height
```

### **Change Colors**
Edit the gradient colors in `gemini_chat_widget.dart`:
```dart
gradient: LinearGradient(
  colors: [Colors.blue.shade400, Colors.purple.shade400],
  // Change to your preferred colors
),
```

## Troubleshooting

### **"Please add your Gemini API key" message**
- You haven't replaced the placeholder API key yet
- Follow Step 2 above

### **"Error: ..." in chat**
- Check your internet connection
- Verify your API key is correct
- Ensure you haven't exceeded API quota

### **Chat button not visible**
- Check that the app is running
- Look in the bottom right corner
- Try resizing the window if it's too small

## Future Enhancements

Potential improvements:
- [ ] Persist chat history to Firebase
- [ ] Add voice input/output
- [ ] Task-specific AI suggestions
- [ ] Integration with task creation (AI suggests tasks)
- [ ] Customizable themes
- [ ] Minimize to notification badge

## API Costs

Gemini API pricing (as of 2024):
- **Free tier**: 60 requests per minute
- **Paid tier**: Check [Google AI pricing](https://ai.google.dev/pricing)

For personal use, the free tier is usually sufficient.
