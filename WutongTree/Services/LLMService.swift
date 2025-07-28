import Foundation

// MARK: - LLM Service Protocol
protocol LLMService {
    func generateResponse(
        messages: [LLMMessage],
        temperature: Double,
        maxTokens: Int
    ) async throws -> String
}

// MARK: - LLM Message Models
struct LLMMessage: Codable {
    let role: String // "system", "user", "assistant"
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

// MARK: - LLM Service Factory
class LLMServiceFactory {
    enum ServiceType {
        case anthropic
        case openai
        case vllm(baseURL: String)
    }
    
    static func createService(type: ServiceType, apiKey: String) -> LLMService {
        switch type {
        case .anthropic:
            return AnthropicLLMService(apiKey: apiKey)
        case .openai:
            return OpenAILLMService(apiKey: apiKey)
        case .vllm(let baseURL):
            return VLLMLLMService(baseURL: baseURL, apiKey: apiKey)
        }
    }
}

// MARK: - Configuration Manager
class LLMConfig {
    static let shared = LLMConfig()
    
    private init() {}
    
    func getAnthropicKey() -> String? {
        return ProcessInfo.processInfo.environment["ANTHROPIC_KEY"] ?? loadFromBundle("ANTHROPIC_KEY")
    }
    
    func getOpenAIKey() -> String? {
        return ProcessInfo.processInfo.environment["OPENAI_KEY"] ?? loadFromBundle("OPENAI_KEY")
    }
    
    private func loadFromBundle(_ key: String) -> String? {
        // Try to load from .env file in bundle
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil),
              let content = try? String(contentsOfFile: path) else {
            return nil
        }
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let components = line.components(separatedBy: "=")
            if components.count == 2 && components[0].trimmingCharacters(in: .whitespaces) == key {
                return components[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}