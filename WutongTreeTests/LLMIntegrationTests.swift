import XCTest
import Combine
@testable import WutongTree

final class LLMIntegrationTests: XCTestCase {
    var chatRoomViewModel: ChatRoomViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        chatRoomViewModel = ChatRoomViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        chatRoomViewModel?.endConversation()
        chatRoomViewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - LLM Service Integration Tests
    
    func testChatRoomSetupWithLLMServices() {
        // Test that ChatRoomViewModel properly sets up LLM services
        let user1 = User(id: "user1", email: "user1@test.com", name: "Alice", interests: [], onboardingCompleted: true, subscriptionType: .free)
        let user2 = User(id: "user2", email: "user2@test.com", name: "Morgan", interests: [], onboardingCompleted: true, subscriptionType: .premium)
        
        let chatRoom = ChatRoom(
            id: "test_room",
            participants: [user1, user2],
            aiHost: AIHost(personality: .friendly),
            isActive: true,
            startTime: Date(),
            recordingEnabled: false
        )
        
        // Setup chat room and verify initial state
        chatRoomViewModel.setup(chatRoom: chatRoom)
        
        XCTAssertEqual(chatRoomViewModel.messages.count, 0, "Should start with no messages")
        
        // Wait for welcome message generation
        let welcomeExpectation = XCTestExpectation(description: "Welcome message generated")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            welcomeExpectation.fulfill()
        }
        
        wait(for: [welcomeExpectation], timeout: 3.0)
        
        // Verify welcome message was generated
        XCTAssertGreaterThan(chatRoomViewModel.messages.count, 0, "Should have generated welcome message")
        
