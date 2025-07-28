# Quick Fix for Duplicate File References

## Method 1: Xcode Manual Cleanup (Recommended)
1. Open Xcode
2. In Project Navigator, remove duplicate ViewModel references
3. Keep only the ones in the ViewModels group
4. Build should work

## Method 2: Revert to Working State (Fastest)
If the manual cleanup is taking too long:

1. Change HomeView.swift back to use OnboardingView temporarily:
```swift
// In HomeView.swift line 48, change:
AIOnboardingView(user: Binding(
// Back to:
OnboardingView(user: Binding(
```

2. Comment out TTS in ChatRoomViewModel.swift:
```swift
// Line 30: Comment out
// private var ttsService = TextToSpeechService()

// And comment out TTS method calls
```

This will get the app building and running with LLM-powered conversations.
Then we can add AI onboarding and TTS one at a time.

## Method 3: Clean Project Creation
If both methods fail, we might need to create a fresh Xcode project and import files properly.

The root issue is duplicate file references in the Xcode project file causing build conflicts.