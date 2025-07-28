import Foundation
import AVFoundation

class ElevenLabsTTSService: NSObject, ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.elevenlabs.io/v1"
    
    override init() {
        self.apiKey = LLMConfig.shared.getElevenLabsKey() ?? ""
        super.init()
        if apiKey.isEmpty {
            print("⚠️ ElevenLabs: No API key found")
        } else {
            print("✅ ElevenLabs: API key loaded")
        }
    }
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isSpeaking = false
    @Published var currentSpeaker: String?
    
    // Voice IDs for different personalities
    private let voiceMapping: [SpeechPersonality: String] = [
        .aiHost: "21m00Tcm4TlvDq8ikWAM", // Rachel - warm, professional
        .participant: "AZnzlk1XvdvUeBnXmlld", // Domi - friendly, conversational
        .neutral: "EXAVITQu4vr4xnSDxMaL" // Bella - neutral, clear
    ]
    
    func speak(_ text: String, for speaker: String, personality: SpeechPersonality = .neutral) {
        print("🔊 ElevenLabs TTS: Starting speech for \(speaker): \(text)")
        
        guard !apiKey.isEmpty else {
            print("❌ ElevenLabs TTS: No API key available")
            return
        }
        
        guard let voiceId = voiceMapping[personality] else {
            print("❌ ElevenLabs TTS: No voice mapping for personality \(personality)")
            return
        }
        
        print("🎤 ElevenLabs TTS: Using voice ID: \(voiceId)")
        
        Task {
            do {
                print("🌐 ElevenLabs TTS: Making API request...")
                let audioData = try await generateSpeech(text: text, voiceId: voiceId)
                print("✅ ElevenLabs TTS: Received audio data (\(audioData.count) bytes)")
                
                await MainActor.run {
                    print("🎵 ElevenLabs TTS: Playing audio...")
                    self.playAudio(data: audioData, speaker: speaker)
                }
            } catch {
                print("❌ ElevenLabs TTS Error: \(error)")
                // Fallback to system TTS if ElevenLabs fails
                await MainActor.run {
                    self.fallbackToSystemTTS(text: text, speaker: speaker)
                }
            }
        }
    }
    
    private func generateSpeech(text: String, voiceId: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/text-to-speech/\(voiceId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": 0.75,
                "similarity_boost": 0.75,
                "style": 0.5,
                "use_speaker_boost": true
            ]
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
            // Setup audio session for playback
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            
            currentSpeaker = speaker
            isSpeaking = true
            
            let success = audioPlayer?.play() ?? false
            print("🎵 ElevenLabs TTS: Audio playback started: \(success)")
            
            if !success {
                print("❌ ElevenLabs TTS: Failed to start audio playback")
                isSpeaking = false
                currentSpeaker = nil
            }
        } catch {
            print("❌ ElevenLabs TTS: Audio playback error: \(error)")
            isSpeaking = false
            currentSpeaker = nil
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
    
    private func fallbackToSystemTTS(text: String, speaker: String) {
        print("🔄 ElevenLabs TTS: Falling back to system TTS")
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.volume = 0.8
        
        currentSpeaker = speaker
        isSpeaking = true
        synthesizer.speak(utterance)
        
        // Reset after a delay (rough estimate)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.count) * 0.1) {
            self.isSpeaking = false
            self.currentSpeaker = nil
        }
    }
}

extension ElevenLabsTTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
        currentSpeaker = nil
    }
}

enum TTSError: Error {
    case networkError
    case audioError
}