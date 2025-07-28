import XCTest
import Foundation
@testable import WutongTree

final class LLMServiceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - LLM Config Tests
    
    func testLLMConfigGetAnthropicKey() {
        // Test reading Anthropic key from environment/bundle
        let config = LLMConfig.shared
        let key = config.getAnthropicKey()
        
        // Should either have a key or return nil if not configured
        if let key = key {
            XCTAssertFalse(key.isEmpty, "Anthropic key should not be empty if present")
            XCTAssertTrue(key.hasPrefix("sk-"), "Anthropic key should start with 'sk-'")
        }
    }
    
    func testLLMConfigGetOpenAIKey() {
        let config = LLMConfig.shared
        let key = config.getOpenAIKey()
        
        // Should either have a key or return nil if not configured
        if let key = key {
            XCTAssertFalse(key.isEmpty, "OpenAI key should not be empty if present")
        }
    }
    
    // MARK: - LLM Service Factory Tests
    
    func testLLMServiceFactoryCreatesAnthropicService() {
        let service = LLMServiceFactory.createService(type: .anthropic, apiKey: "test-key")
        
        XCTAssertTrue(service is AnthropicLLMService, "Factory should create AnthropicLLMService")
    }
    
    func testLLMServiceFactoryCreatesOpenAIService() {
        let service = LLMServiceFactory.createService(type: .openai, apiKey: "test-key")
        
        XCTAssertTrue(service is OpenAILLMService, "Factory should create OpenAILLMService")
    }
    
    func testLLMServiceFactoryCreatesVLLMService() {
        let service = LLMServiceFactory.createService(type: .vllm(baseURL: "http://localhost:8000"), apiKey: "test-key")
        
        XCTAssertTrue(service is VLLMLLMService, "Factory should create VLLMLLMService")
    }
    
    // MARK: - LLM Message Tests
    
    func testLLMMessageCreation() {
        let message = LLMMessage(role: "user", content: "Test message")
        
        XCTAssertEqual(message.role, "user")
        XCTAssertEqual(message.content, "Test message")
    }
    
    func testLLMMessageCodable() {
        let message = LLMMessage(role: "assistant", content: "Test response")
        
        // Test encoding
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(message))
        
        // Test decoding
        let decoder = JSONDecoder()
        do {
            let data = try encoder.encode(message)
            let decodedMessage = try decoder.decode(LLMMessage.self, from: data)
            
            XCTAssertEqual(decodedMessage.role, message.role)
            XCTAssertEqual(decodedMessage.content, message.content)
        } catch {
            XCTFail("Failed to encode/decode LLMMessage: \(error)")
        }
    }
    
    // MARK: - LLM Error Tests
    
    func testLLMErrorDescriptions() {
        let encodingError = LLMError.encodingError(NSError(domain: "test", code: 1))
        XCTAssertTrue(encodingError.errorDescription?.contains("Failed to encode request") ?? false)
        
        let networkError = LLMError.networkError(NSError(domain: "test", code: 2))
        XCTAssertTrue(networkError.errorDescription?.contains("Network error") ?? false)
        
        let apiError = LLMError.apiError(429, "Rate limit exceeded")
        XCTAssertTrue(apiError.errorDescription?.contains("API error (429)") ?? false)
        
        let noContentError = LLMError.noContentError
        XCTAssertEqual(noContentError.errorDescription, "No content in response")
        
        let missingKeyError = LLMError.missingApiKey
        XCTAssertEqual(missingKeyError.errorDescription, "Missing API key")
    }
    
    // MARK: - Mock LLM Service for Testing
    
    func testMockLLMService() {
        let mockService = MockLLMService()
        let messages = [
            LLMMessage(role: "system", content: "You are a helpful assistant."),
            LLMMessage(role: "user", content: "Hello!")
        ]
        
        let expectation = XCTestExpectation(description: "Mock LLM response")
        
        Task {
            do {
                let response = try await mockService.generateResponse(
                    messages: messages,
                    temperature: 0.7,
                    maxTokens: 100
                )
                
                XCTAssertFalse(response.isEmpty, "Mock response should not be empty")
                XCTAssertTrue(response.contains("mock"), "Mock response should contain 'mock'")
                expectation.fulfill()
            } catch {
                XCTFail("Mock service should not throw error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testMockLLMServiceWithError() {
        let mockService = MockLLMService(shouldFail: true)
        let messages = [LLMMessage(role: "user", content: "Test")]
        
        let expectation = XCTestExpectation(description: "Mock LLM error")
        
        Task {
            do {
                _ = try await mockService.generateResponse(
                    messages: messages,
                    temperature: 0.7,
                    maxTokens: 100
                )
                XCTFail("Mock service should throw error when shouldFail is true")
            } catch {
                XCTAssertTrue(error is LLMError, "Should throw LLMError")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Integration Tests with Chat Room
    
    func testChatRoomViewModelWithMockLLMService() {
        let chatRoomViewModel = ChatRoomViewModel()
        
        // Create test chat room
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
        
        // Setup chat room
        chatRoomViewModel.setup(chatRoom: chatRoom)
        
        // Wait for welcome message
        let expectation = XCTestExpectation(description: "Welcome message generated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        
        // Verify welcome message was added
        XCTAssertGreaterThan(chatRoomViewModel.messages.count, 0, "Should have at least one welcome message")
        
        let welcomeMessage = chatRoomViewModel.messages.first
        XCTAssertNotNil(welcomeMessage, "Should have a welcome message")
        XCTAssertEqual(welcomeMessage?.messageType, .aiGenerated, "Welcome message should be AI generated")
        XCTAssertEqual(welcomeMessage?.senderName, "MoMo", "Welcome message should be from MoMo")
    }
    
    // MARK: - Performance Tests
    
    func testLLMServicePerformance() {
        let mockService = MockLLMService()
        let messages = [LLMMessage(role: "user", content: "Performance test")]
        
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                do {
                    _ = try await mockService.generateResponse(
                        messages: messages,
                        temperature: 0.7,
                        maxTokens: 50
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 0.1)
        }
    }
    
    // MARK: - Edge Cases
    
    func testLLMServiceWithEmptyMessages() {
        let mockService = MockLLMService()
        let emptyMessages: [LLMMessage] = []
        
        let expectation = XCTestExpectation(description: "Empty messages test")
        
        Task {
            do {
                let response = try await mockService.generateResponse(
                    messages: emptyMessages,
                    temperature: 0.7,
                    maxTokens: 100
                )
                
                XCTAssertFalse(response.isEmpty, "Should handle empty messages gracefully")
                expectation.fulfill()
            } catch {
                XCTFail("Should handle empty messages without error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLLMServiceWithExtremeParameters() {
        let mockService = MockLLMService()
        let messages = [LLMMessage(role: "user", content: "Test")]
        
        let expectation = XCTestExpectation(description: "Extreme parameters test")
        
        Task {
            do {
                // Test with extreme temperature and token values
                let response = try await mockService.generateResponse(
                    messages: messages,
                    temperature: 2.0, // Very high temperature
                    maxTokens: 1 // Very low token count
                )
                
                XCTAssertFalse(response.isEmpty, "Should handle extreme parameters")
                expectation.fulfill()
            } catch {
                XCTFail("Should handle extreme parameters: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// MARK: - Mock LLM Service for Testing

class MockLLMService: LLMService {
    private let shouldFail: Bool
    private let delay: TimeInterval
    
    init(shouldFail: Bool = false, delay: TimeInterval = 0.1) {
        self.shouldFail = shouldFail
        self.delay = delay
    }
    
    func generateResponse(
        messages: [LLMMessage],
        temperature: Double,
        maxTokens: Int
    ) async throws -> String {
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if shouldFail {
            throw LLMError.apiError(500, "Mock service error")
        }
        
        // Generate mock response based on input
        let lastMessage = messages.last?.content ?? "No message"
        
        if lastMessage.lowercased().contains("welcome") {
            return "🎙️ Welcome to WutongTree! I'm MoMo, your friendly AI host. Let's have a great conversation! 😊"
        } else if lastMessage.lowercased().contains("host message") {
            return "🎯 That's interesting! What do you all think about that? Let's dive deeper! 💭"
        } else if lastMessage.lowercased().contains("natural response") {
            return "That's really cool! 😄 I love hearing different perspectives on this topic."
        } else {
            return "This is a mock response from the LLM service for testing purposes."
        }
    }
}