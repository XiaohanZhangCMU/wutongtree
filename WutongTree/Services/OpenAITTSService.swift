import Foundation
import AVFoundation

class OpenAITTSService: NSObject, ObservableObject {
    private let apiKey = "your-openai-api-key" // Add to your .env
    private let baseURL = "https://api.openai.com/v1/audio/speech"
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isSpeaking = false
    @Published var currentSpeaker: String?
    
    // Voice mapping for different personalities
    private let voiceMapping: [SpeechPersonality: String] = [
        .aiHost: "nova", // Clear, friendly female voice
        .participant: "alloy", // Balanced, conversational
        .neutral: "echo" // Clear, neutral
    ]
    
    func speak(_ text: String, for speaker: String, personality: SpeechPersonality = .neutral) {
        print("OpenAI TTS: Speaking for \(speaker): \(text)")
        
        guard let voice = voiceMapping[personality] else {
            print("OpenAI TTS: No voice mapping for personality")
            return
        }
        
        Task {
            do {
                let audioData = try await generateSpeech(text: text, voice: voice)
                await MainActor.run {
                    self.playAudio(data: audioData, speaker: speaker)
                }
            } catch {
                print("OpenAI TTS Error: \(error)")
            }
        }
    }
    
    private func generateSpeech(text: String, voice: String) async throws -> Data {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "model": "tts-1-hd", // Higher quality model
            "input": text,
            "voice": voice,
            "response_format": "mp3",
            "speed": 1.0
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TTSError.networkError
        }
        
        return data
    }
    
    private func playAudio(data: Data, speaker: String) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            currentSpeaker = speaker
            isSpeaking = true
            audioPlayer?.play()
        } catch {
            print("Audio playback error: \(error)")
        }
    }
    
    func stopSpeaking() {
        audioPlayer?.stop()
        isSpeaking = false
        currentSpeaker = nil
    }
    
    var isCurrentlySpeaking: Bool {
        return isSpeaking
    }
}

extension OpenAITTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
        currentSpeaker = nil
    }
}