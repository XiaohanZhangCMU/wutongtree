import Foundation

class AnthropicLLMService: LLMService {
    private let apiKey: String
    private let baseURL = "https://api.anthropic.com/v1/messages"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateResponse(
        messages: [LLMMessage],
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) async throws -> String {
        
        // Convert messages to Anthropic format
        let anthropicMessages = messages.filter { $0.role != "system" }.map { message in
            AnthropicMessage(role: message.role, content: message.content)
        }
        
        // Extract system message
        let systemMessage = messages.first { $0.role == "system" }?.content
        
        let requestBody = AnthropicRequest(
            model: "claude-3-haiku-20240307",
            maxTokens: maxTokens,
            temperature: temperature,
            system: systemMessage,
            messages: anthropicMessages
        )
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw LLMError.encodingError(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw LLMError.apiError(httpResponse.statusCode, errorMessage)
                }
            }
            
            let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            
            // Extract text content from the response
            if let textContent = anthropicResponse.content.first(where: { $0.type == "text" }) {
                return textContent.text
            } else {
                throw LLMError.noContentError
            }
            
        } catch let error as LLMError {
            throw error
        } catch {
            throw LLMError.networkError(error)
        }
    }
}

// MARK: - Anthropic API Models
private struct AnthropicRequest: Codable {
    let model: String
    let maxTokens: Int
    let temperature: Double
    let system: String?
    let messages: [AnthropicMessage]
    
    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case temperature
        case system
        case messages
    }
}

private struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

private struct AnthropicResponse: Codable {
    let content: [AnthropicContent]
}

private struct AnthropicContent: Codable {
    let type: String
    let text: String
}

// MARK: - LLM Errors
enum LLMError: Error, LocalizedError {
    case encodingError(Error)
    case networkError(Error)
    case apiError(Int, String)
    case noContentError
    case missingApiKey
    
    var errorDescription: String? {
        switch self {
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .noContentError:
            return "No content in response"
        case .missingApiKey:
            return "Missing API key"
        }
    }
}