import Foundation
import Combine

class OnboardingInterviewViewModel: ObservableObject {
    @Published var messages: [OnboardingMessage] = []
    @Published var currentUserInput = ""
    @Published var isTyping = false
    @Published var currentQuestionIndex = 0
    @Published var isComplete = false
    @Published var userResponses: [String] = []
    
    private var llmService: LLMService?
    private let questions = [
        "Hi there! I'm MoMo, your AI guide. What's your name?",
        "Nice to meet you! How old are you?",
        "What topics do you love talking about? Tell me about your interests and hobbies.",
        "What kind of conversations are you hoping to have on WutongTree? Deep discussions, casual chats, or something else?",
        "Tell me about a recent experience or thought that's been on your mind lately.",
        "What's something you're passionate about that you'd love to share with someone new?",
        "Perfect! Let me analyze your responses to help find great conversation matches for you."
    ]
    
    init() {
        setupLLMService()
        startInterview()
    }
    
    private func setupLLMService() {
        guard let anthropicKey = LLMConfig.shared.getAnthropicKey() else {
            print("Warning: No Anthropic API key found for onboarding")
            return
        }
        llmService = LLMServiceFactory.createService(type: .anthropic, apiKey: anthropicKey)
    }
    
    private func startInterview() {
        askNextQuestion()
    }
    
    func submitResponse() {
        guard !currentUserInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = OnboardingMessage(
            id: UUID().uuidString,
            content: currentUserInput,
            isFromAI: false,
            timestamp: Date()
        )
        messages.append(userMessage)
        userResponses.append(currentUserInput)
        
        let response = currentUserInput
        currentUserInput = ""
        currentQuestionIndex += 1
        
        // Process response and ask next question
        Task {
            await processResponseAndContinue(response)
        }
    }
    
    private func processResponseAndContinue(_ response: String) async {
        // Small delay for natural conversation flow
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        if currentQuestionIndex < questions.count {
            if currentQuestionIndex == questions.count - 1 {
                // Final analysis message
                await generateAnalysisMessage()
            } else {
                await askNextQuestion()
            }
        } else {
            completeInterview()
        }
    }
    
    private func askNextQuestion() async {
        await MainActor.run {
            isTyping = true
        }
        
        // Simulate typing delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let questionContent: String
        
        if currentQuestionIndex < questions.count {
            if currentQuestionIndex == 0 || llmService == nil {
                // Use predefined questions for first question or if no LLM service
                questionContent = questions[currentQuestionIndex]
            } else {
                // Generate dynamic follow-up questions based on previous responses
                questionContent = await generateDynamicQuestion() ?? questions[currentQuestionIndex]
            }
        } else {
            questionContent = "Thank you! I have everything I need."
        }
        
        let aiMessage = OnboardingMessage(
            id: UUID().uuidString,
            content: questionContent,
            isFromAI: true,
            timestamp: Date()
        )
        
        await MainActor.run {
            self.messages.append(aiMessage)
            self.isTyping = false
        }
    }
    
    private func generateDynamicQuestion() async -> String? {
        guard let llmService = llmService else { return nil }
        
        let conversationHistory = userResponses.enumerated().map { index, response in
            "Q\(index + 1): \(questions[index])\nA\(index + 1): \(response)"
        }.joined(separator: "\n\n")
        
        let systemPrompt = """
        You are MoMo, a friendly AI guide conducting an onboarding interview for WutongTree, a voice chat app. 
        
        Your goal is to understand the user's personality, interests, and conversation preferences to help with matching.
        
        Guidelines:
        - Ask natural, engaging follow-up questions
        - Be warm and conversational
        - Focus on interests, personality, and what they want from conversations
        - Keep questions concise (1-2 sentences max)
        - Use emojis sparingly and naturally
        - Build on their previous responses
        
        Current question number: \(currentQuestionIndex + 1) of \(questions.count)
        """
        
        let messages: [LLMMessage] = [
            LLMMessage(role: "system", content: systemPrompt),
            LLMMessage(role: "user", content: """
                Based on this conversation history, generate the next engaging question:
                
                \(conversationHistory)
                
                Generate a natural follow-up question that builds on their responses and helps understand their personality and conversation preferences.
                """)
        ]
        
        do {
            return try await llmService.generateResponse(
                messages: messages,
                temperature: 0.8,
                maxTokens: 100
            )
        } catch {
            print("Failed to generate dynamic question: \(error)")
            return nil
        }
    }
    
