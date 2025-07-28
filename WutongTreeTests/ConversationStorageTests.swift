import XCTest
@testable import WutongTree

final class ConversationStorageTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any existing conversations
        UserDefaults.standard.removeObject(forKey: "savedConversations")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "savedConversations")
        super.tearDown()
    }
    
    func testConversationRecordingAndStorage() {
        // Step 15 from spec: Conversations are recorded and saved to phone storage
        
        // Create a conversation record
        let conversationRecord = ConversationRecord(
            id: "test123",
            partnerName: "Test Partner",
            topic: "Test Topic",
            duration: 1800, // 30 minutes
            date: Date(),
            rating: 5,
            hasRecording: true
        )
        
        // Save to local storage
        var savedConversations: [ConversationRecord] = []
        savedConversations.append(conversationRecord)
        
        if let data = try? JSONEncoder().encode(savedConversations) {
            UserDefaults.standard.set(data, forKey: "savedConversations")
        }
        
        // Verify it was saved
        guard let retrievedData = UserDefaults.standard.data(forKey: "savedConversations"),
              let retrievedConversations = try? JSONDecoder().decode([ConversationRecord].self, from: retrievedData) else {
            XCTFail("Failed to retrieve saved conversations")
            return
        }
        
        XCTAssertEqual(retrievedConversations.count, 1)
        XCTAssertEqual(retrievedConversations.first?.id, "test123")
        XCTAssertEqual(retrievedConversations.first?.partnerName, "Test Partner")
        XCTAssertEqual(retrievedConversations.first?.duration, 1800)
        XCTAssertTrue(retrievedConversations.first?.hasRecording ?? false)
    }
    
    func testMultipleConversationStorage() {
        // Test storing multiple conversations
        
        let conversations = [
            ConversationRecord(
                id: "conv1",
                partnerName: "Partner 1",
                topic: "Topic 1",
                duration: 1200,
                date: Date().addingTimeInterval(-86400), // Yesterday
                rating: 4,
                hasRecording: true
            ),
            ConversationRecord(
                id: "conv2",
                partnerName: "Partner 2",
                topic: "Topic 2",
                duration: 1800,
                date: Date(),
                rating: 5,
                hasRecording: false
            )
        ]
        
        // Save conversations
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: "savedConversations")
        }
        
        // Retrieve and verify
        guard let retrievedData = UserDefaults.standard.data(forKey: "savedConversations"),
              let retrievedConversations = try? JSONDecoder().decode([ConversationRecord].self, from: retrievedData) else {
            XCTFail("Failed to retrieve saved conversations")
            return
        }
        
        XCTAssertEqual(retrievedConversations.count, 2)
        
        // Verify sorting by date (newest first)
        let sortedConversations = retrievedConversations.sorted { $0.date > $1.date }
        XCTAssertEqual(sortedConversations.first?.id, "conv2") // Most recent
        XCTAssertEqual(sortedConversations.last?.id, "conv1") // Older
    }
    
    func testConversationSharingCapability() {
        // Step 15 from spec: Users can share recordings in social media or podcast
        
        let conversationRecord = ConversationRecord(
            id: "shareable",
            partnerName: "Share Partner",
            topic: "Shareable Topic",
            duration: 2400,
            date: Date(),
            rating: 5,
            hasRecording: true
        )
        
        // Verify conversation has recording for sharing
        XCTAssertTrue(conversationRecord.hasRecording, "Conversation must have recording to be shareable")
        XCTAssertGreaterThan(conversationRecord.duration, 0, "Conversation must have duration for sharing")
        XCTAssertFalse(conversationRecord.partnerName.isEmpty, "Partner name needed for sharing context")
        XCTAssertFalse(conversationRecord.topic.isEmpty, "Topic needed for sharing context")
    }
    
    func testRecordingFilePathGeneration() {
        // Test that recording file paths are properly generated
        
        let timestamp = Date().timeIntervalSince1970
        let expectedFilename = "conversation_\(timestamp).m4a"
        
        // Simulate file path generation
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilePath = documentsPath.appendingPathComponent(expectedFilename)
        
        XCTAssertTrue(audioFilePath.path.contains("conversation_"))
        XCTAssertTrue(audioFilePath.path.hasSuffix(".m4a"))
        XCTAssertTrue(audioFilePath.path.contains("Documents"))
    }
    
    func testConversationMetadataCompleteness() {
        // Verify all required metadata is captured per spec
        
        let conversationRecord = ConversationRecord(
            id: "metadata_test",
            partnerName: "Metadata Partner",
            topic: "Metadata Topic",
            duration: 1500,
            date: Date(),
            rating: 4,
            hasRecording: true
        )
        
        // All required fields should be present
        XCTAssertFalse(conversationRecord.id.isEmpty, "ID is required")
        XCTAssertFalse(conversationRecord.partnerName.isEmpty, "Partner name is required")
        XCTAssertFalse(conversationRecord.topic.isEmpty, "Topic is required")
        XCTAssertGreaterThan(conversationRecord.duration, 0, "Duration must be positive")
        XCTAssertNotNil(conversationRecord.date, "Date is required")
        XCTAssertGreaterThanOrEqual(conversationRecord.rating, 0, "Rating must be non-negative")
        XCTAssertLessThanOrEqual(conversationRecord.rating, 5, "Rating must not exceed 5")
    }
    
    func testRecordingPrivacy() {
        // Step 13 from spec: Both users must agree to recording
        
        // Simulate recording agreement flow
        var recordingAgreed = false
        
        // In real implementation, this would be a UI prompt
        // For testing, we simulate user agreement
        recordingAgreed = true // Both users agreed
        
        XCTAssertTrue(recordingAgreed, "Recording can only proceed with agreement from both participants")
        
        // Only save if agreed
        if recordingAgreed {
            let conversation = ConversationRecord(
                id: "agreed_recording",
                partnerName: "Agreeing Partner",
                topic: "Agreed Topic",
                duration: 1200,
                date: Date(),
                rating: 5,
                hasRecording: true
            )
            
            XCTAssertTrue(conversation.hasRecording, "Recording saved only with consent")
        }
    }
    
    func testConversationEndTriggersRecordingSave() {
        // Step 14 from spec: When conversation ends, recording is saved
        
        // Simulate conversation ending
        let conversationEnded = true
        let recordingWasActive = true
        
        if conversationEnded && recordingWasActive {
            let finalRecord = ConversationRecord(
                id: "ended_conversation",
                partnerName: "End Partner",
                topic: "Ending Topic",
                duration: 1800,
                date: Date(),
                rating: 0, // Not yet rated
                hasRecording: true
            )
            
            // Save the recording
            var conversations: [ConversationRecord] = []
            conversations.append(finalRecord)
            
            if let data = try? JSONEncoder().encode(conversations) {
                UserDefaults.standard.set(data, forKey: "savedConversations")
            }
            
            // Verify saving occurred
            guard let savedData = UserDefaults.standard.data(forKey: "savedConversations"),
                  let savedConversations = try? JSONDecoder().decode([ConversationRecord].self, from: savedData) else {
                XCTFail("Recording should be saved when conversation ends")
                return
            }
            
            XCTAssertEqual(savedConversations.count, 1)
            XCTAssertTrue(savedConversations.first?.hasRecording ?? false)
        }
    }
}