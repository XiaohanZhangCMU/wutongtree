import Foundation
import AVFoundation

class CustomTTSService: NSObject, ObservableObject {
    private let serverURL = "http://your-gpu-cluster.com:8000" // Your TTS server
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isSpeaking = false
    @Published var currentSpeaker: String?
    
    // Voice mapping for your custom models
    private let voiceMapping: [SpeechPersonality: String] = [
        .aiHost: "friendly_host_voice",
        .participant: "casual_participant_voice", 
        .neutral: "neutral_voice"
    ]
    
    func speak(_ text: String, for speaker: String, personality: SpeechPersonality = .neutral) {
        print("Custom TTS: Speaking for \(speaker): \(text)")
        
        guard let voiceId = voiceMapping[personality] else {
            print("Custom TTS: No voice mapping for personality")
            return
        }
        
        Task {
            do {
                let audioData = try await generateSpeech(text: text, voiceId: voiceId)
                await MainActor.run {
                    self.playAudio(data: audioData, speaker: speaker)
                }
            } catch {
                print("Custom TTS Error: \(error)")
            }
        }
    }
    
    private func generateSpeech(text: String, voiceId: String) async throws -> Data {
        let url = URL(string: "\(serverURL)/synthesize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "text": text,
            "voice_id": voiceId,
            "speed": 1.0,
            "emotion": "neutral", // Can customize based on context
            "format": "wav"
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

extension CustomTTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
        currentSpeaker = nil
    }
}