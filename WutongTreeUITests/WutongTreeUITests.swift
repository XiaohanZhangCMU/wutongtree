import XCTest

final class WutongTreeUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Test Tommy's Complete User Journey (from implementation.md)
    
    func testCompleteUserJourney() throws {
        // Step 3: Tommy signs up with Gmail/Facebook/Apple account
        testUserSignUp()
        
        // Step 4: Tommy logs into WutongTree
        // (Automatically handled after sign up)
        
        // Step 6.2: Tommy MUST finish answering all questions before matching
        testOnboardingCompletion()
        
        // Step 7: Tommy clicks microphone button to start talking
        testMicrophoneInteraction()
        
        // Step 8-9: WutongTree asks questions and does personality analysis
        testPersonalityAnalysis()
        
        // Step 10: Tommy is matched with another user
        testUserMatching()
        
        // Step 11: Tommy enters chat room with 5-minute limit
        testChatRoomEntry()
        
        // Step 12-14: Three-way conversation with MoMo AI host
        testConversationFlow()
        
        // Step 15: Conversation recording functionality
        testConversationRecording()
        
        // Step 17: Post-conversation feedback
        testFeedbackSystem()
    }
    
    // MARK: - Individual Test Components
    
    func testUserSignUp() {
        // Verify welcome screen appears first
        let welcomeTitle = app.staticTexts["WutongTree"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5))
        
        let descriptionText = app.staticTexts["AI hosting chat room for humans to share ideas, thoughts and life"]
        XCTAssertTrue(descriptionText.exists)
        
        // Test Google sign-in (mock implementation)
        let googleSignInButton = app.buttons["Continue with Google"]
        XCTAssertTrue(googleSignInButton.exists)
        googleSignInButton.tap()
        
        // Verify authentication loading state
        let loadingIndicator = app.activityIndicators.firstMatch
        XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 2))
        
        // Wait for sign-in to complete
        let homeView = app.tabBars.firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 10))
    }
    
    func testOnboardingCompletion() {
        // Should show onboarding prompt for new users
        let onboardingPrompt = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(onboardingPrompt.waitForExistence(timeout: 5))
        
        let startOnboardingButton = app.buttons["Start Onboarding"]
        XCTAssertTrue(startOnboardingButton.exists)
        startOnboardingButton.tap()
        
        // Step 1: Profile Photo
        let addPhotoText = app.staticTexts["Add Your Photo"]
        XCTAssertTrue(addPhotoText.waitForExistence(timeout: 3))
        
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.exists)
        nextButton.tap()
        
        // Step 2: Basic Information
        let nameField = app.textFields["Your name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Tommy")
        
        let ageField = app.textFields["Your age"]
        ageField.tap()
        ageField.typeText("20")
        
        nextButton.tap()
        
        // Step 3: Interests (minimum 3 required)
        let interestsTitle = app.staticTexts["What Are Your Interests?"]
        XCTAssertTrue(interestsTitle.waitForExistence(timeout: 3))
        
        // Select required interests
        app.buttons["Politics"].tap()
        app.buttons["Philosophy"].tap()
        app.buttons["Technology"].tap()
        
        // Verify Next button is enabled after selecting 3 interests
        XCTAssertTrue(nextButton.isEnabled)
        nextButton.tap()
        
        // Step 4: Looking For
        let lookingForTitle = app.staticTexts["What Are You Looking For?"]
        XCTAssertTrue(lookingForTitle.waitForExistence(timeout: 3))
        
        app.buttons["Deep philosophical discussions"].tap()
        nextButton.tap()
        
        // Step 5: Voice Setup Complete
        let completeButton = app.buttons["Complete"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 3))
        completeButton.tap()
        
        // Verify onboarding is complete and user returns to home
        let microphoneButton = app.buttons.matching(identifier: "microphone_button").firstMatch
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5))
    }
    
    func testMicrophoneButtonRequiresOnboarding() {
        // New users should NOT be able to use microphone without completing onboarding
        
        // Skip onboarding and try to access microphone
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Should show onboarding requirement, not microphone
        let onboardingPrompt = app.staticTexts["Complete Your Profile"]
        XCTAssertTrue(onboardingPrompt.exists, "Users MUST complete onboarding before accessing microphone")
        
        // Microphone should NOT be accessible
        let microphoneButton = app.buttons.matching(identifier: "microphone_button").firstMatch
        XCTAssertFalse(microphoneButton.exists, "Microphone should not be available without onboarding")
    }
    
    func testMicrophoneInteraction() {
        // Complete onboarding first
        completeOnboardingQuickly()
        
        // Step 7: Tommy clicks on microphone button
        let microphoneButton = app.buttons.matching(identifier: "microphone_button").firstMatch
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5))
        
        let readyText = app.staticTexts["Ready to start a conversation?"]
        XCTAssertTrue(readyText.exists)
        
        // Tap microphone to start recording
        microphoneButton.tap()
        
        // Verify recording state
        let recordingInstructions = app.staticTexts["Tell me what you'd like to talk about today..."]
        XCTAssertTrue(recordingInstructions.waitForExistence(timeout: 2))
        
        let stopText = app.staticTexts["Tap to stop recording"]
        XCTAssertTrue(stopText.exists)
        
        // Stop recording after a moment
        sleep(2)
        microphoneButton.tap()
        
        // Should start matching process
        let matchingText = app.staticTexts["Finding your perfect match..."]
        XCTAssertTrue(matchingText.waitForExistence(timeout: 3))
    }
    
    func testPersonalityAnalysis() {
        // This happens automatically after recording
        // Verify the app shows matching/analysis progress
        
        let progressIndicator = app.activityIndicators.firstMatch
        XCTAssertTrue(progressIndicator.exists, "Should show progress during personality analysis")
        
        let matchingText = app.staticTexts["Finding your perfect match..."]
        XCTAssertTrue(matchingText.exists, "Should indicate matching in progress")
    }
    
    func testUserMatching() {
        // Wait for match to be found (up to 2 minutes per spec)
        let matchFoundText = app.staticTexts["Match Found! 🎉"]
        XCTAssertTrue(matchFoundText.waitForExistence(timeout: 125), "Match should be found within 2 minutes")
        
        // Verify 5-minute timer message
        let timerText = app.staticTexts["You have 5 minutes to join"]
        XCTAssertTrue(timerText.exists, "Must show 5-minute join timer per spec")
        
        // Verify chat room button is available
        let enterChatButton = app.buttons["Enter Chat Room"]
        XCTAssertTrue(enterChatButton.exists)
    }
    
    func testChatRoomEntry() {
        // Enter the chat room within 5-minute window
        let enterChatButton = app.buttons["Enter Chat Room"]
        enterChatButton.tap()
        
        // Verify chat room interface
        let chatTitle = app.navigationBars["WutongTree Chat"]
        XCTAssertTrue(chatTitle.waitForExistence(timeout: 5))
        
        // Should show 3 participants: Tommy, match, and MoMo
        let participantViews = app.scrollViews.firstMatch.otherElements
        XCTAssertGreaterThanOrEqual(participantViews.count, 3, "Should show 3 participants")
        
        // Verify MoMo AI host is present
        let momoName = app.staticTexts["MoMo"]
        XCTAssertTrue(momoName.exists, "MoMo AI host should be present")
        
        // Verify audio controls
        let muteButton = app.buttons.matching(identifier: "mute_button").firstMatch
        let speakerButton = app.buttons.matching(identifier: "speaker_button").firstMatch
        XCTAssertTrue(muteButton.exists)
        XCTAssertTrue(speakerButton.exists)
    }
    
    func testConversationFlow() {
        // Verify MoMo's welcome message appears
        let welcomeMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Welcome to WutongTree'"))
        XCTAssertTrue(welcomeMessage.firstMatch.waitForExistence(timeout: 10), "MoMo should send welcome message")
        
        // Test mute functionality
        let muteButton = app.buttons.matching(identifier: "mute_button").firstMatch
        muteButton.tap()
        
        let muteConfirmation = app.staticTexts["You are now muted"]
        XCTAssertTrue(muteConfirmation.waitForExistence(timeout: 3))
        
        // Unmute
        muteButton.tap()
        let unmuteConfirmation = app.staticTexts["You are now unmuted"]
        XCTAssertTrue(unmuteConfirmation.waitForExistence(timeout: 3))
        
        // Test speaker toggle
        let speakerButton = app.buttons.matching(identifier: "speaker_button").firstMatch
        speakerButton.tap()
        
        // Verify conversation can be ended
        let leaveButton = app.buttons["Leave"]
        XCTAssertTrue(leaveButton.exists, "Users should be able to leave conversation anytime")
    }
    
    func testConversationRecording() {
        // Test recording functionality (Step 13 from spec)
        let recordingButton = app.buttons["Start Recording"]
        XCTAssertTrue(recordingButton.exists, "Recording should be available")
        
        recordingButton.tap()
        
        // Verify recording state
        let recordingIndicator = app.staticTexts["Recording in progress"]
        XCTAssertTrue(recordingIndicator.waitForExistence(timeout: 3))
        
        let stopRecordingButton = app.buttons["Stop Recording"]
        XCTAssertTrue(stopRecordingButton.exists)
        
        // Stop recording
        stopRecordingButton.tap()
        
        let recordingSaved = app.staticTexts["⏹️ Recording stopped and saved"]
        XCTAssertTrue(recordingSaved.waitForExistence(timeout: 3))
    }
    
    func testFeedbackSystem() {
        // End conversation to trigger feedback
        let leaveButton = app.buttons["Leave"]
        leaveButton.tap()
        
        let endConfirmation = app.alerts["End Conversation?"]
        XCTAssertTrue(endConfirmation.waitForExistence(timeout: 3))
        
        let endButton = endConfirmation.buttons["End"]
        endButton.tap()
        
        // Should return to home and potentially show feedback prompt
        let homeView = app.tabBars.firstMatch
        XCTAssertTrue(homeView.waitForExistence(timeout: 5))
    }
    
    func testSubscriptionFlow() {
        // Test 7-day free trial and $10/month premium (Step 16)
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        
        let upgradeButton = app.buttons["Upgrade to Premium"]
        XCTAssertTrue(upgradeButton.exists)
        upgradeButton.tap()
        
        // Verify subscription options
        let monthlyPlan = app.staticTexts["$10.99/month"]
        let annualPlan = app.staticTexts["$99.99/year"]
        let freeTrialText = app.staticTexts["7-day free trial • Cancel anytime"]
        
        XCTAssertTrue(monthlyPlan.waitForExistence(timeout: 3))
        XCTAssertTrue(annualPlan.exists)
        XCTAssertTrue(freeTrialText.exists)
    }
    
    // MARK: - Helper Methods
    
    private func completeOnboardingQuickly() {
        let startOnboardingButton = app.buttons["Start Onboarding"]
        if startOnboardingButton.exists {
            startOnboardingButton.tap()
            
            // Quick onboarding completion
            app.buttons["Next"].tap() // Photo step
            
            app.textFields["Your name"].tap()
            app.textFields["Your name"].typeText("TestUser")
            app.textFields["Your age"].tap()
            app.textFields["Your age"].typeText("25")
            app.buttons["Next"].tap()
            
            app.buttons["Politics"].tap()
            app.buttons["Philosophy"].tap()
            app.buttons["Technology"].tap()
            app.buttons["Next"].tap()
            
            app.buttons["Deep philosophical discussions"].tap()
            app.buttons["Next"].tap()
            
            app.buttons["Complete"].tap()
        }
    }
}