# How to Add LLM Service Files to Xcode Project

## Files to Add (all located in WutongTree/Services/):

1. `LLMService.swift` - Main protocol and factory
2. `AnthropicLLMService.swift` - Anthropic implementation  
3. `OpenAILLMService.swift` - OpenAI implementation
4. `VLLMLLMService.swift` - vLLM implementation

## Steps in Xcode:

### Method 1: Drag and Drop (Recommended)
1. Open Xcode with `WutongTree.xcodeproj`
2. In the Project Navigator (left sidebar), find the "Services" folder
3. Open Finder and navigate to `/Users/xiaohan.zhang/Codes/mosaicml/wutongtree/WutongTree/Services/`
4. Select all 4 LLM service files
5. Drag them into the "Services" folder in Xcode
6. In the dialog that appears:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Add to target: WutongTree"
   - Click "Finish"

### Method 2: Add Files Menu
1. Right-click on the "Services" folder in Xcode
2. Select "Add Files to 'WutongTree'"
3. Navigate to the Services folder
4. Select all 4 LLM service files
5. Make sure "Add to target: WutongTree" is checked
6. Click "Add"

### Method 3: If Services folder doesn't exist
1. Right-click on "WutongTree" folder in project navigator
2. Select "New Group"
3. Name it "Services" 
4. Add the files to this new group

## Verify the Files are Added:
- You should see all 4 files in the Services group
- Each file should have a blue icon (not gray)
- Build the project - the errors should be resolved

## Also Add Test Files:
Add these to the WutongTreeTests group:
- `LLMServiceTests.swift`
- `LLMIntegrationTests.swift`

## Alternative: Command Line Fix
If you prefer, run this script to add files via command line:
```bash
cd /Users/xiaohan.zhang/Codes/mosaicml/wutongtree
# The files are already in the right location, just need to be added to project
```

Once you've added the files to Xcode, the build errors will be resolved!