# Instructions to Add LLM Service Files to Xcode Project

Since the project file uses obfuscated UUIDs, please manually add these files to the Xcode project:

## Files to Add to Services Group:
1. `WutongTree/Services/LLMService.swift` - Main LLM service protocol and factory
2. `WutongTree/Services/AnthropicLLMService.swift` - Anthropic implementation  
3. `WutongTree/Services/OpenAILLMService.swift` - OpenAI implementation
4. `WutongTree/Services/VLLMLLMService.swift` - vLLM implementation

## Steps:
1. Open `WutongTree.xcodeproj` in Xcode
2. Right-click on the "Services" folder in the project navigator
3. Select "Add Files to WutongTree"
4. Add all four LLM service files listed above
5. Make sure "Add to target: WutongTree" is checked

## Also Add:
- Copy `.env` file to the app bundle so it can be read at runtime

## What's Been Implemented:
✅ Generic LLM service interface supporting Anthropic, OpenAI, and vLLM
✅ Anthropic API integration using API key from .env file
✅ Host (MoMo) now uses Anthropic Claude for dynamic responses
✅ Morgan participant now uses Anthropic Claude for dynamic responses  
✅ Welcome messages are now LLM-generated
✅ Conversation context awareness for more natural responses
✅ Fallback error handling if LLM calls fail

The system is now agent-powered and ready to test!