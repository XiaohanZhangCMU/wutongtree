import XCTest
import Combine
@testable import WutongTree

final class IntegrationTests: XCTestCase {
    var authViewModel: AuthenticationViewModel!
    var voiceViewModel: VoiceRecordingViewModel!
    var matchingViewModel: MatchingViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        authViewModel = AuthenticationViewModel()
        voiceViewModel = VoiceRecordingViewModel()
        matchingViewModel = MatchingViewModel()
        cancellables = Set<AnyCancellable>()
        
        // Clear existing data
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "savedConversations")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "savedConversations")
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Authentication + Onboarding Integration
    
    func testCompleteAuthenticationToOnboardingFlow() {
        let expectation = XCTestExpectation(description: "Complete auth to onboarding flow")
        
        // Step 1: User signs in
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    // Step 2: Verify user is created but onboarding incomplete
                    XCTAssertNotNil(self.authViewModel.currentUser)
                    XCTAssertFalse(self.authViewModel.currentUser?.onboardingCompleted ?? true)
                    
                    // Step 3: Complete onboarding
                    var user = self.authViewModel.currentUser!
                    user.name = "Tommy"
                    user.age = 20
                    user.interests = ["Politics", "Philosophy", "Technology"]
                    user.lookingFor = "Deep philosophical discussions"
                    user.onboardingCompleted = true
                    
                    // Step 4: Save updated user
                    self.authViewModel.currentUser = user
                    if let userData = try? JSONEncoder().encode(user) {
                        UserDefaults.standard.set(userData, forKey: "currentUser")
                    }
                    
                    // Step 5: Verify persistence
                    self.authViewModel.checkAuthenticationStatus()
                    XCTAssertTrue(self.authViewModel.currentUser?.onboardingCompleted ?? false)
                    
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        authViewModel.signInWithGoogle()
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Voice Recording + Matching Integration
    
    func testVoiceRecordingToMatchingFlow() {
        // Setup authenticated user with completed onboarding
        let user = User(
            id: "test_user",
            email: "test@test.com",
            name: "Test User",
            age: 25,
            interests: ["Technology", "Philosophy", "Politics"],
            lookingFor: "Deep conversations",
            onboardingCompleted: true,
            subscriptionType: .free
        )
        authViewModel.currentUser = user
        
        let recordingExpectation = XCTestExpectation(description: "Recording completes")
        let matchingExpectation = XCTestExpectation(description: "Matching starts")
        
        // Simulate recording flow
        voiceViewModel.hasPermission = true
        voiceViewModel.startRecording()
        
        // Verify recording started
        XCTAssertTrue(voiceViewModel.isRecording)
        
        // Simulate recording completion after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.voiceViewModel.stopRecording()
            recordingExpectation.fulfill()
            
            // Now start matching based on recording
            self.matchingViewModel.findMatch()
            matchingExpectation.fulfill()
        }
        
        wait(for: [recordingExpectation, matchingExpectation], timeout: 5.0)
        
        XCTAssertFalse(voiceViewModel.isRecording)
        XCTAssertTrue(matchingViewModel.isSearching)
    }
    
    // MARK: - Matching + Chat Room Integration
    
    func testMatchingToChatRoomFlow() {
        let matchFoundExpectation = XCTestExpectation(description: "Match found")
        let timerExpectation = XCTestExpectation(description: "Timer starts")
        
        // Start matching
        matchingViewModel.findMatch()
        
        // Wait for match
        matchingViewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched {
                    matchFoundExpectation.fulfill()
                    
                    // Verify 5-minute timer started
                    XCTAssertEqual(self.matchingViewModel.timeLeftToJoin, 300)
                    XCTAssertFalse(self.matchingViewModel.matchExpired)
                    XCTAssertNotNil(self.matchingViewModel.currentMatch)
                    
                    // Simulate timer countdown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        XCTAssertLessThan(self.matchingViewModel.timeLeftToJoin, 300)
                        timerExpectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)
        
        wait(for: [matchFoundExpectation, timerExpectation], timeout: 125.0)
    }
    
    // MARK: - Chat Room + Recording Integration
    
    func testChatRoomWithRecordingFlow() {
        // Setup chat room
        let user1 = User(id: "user1", email: "user1@test.com", name: "User 1", interests: [], onboardingCompleted: true, subscriptionType: .free)
        let user2 = User(id: "user2", email: "user2@test.com", name: "User 2", interests: [], onboardingCompleted: true, subscriptionType: .premium)
        
        let chatRoom = ChatRoom(
            id: "test_room",
            participants: [user1, user2],
            aiHost: AIHost(personality: .friendly),
            isActive: true,
            startTime: Date(),
            recordingEnabled: false
        )
        
        let chatRoomViewModel = ChatRoomViewModel()
        chatRoomViewModel.setup(chatRoom: chatRoom)
        
        // Verify initial state
        XCTAssertFalse(chatRoomViewModel.isRecording)
        XCTAssertGreaterThan(chatRoomViewModel.messages.count, 0) // Should have welcome message
        
        // Start recording
        chatRoomViewModel.toggleRecording()
        XCTAssertTrue(chatRoomViewModel.isRecording)
        
        // Wait for recording duration to increment
        let recordingExpectation = XCTestExpectation(description: "Recording duration increments")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertGreaterThan(chatRoomViewModel.recordingDuration, 0)
            recordingExpectation.fulfill()
        }
        
        wait(for: [recordingExpectation], timeout: 3.0)
        
        // Stop recording
        chatRoomViewModel.toggleRecording()
        XCTAssertFalse(chatRoomViewModel.isRecording)
        
        // Verify recording message was added
        let recordingMessages = chatRoomViewModel.messages.filter { $0.messageType == .system && $0.content.contains("Recording") }
        XCTAssertGreaterThan(recordingMessages.count, 0)
    }
    
    // MARK: - Conversation + Storage Integration
    
    func testConversationToStorageFlow() {
        // Setup and complete a conversation
        let conversationRecord = ConversationRecord(
            id: "storage_test",
            partnerName: "Storage Partner",
            topic: "Storage Topic",
            duration: 1800,
            date: Date(),
            rating: 5,
            hasRecording: true
        )
        
        // Save conversation
        var conversations = [conversationRecord]
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: "savedConversations")
        }
        
        // Verify storage worked
        guard let savedData = UserDefaults.standard.data(forKey: "savedConversations"),
              let savedConversations = try? JSONDecoder().decode([ConversationRecord].self, from: savedData) else {
            XCTFail("Failed to save/load conversations")
            return
        }
        
        XCTAssertEqual(savedConversations.count, 1)
        XCTAssertEqual(savedConversations.first?.id, "storage_test")
        
        // Test adding multiple conversations
        let secondConversation = ConversationRecord(
            id: "storage_test_2",
            partnerName: "Storage Partner 2",
            topic: "Storage Topic 2",
            duration: 1200,
            date: Date().addingTimeInterval(-3600),
            rating: 4,
            hasRecording: false
        )
        
        conversations.append(secondConversation)
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: "savedConversations")
        }
        
        // Verify multiple conversations
        guard let updatedData = UserDefaults.standard.data(forKey: "savedConversations"),
              let updatedConversations = try? JSONDecoder().decode([ConversationRecord].self, from: updatedData) else {
            XCTFail("Failed to save/load multiple conversations")
            return
        }
        
        XCTAssertEqual(updatedConversations.count, 2)
    }
    
    // MARK: - Subscription + User Persistence Integration
    
    func testSubscriptionPersistenceFlow() {
        // Create user with free subscription
        var user = User(
            id: "subscription_test",
            email: "sub@test.com",
            name: "Sub User",
            interests: ["Technology"],
            onboardingCompleted: true,
            subscriptionType: .free
        )
        
        // Save user
        authViewModel.currentUser = user
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        // Verify free subscription persisted
        authViewModel.checkAuthenticationStatus()
        XCTAssertEqual(authViewModel.currentUser?.subscriptionType, .free)
        
        // Upgrade to premium
        user.subscriptionType = .premium
        authViewModel.currentUser = user
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        // Verify premium subscription persisted
        authViewModel.checkAuthenticationStatus()
        XCTAssertEqual(authViewModel.currentUser?.subscriptionType, .premium)
        
        // Verify subscription display
        XCTAssertEqual(user.subscriptionType.displayName, "Premium ($10/month)")
    }
    
    // MARK: - Full End-to-End Integration Test
    
    func testCompleteUserJourneyIntegration() {
        let journeyExpectation = XCTestExpectation(description: "Complete user journey")
        
        // Step 1: Authentication
        authViewModel.$isAuthenticated
            .dropFirst()
            .sink { [weak self] isAuthenticated in
                guard let self = self, isAuthenticated else { return }
                
                // Step 2: Complete onboarding
                var user = self.authViewModel.currentUser!
                user.name = "Tommy"
                user.age = 20
                user.interests = ["Politics", "Philosophy", "Technology"]
                user.lookingFor = "Deep philosophical discussions"
                user.onboardingCompleted = true
                
                self.authViewModel.currentUser = user
                if let userData = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(userData, forKey: "currentUser")
                }
                
                // Step 3: Voice recording
                self.voiceViewModel.hasPermission = true
                self.voiceViewModel.startRecording()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.voiceViewModel.stopRecording()
                    
                    // Step 4: Start matching
                    self.matchingViewModel.findMatch()
                    
                    // Step 5: Wait for match and verify complete flow
                    self.matchingViewModel.$isMatched
                        .dropFirst()
                        .sink { isMatched in
                            if isMatched {
                                // Verify all components are in correct state
                                XCTAssertTrue(self.authViewModel.isAuthenticated)
                                XCTAssertTrue(self.authViewModel.currentUser?.onboardingCompleted ?? false)
                                XCTAssertFalse(self.voiceViewModel.isRecording)
                                XCTAssertTrue(self.matchingViewModel.isMatched)
                                XCTAssertNotNil(self.matchingViewModel.currentMatch)
                                XCTAssertEqual(self.matchingViewModel.timeLeftToJoin, 300)
                                
                                journeyExpectation.fulfill()
                            }
                        }
                        .store(in: &self.cancellables)
                }
            }
            .store(in: &cancellables)
        
        authViewModel.signInWithGoogle()
        wait(for: [journeyExpectation], timeout: 130.0)
    }
}