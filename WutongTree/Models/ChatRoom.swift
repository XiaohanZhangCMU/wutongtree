import Foundation

struct ChatRoom: Identifiable, Codable {
    let id: String
    let participants: [User]
    let aiHost: AIHost
    var isActive: Bool
    var startTime: Date
    var endTime: Date?
    var conversationTopic: String?
    var recordingEnabled: Bool
    var recordingPath: String?
}

struct AIHost: Codable {
    let id: String = "momo"
    let name: String = "MoMo"
    let avatar: String = "momo_avatar"
    let personality: HostPersonality
}

enum HostPersonality: String, Codable, CaseIterable {
    case friendly = "friendly"
    case professional = "professional"
    case humorous = "humorous"
    case empathetic = "empathetic"
    
    var description: String {
        switch self {
        case .friendly:
            return "Warm and welcoming conversation facilitator"
        case .professional:
            return "Professional and structured conversation guide"
        case .humorous:
            return "Light-hearted and fun conversation starter"
        case .empathetic:
            return "Understanding and supportive conversation helper"
        }
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let senderID: String
    let senderName: String
    let content: String
    let timestamp: Date
    let messageType: MessageType
    
    enum MessageType: String, Codable {
        case text
        case voice
        case system
        case aiGenerated
    }
}