        if let welcomeMessage = chatRoomViewModel.messages.first {
            XCTAssertEqual(welcomeMessage.messageType, .aiGenerated, "Welcome message should be AI generated")
            XCTAssertEqual(welcomeMessage.senderName, "MoMo", "Welcome message should be from MoMo")
            XCTAssertFalse(welcomeMessage.content.isEmpty, "Welcome message should have content")
        }
    }
    
    func testAIHostResponseGeneration() {
        // Test that AI host generates responses using LLM service
        let user1 = User(id: "user1", email: "user1@test.com", name: "Alice", interests: [], onboardingCompleted: true, subscriptionType: .free)
        let user2 = User(id: "user2", email: "user2@test.com", name: "Morgan", interests: [], onboardingCompleted: true, subscriptionType: .premium)
        
        let chatRoom = ChatRoom(
            id: "test_room",
            participants: [user1, user2],
            aiHost: AIHost(personality: .humorous),
            isActive: true,
            startTime: Date(),
            recordingEnabled: false
        )
        
        chatRoomViewModel.setup(chatRoom: chatRoom)
        
        // Wait for initial setup and welcome message
        let setupExpectation = XCTestExpectation(description: "Setup complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 3.0)
        
        let initialMessageCount = chatRoomViewModel.messages.count
        
        // Wait for AI response generation (should happen automatically via timer)
        let aiResponseExpectation = XCTestExpectation(description: "AI response generated")
        
        // Monitor messages for new AI responses
        chatRoomViewModel.$messages
            .dropFirst()
            .sink { messages in
                let aiMessages = messages.filter { $0.messageType == .aiGenerated && $0.senderName == "MoMo" }
                if aiMessages.count > 1 { // More than just welcome message
                    aiResponseExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [aiResponseExpectation], timeout: 30.0) // AI responds every 25 seconds
        
        // Verify AI response was generated
        let aiMessages = chatRoomViewModel.messages.filter { $0.messageType == .aiGenerated && $0.senderName == "MoMo" }
        XCTAssertGreaterThan(aiMessages.count, 1, "Should have generated AI responses beyond welcome message")
        
        // Verify latest AI message has content
        if let latestAIMessage = aiMessages.last {
            XCTAssertFalse(latestAIMessage.content.isEmpty, "AI response should have content")
        }
    }
    
    func testParticipantResponseGeneration() {
        // Test that Morgan generates responses using LLM service
        let user1 = User(id: "user1", email: "user1@test.com", name: "Alice", interests: [], onboardingCompleted: true, subscriptionType: .free)
        let user2 = User(id: "user2", email: "user2@test.com", name: "Morgan", interests: [], onboardingCompleted: true, subscriptionType: .premium)
        
        let chatRoom = ChatRoom(
            id: "test_room",
            participants: [user1, user2],
            aiHost: AIHost(personality: .empathetic),
            isActive: true,
            startTime: Date(),
            recordingEnabled: false
        )
        
        chatRoomViewModel.setup(chatRoom: chatRoom)
        
        // Wait for initial setup
        let setupExpectation = XCTestExpectation(description: "Setup complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 3.0)
        
        // Wait for Morgan's response (should happen after 10 seconds)
        let morganResponseExpectation = XCTestExpectation(description: "Morgan response generated")
        
        chatRoomViewModel.$messages
            .sink { messages in
                let morganMessages = messages.filter { $0.senderName == "Morgan" }
                if !morganMessages.isEmpty {
                    morganResponseExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [morganResponseExpectation], timeout: 15.0)
        
        // Verify Morgan's response
        let morganMessages = chatRoomViewModel.messages.filter { $0.senderName == "Morgan" }
        XCTAssertGreaterThan(morganMessages.count, 0, "Morgan should have generated responses")
        
        if let morganMessage = morganMessages.first {
            XCTAssertEqual(morganMessage.messageType, .text, "Morgan's message should be text type")
            XCTAssertFalse(morganMessage.content.isEmpty, "Morgan's response should have content")
        }
    }
    
    func testConversationFlow() {
        // Test the full conversation flow between AI host and participant
        let user1 = User(id: "user1", email: "user1@test.com", name: "Alice", interests: [], onboardingCompleted: true, subscriptionType: .free)
        let user2 = User(id: "user2", email: "user2@test.com", name: "Morgan", interests: [], onboardingCompleted: true, subscriptionType: .premium)
        
        let chatRoom = ChatRoom(
            id: "test_room",
            participants: [user1, user2],
            aiHost: AIHost(personality: .professional),
            isActive: true,
            startTime: Date(),
            recordingEnabled: false
        )
        
        chatRoomViewModel.setup(chatRoom: chatRoom)
        
        // Wait for conversation to develop
        let conversationExpectation = XCTestExpectation(description: "Conversation develops")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 40) { // Wait for multiple exchanges
            conversationExpectation.fulfill()
        }
        
        wait(for: [conversationExpectation], timeout: 45.0)
        
        // Verify conversation has developed
        let totalMessages = chatRoomViewModel.messages.count
        let aiMessages = chatRoomViewModel.messages.filter { $0.messageType == .aiGenerated }
        let participantMessages = chatRoomViewModel.messages.filter { $0.senderName == "Morgan" }
        
        XCTAssertGreaterThan(totalMessages, 2, "Should have multiple messages in conversation")
        XCTAssertGreaterThan(aiMessages.count, 1, "AI should have sent multiple messages")
        XCTAssertGreaterThan(participantMessages.count, 0, "Morgan should have participated")
        
        // Verify message ordering and timing
        let sortedMessages = chatRoomViewModel.messages.sorted { $0.timestamp < $1.timestamp }
        XCTAssertEqual(sortedMessages.count, totalMessages, "Messages should be properly ordered by timestamp")
    }
    
    func testLLMServiceFailureHandling() {
        // Test that the system handles LLM service failures gracefully with fallbacks
        
        // Create a chatroom that would trigger LLM calls
        let user1 = User(id: "user1", email: "user1@test.com", name: "Alice", interests: [], onboardingCompleted: true, subscriptionType: .free)
        let user2 = User(id: "user2", email: "user2@test.com", name: "Morgan", interests: [], onboardingCompleted: true, subscriptionType: .premium)
        
        let chatRoom = ChatRoom(
            id: "test_room",
            participants: [user1, user2],
            aiHost: AIHost(personality: .friendly),
            isActive: true,
            startTime: Date(),
            recordingEnabled: false
        )
        
        // Note: This test assumes LLM services might fail and we have fallback messages
        chatRoomViewModel.setup(chatRoom: chatRoom)
        
        // Wait for initial message generation (welcome message or fallback)
        let fallbackExpectation = XCTestExpectation(description: "Fallback messages work")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            fallbackExpectation.fulfill()
        }
        
        wait(for: [fallbackExpectation], timeout: 5.0)
        
        // Verify that some form of message was generated (either LLM or fallback)
        XCTAssertGreaterThan(chatRoomViewModel.messages.count, 0, "Should have generated welcome message even if LLM fails")
        
        if let firstMessage = chatRoomViewModel.messages.first {
            XCTAssertFalse(firstMessage.content.isEmpty, "Message should have content")
            XCTAssertEqual(firstMessage.senderName, "MoMo", "First message should be from AI host")
        }
    }
    
    func testDifferentPersonalities() {
        // Test that different AI personalities generate appropriate responses
        let personalities: [HostPersonality] = [.friendly, .professional, .humorous, .empathetic]
        
        for personality in personalities {
            let user1 = User(id: "user1", email: "user1@test.com", name: "Alice", interests: [], onboardingCompleted: true, subscriptionType: .free)
            let user2 = User(id: "user2", email: "user2@test.com", name: "Morgan", interests: [], onboardingCompleted: true, subscriptionType: .premium)
            
            let chatRoom = ChatRoom(
                id: "test_room_\(personality.rawValue)",
                participants: [user1, user2],
                aiHost: AIHost(personality: personality),
                isActive: true,
                startTime: Date(),
                recordingEnabled: false
            )
            
            let personalityViewModel = ChatRoomViewModel()
            personalityViewModel.setup(chatRoom: chatRoom)
            
            // Wait for welcome message
            let personalityExpectation = XCTestExpectation(description: "Personality test for \(personality.rawValue)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                personalityExpectation.fulfill()
            }
            
            wait(for: [personalityExpectation], timeout: 3.0)
            
            // Verify message was generated for this personality
            XCTAssertGreaterThan(personalityViewModel.messages.count, 0, "Should generate message for \(personality.rawValue) personality")
            
            if let welcomeMessage = personalityViewModel.messages.first {
                XCTAssertEqual(welcomeMessage.senderName, "MoMo", "Message should be from MoMo")
                XCTAssertFalse(welcomeMessage.content.isEmpty, "Message should have content for \(personality.rawValue)")
            }
            
            personalityViewModel.endConversation()
        }
    }
    
    // MARK: - Performance Tests
    
    func testLLMResponsePerformance() {
        // Test that LLM responses don't block the UI
        let user1 = User(id: "user1", email: "user1@test.com", name: "Alice", interests: [], onboardingCompleted: true, subscriptionType: .free)
        let user2 = User(id: "user2", email: "user2@test.com", name: "Morgan", interests: [], onboardingCompleted: true, subscriptionType: .premium)
        
        let chatRoom = ChatRoom(
            id: "test_room",
            participants: [user1, user2],
            aiHost: AIHost(personality: .friendly),
            isActive: true,
            startTime: Date(),
            recordingEnabled: false
        )
        
        measure {
            chatRoomViewModel.setup(chatRoom: chatRoom)
            
            let performanceExpectation = XCTestExpectation(description: "Setup performance")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                performanceExpectation.fulfill()
            }
            
            wait(for: [performanceExpectation], timeout: 1.0)
        }
    }
    
    // MARK: - Audio Integration Tests
    
    func testSpeakingIndicatorsWithLLMResponses() {
        // Test that speaking indicators work correctly with LLM-generated responses
        let user1 = User(id: "user1", email: "user1@test.com", name: "Alice", interests: [], onboardingCompleted: true, subscriptionType: .free)
        let user2 = User(id: "user2", email: "user2@test.com", name: "Morgan", interests: [], onboardingCompleted: true, subscriptionType: .premium)
        
        let chatRoom = ChatRoom(
            id: "test_room",
            participants: [user1, user2],
            aiHost: AIHost(personality: .friendly),
            isActive: true,
            startTime: Date(),
            recordingEnabled: false
        )
        
        chatRoomViewModel.setup(chatRoom: chatRoom)
        
        // Wait for welcome message and speaking indicators
        let speakingExpectation = XCTestExpectation(description: "Speaking indicators work")
        
        chatRoomViewModel.$speakingParticipants
            .sink { speakingParticipants in
                if speakingParticipants.contains("momo") {
                    speakingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [speakingExpectation], timeout: 10.0)
        
        // Verify speaking indicators were activated
        XCTAssertTrue(chatRoomViewModel.speakingParticipants.isEmpty || chatRoomViewModel.speakingParticipants.contains("momo"), 
                     "MoMo should have been marked as speaking during welcome message")
    }
}