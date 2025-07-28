# Files to Add to Xcode Project

You need to add these new files to the Xcode project:

## In Services group:
- `TextToSpeechService.swift` - Text-to-speech functionality

## In ViewModels group:
- `OnboardingInterviewViewModel.swift` - AI interview logic

## In Views group:
- `AIOnboardingView.swift` - AI-hosted onboarding UI

## Steps:
1. Open Xcode
2. Right-click on each group (Services, ViewModels, Views)
3. Select "Add Files to 'WutongTree'"
4. Add the corresponding files
5. Make sure "Add to target: WutongTree" is checked

## Test the fixes:
After adding the files and rebuilding:
1. **AI Onboarding**: Should now ask multiple questions (with debug logs in console)
2. **Audio**: Should hear TTS speech when agents talk in chat room

The debug logs will help identify what's happening with the onboarding flow.