    private func generateAnalysisMessage() async {
        await MainActor.run {
            isTyping = true
        }
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        let analysisContent: String
        
        if let llmService = llmService {
            analysisContent = await generatePersonalizedAnalysis() ?? getDefaultAnalysis()
        } else {
            analysisContent = getDefaultAnalysis()
        }
        
        let analysisMessage = OnboardingMessage(
            id: UUID().uuidString,
            content: analysisContent,
            isFromAI: true,
            timestamp: Date()
        )
        
        await MainActor.run {
            self.messages.append(analysisMessage)
            self.isTyping = false
        }
        
        // Complete after analysis
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
            self.completeInterview()
        }
    }
    
    private func generatePersonalizedAnalysis() async -> String? {
        guard let llmService = llmService else { return nil }
        
        let allResponses = userResponses.joined(separator: " | ")
        
        let systemPrompt = """
        You are MoMo, analyzing a user's onboarding responses for WutongTree. Create a brief, encouraging summary of their personality and interests that shows you understand them.
        
        Guidelines:
        - Be warm and positive
        - Highlight their key interests and personality traits
        - Mention what kind of conversations they'd enjoy
        - Keep it concise (2-3 sentences)
        - End with excitement about finding them great matches
        """
        
        let messages: [LLMMessage] = [
            LLMMessage(role: "system", content: systemPrompt),
            LLMMessage(role: "user", content: """
                Analyze these onboarding responses and create a personalized summary:
                
                \(allResponses)
                
                Generate an encouraging analysis that shows understanding of their personality and conversation preferences.
                """)
        ]
        
        do {
            return try await llmService.generateResponse(
                messages: messages,
                temperature: 0.7,
                maxTokens: 150
            )
        } catch {
            print("Failed to generate analysis: \(error)")
            return nil
        }
    }
    
    private func getDefaultAnalysis() -> String {
        "Perfect! Based on your responses, I can see you're someone who values meaningful connections and interesting conversations. I'm excited to help you find like-minded people to chat with on WutongTree! 🌟"
    }
    
    private func completeInterview() {
        isComplete = true
    }
    
    // Extract user data for User model
    func extractUserData() -> (name: String, age: Int?, interests: [String], lookingFor: String) {
        let name = userResponses.first ?? ""
        let age = userResponses.count > 1 ? Int(userResponses[1]) : nil
        
        // Extract interests from the third response
        let interestsText = userResponses.count > 2 ? userResponses[2] : ""
        let interests = extractInterests(from: interestsText)
        
        // Extract conversation preference from fourth response
        let lookingFor = userResponses.count > 3 ? userResponses[3] : "Meaningful conversations"
        
        return (name, age, interests, lookingFor)
    }
    
    private func extractInterests(from text: String) -> [String] {
        let commonInterests = [
            "politics", "philosophy", "technology", "art", "music", "sports",
            "science", "literature", "travel", "food", "movies", "gaming",
            "photography", "dancing", "writing", "history", "psychology",
            "cooking", "reading", "fitness", "nature", "business"
        ]
        
        let lowercaseText = text.lowercased()
        var foundInterests: [String] = []
        
        for interest in commonInterests {
            if lowercaseText.contains(interest) {
                foundInterests.append(interest.capitalized)
            }
        }
        
        // If no common interests found, use the first few words as interests
        if foundInterests.isEmpty {
            let words = text.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty && $0.count > 2 }
                .prefix(3)
            foundInterests = Array(words).map { $0.capitalized }
        }
        
        return foundInterests
    }
}

struct OnboardingMessage: Identifiable, Codable {
    let id: String
    let content: String
    let isFromAI: Bool
    let timestamp: Date
}