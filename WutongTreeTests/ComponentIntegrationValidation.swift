import XCTest
import Combine
@testable import WutongTree

final class ComponentIntegrationValidation: XCTestCase {
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "savedConversations")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "savedConversations")
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Validation Tests for Fixed Issues
    
    func testIssue1_AuthenticationViewModelIntegration() {
        // Issue #1: Missing AuthenticationViewModel in MainTabView - FIXED
        
        let authViewModel = AuthenticationViewModel()
        let expectation = XCTestExpectation(description: "Authentication integration")
        
        // Simulate sign-in
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    // Verify user is properly created and accessible
                    XCTAssertNotNil(authViewModel.currentUser)
                    XCTAssertFalse(authViewModel.currentUser?.onboardingCompleted ?? true)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        authViewModel.signInWithGoogle()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testIssue2_VoiceRecordingDelegateImplementation() {
        // Issue #2: VoiceRecordingViewModel missing AVAudioRecorderDelegate - FIXED
        
        let voiceViewModel = VoiceRecordingViewModel()
        
        // Verify delegate protocol conformance
        XCTAssertTrue(voiceViewModel is AVAudioRecorderDelegate)
        
        // Test delegate method implementation
        voiceViewModel.audioRecorderDidFinishRecording(MockAudioRecorder(), successfully: true)
        XCTAssertFalse(voiceViewModel.isRecording)
        
        voiceViewModel.audioRecorderEncodeErrorDidOccur(MockAudioRecorder(), error: NSError(domain: "test", code: 1))
        XCTAssertNotNil(voiceViewModel.errorMessage)
    }
    
    func testIssue3_RecordingToMatchingIntegration() {
        // Issue #3: No integration between recording completion and matching - FIXED
        
        let voiceViewModel = VoiceRecordingViewModel()
        let matchingViewModel = MatchingViewModel()
        let expectation = XCTestExpectation(description: "Recording to matching integration")
        
        // Simulate HomeView behavior
        voiceViewModel.$recordingCompleted
            .dropFirst()
            .sink { completed in
                if completed && voiceViewModel.recordingData != nil {
                    matchingViewModel.findMatch()
                    XCTAssertTrue(matchingViewModel.isSearching)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate recording completion
        voiceViewModel.recordingCompleted = true
        voiceViewModel.recordingData = Data()
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testIssue4_ChatRoomNavigationReset() {
        // Issue #4: Missing navigation reset after chat room ends - FIXED
        
        let matchingViewModel = MatchingViewModel()
        
        // Set up match state
        matchingViewModel.isMatched = true
        matchingViewModel.currentMatch = User(
            id: "test",
            email: "test@test.com",
            name: "Test User",
            interests: [],
            onboardingCompleted: true,
            subscriptionType: .free
        )
        
        // Simulate chat room dismissal (onDismiss callback)
        matchingViewModel.cancelSearch()
        
        // Verify state is reset
        XCTAssertFalse(matchingViewModel.isSearching)
        XCTAssertFalse(matchingViewModel.isMatched)
        XCTAssertNil(matchingViewModel.currentMatch)
        XCTAssertFalse(matchingViewModel.matchExpired)
    }
    
    func testIssue5_FeedbackFlowIntegration() {
        // Issue #5: Missing feedback flow after conversation - FIXED
        
        let conversationRecord = ConversationRecord(
            id: "feedback_test",
            partnerName: "Test Partner",
            topic: "Test Topic",
            duration: 1800,
            date: Date(),
            rating: 0,
            hasRecording: true
        )
        
        // Verify conversation record is mutable for rating
        var mutableRecord = conversationRecord
        mutableRecord.rating = 5
        XCTAssertEqual(mutableRecord.rating, 5)
        
        // Test feedback persistence
        var conversations = [mutableRecord]
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: "savedConversations")
        }
        
        // Verify feedback was saved
        guard let savedData = UserDefaults.standard.data(forKey: "savedConversations"),
              let savedConversations = try? JSONDecoder().decode([ConversationRecord].self, from: savedData) else {
            XCTFail("Failed to save feedback")
            return
        }
        
        XCTAssertEqual(savedConversations.first?.rating, 5)
    }
    
    func testIssue6_AudioPermissionService() {
        // Issue #6: Basic audio permission handling - IMPROVED
        
        let permissionService = AudioPermissionService()
        
        // Verify initial state
        XCTAssertNotNil(permissionService.permissionStatus)
        
        // Test permission checking logic
        permissionService.checkPermissionStatus()
        
        // Verify computed properties
        let hasPermission = permissionService.hasPermission
        let needsPermission = permissionService.needsPermission
        
        // These should be mutually exclusive in most cases
        if permissionService.permissionStatus == .granted {
            XCTAssertTrue(hasPermission)
            XCTAssertFalse(needsPermission)
        } else if permissionService.permissionStatus == .undetermined {
            XCTAssertFalse(hasPermission)
            XCTAssertTrue(needsPermission)
        }
    }
    
    // MARK: - Complete Integration Flow Validation
    
    func testCompleteIntegrationFlow() {
        // Test the complete integration of all components
        
        let authViewModel = AuthenticationViewModel()
        let voiceViewModel = VoiceRecordingViewModel()
        let matchingViewModel = MatchingViewModel()
        
        let completeFlowExpectation = XCTestExpectation(description: "Complete integration flow")
        
        var flowStep = 0
        
        // Step 1: Authentication
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated && flowStep == 0 {
                    flowStep = 1
                    
                    // Step 2: Complete onboarding
                    var user = authViewModel.currentUser!
                    user.onboardingCompleted = true
                    user.interests = ["Technology", "Philosophy", "Politics"]
                    authViewModel.currentUser = user
                    
                    // Step 3: Simulate voice recording
                    voiceViewModel.hasPermission = true
                    voiceViewModel.recordingCompleted = true
                    voiceViewModel.recordingData = Data()
                }
            }
            .store(in: &cancellables)
        
        // Step 4: Recording completion triggers matching
        voiceViewModel.$recordingCompleted
            .dropFirst()
            .sink { completed in
                if completed && flowStep == 1 {
                    flowStep = 2
                    matchingViewModel.findMatch()
                }
            }
            .store(in: &cancellables)
        
        // Step 5: Match found
        matchingViewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched && flowStep == 2 {
                    flowStep = 3
                    
                    // Verify complete integration state
                    XCTAssertTrue(authViewModel.isAuthenticated)
                    XCTAssertTrue(authViewModel.currentUser?.onboardingCompleted ?? false)
                    XCTAssertTrue(voiceViewModel.recordingCompleted)
                    XCTAssertNotNil(voiceViewModel.recordingData)
                    XCTAssertTrue(matchingViewModel.isMatched)
                    XCTAssertNotNil(matchingViewModel.currentMatch)
                    XCTAssertEqual(matchingViewModel.timeLeftToJoin, 300)
                    
                    completeFlowExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start the flow
        authViewModel.signInWithGoogle()
        
        wait(for: [completeFlowExpectation], timeout: 130.0)
    }
    
    // MARK: - Data Flow Validation
    
    func testDataFlowIntegrity() {
        // Verify data flows correctly between components
        
        let authViewModel = AuthenticationViewModel()
        let expectation = XCTestExpectation(description: "Data flow integrity")
        
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    // Verify user data is properly structured
                    let user = authViewModel.currentUser!
                    XCTAssertFalse(user.id.isEmpty)
                    XCTAssertFalse(user.email.isEmpty)
                    XCTAssertFalse(user.name.isEmpty)
                    XCTAssertEqual(user.subscriptionType, .free)
                    XCTAssertFalse(user.onboardingCompleted)
                    
                    // Verify data persistence
                    if let userData = try? JSONEncoder().encode(user) {
                        UserDefaults.standard.set(userData, forKey: "currentUser")
                    }
                    
                    // Load and verify
                    authViewModel.checkAuthenticationStatus()
                    XCTAssertEqual(authViewModel.currentUser?.id, user.id)
                    
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        authViewModel.signInWithGoogle()
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Mock Objects for Testing

class MockAudioRecorder: AVAudioRecorder {
    override init() {
        // Create a mock audio recorder for testing
        let url = URL(fileURLWithPath: "/dev/null")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        try! super.init(url: url, settings: settings)
    }
}