import Foundation

class HostPersonalityService {
    enum Mood: CaseIterable {
        case excited, curious, empathetic, playful, thoughtful, encouraging
        
        var description: String {
            switch self {
            case .excited: return "excited and energetic"
            case .curious: return "genuinely curious and inquisitive"
            case .empathetic: return "empathetic and understanding"
            case .playful: return "playful and lighthearted"
            case .thoughtful: return "thoughtful and reflective"
            case .encouraging: return "encouraging and supportive"
            }
        }
    }
    
    enum ResponseStyle: CaseIterable {
        case questionAsker, reactiveListener, topicBridger, encourager
        
        var instruction: String {
            switch self {
            case .questionAsker:
                return "Ask a specific follow-up question about what they just said"
            case .reactiveListener:
                return "React naturally to what they shared, like a friend would"
            case .topicBridger:
                return "Connect what they said to something relatable or ask others to share"
            case .encourager:
                return "Encourage them to share more or validate what they said"
            }
        }
    }
    
    private var currentMood: Mood = .curious
    private var lastResponseTime = Date()
    
    func generateContextualPrompt(recentMessages: [ChatMessage]) -> (systemPrompt: String, temperature: Double) {
        // Analyze conversation context
        let conversationTone = analyzeConversationTone(messages: recentMessages)
        adaptMoodToConversation(tone: conversationTone)
        
        let responseStyle = chooseResponseStyle(messages: recentMessages)
        
        let systemPrompt = """
        You're a skilled human conversation host with a \(currentMood.description) personality right now.
        
        Your role: \(responseStyle.instruction)
        
        Context from recent conversation:
        \(getConversationContext(messages: recentMessages))
        
        Respond like a real person would - be genuinely interested and natural. Reference specific things they mentioned.
        Use natural speech patterns: "Oh that's actually really cool", "Wait, so you're saying...", "That reminds me of..."
        
        Keep it conversational (10-20 words) and sound authentically human.
        """
        
        let temperature = currentMood == .playful || currentMood == .excited ? 0.95 : 0.85
        
        return (systemPrompt, temperature)
    }
    
    private func analyzeConversationTone(messages: [ChatMessage]) -> String {
        let recentContent = messages.suffix(3).map { $0.content.lowercased() }.joined(separator: " ")
        
        if recentContent.contains("excited") || recentContent.contains("amazing") || recentContent.contains("love") {
            return "excited"
        } else if recentContent.contains("difficult") || recentContent.contains("hard") || recentContent.contains("struggle") {
            return "empathetic"
        } else if recentContent.contains("funny") || recentContent.contains("lol") || recentContent.contains("haha") {
            return "playful"
        } else {
            return "curious"
        }
    }
    
    private func adaptMoodToConversation(tone: String) {
        switch tone {
        case "excited":
            currentMood = Bool.random() ? .excited : .encouraging
        case "empathetic":
            currentMood = Bool.random() ? .empathetic : .encouraging
        case "playful":
            currentMood = Bool.random() ? .playful : .curious
        default:
            currentMood = [.curious, .thoughtful].randomElement() ?? .curious
        }
    }
    
    private func chooseResponseStyle(messages: [ChatMessage]) -> ResponseStyle {
        let lastMessage = messages.last?.content ?? ""
        
        if lastMessage.contains("?") {
            return .reactiveListener // They asked a question, respond to it
        } else if messages.count % 3 == 0 {
            return .topicBridger // Occasionally bridge topics
        } else if lastMessage.count > 50 {
            return .encourager // They shared something substantial
        } else {
            return .questionAsker // Ask follow-up questions
        }
    }
    
    private func getConversationContext(messages: [ChatMessage]) -> String {
        let recentMessages = messages.suffix(3)
        if recentMessages.isEmpty {
            return "Conversation is just starting"
        }
        
        let context = recentMessages.map { "\($0.senderName): \($0.content)" }.joined(separator: "\n")
        return "Recent messages:\n\(context)"
    }
}