import Foundation

class VLLMLLMService: LLMService {
    private let baseURL: String
    private let apiKey: String
    
    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
    
    func generateResponse(
        messages: [LLMMessage],
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) async throws -> String {
        
        let vllmMessages = messages.map { message in
            VLLMMessage(role: message.role, content: message.content)
        }
        
        let requestBody = VLLMRequest(
            model: "default", // Can be configured based on vLLM deployment
            messages: vllmMessages,
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        let url = baseURL.hasSuffix("/") ? baseURL + "v1/chat/completions" : baseURL + "/v1/chat/completions"
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
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
            
            let vllmResponse = try JSONDecoder().decode(VLLMResponse.self, from: data)
            
            if let choice = vllmResponse.choices.first {
                return choice.message.content
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

// MARK: - vLLM API Models (OpenAI-compatible)
private struct VLLMRequest: Codable {
    let model: String
    let messages: [VLLMMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

private struct VLLMMessage: Codable {
    let role: String
    let content: String
}

private struct VLLMResponse: Codable {
    let choices: [VLLMChoice]
}

private struct VLLMChoice: Codable {
    let message: VLLMMessage
}