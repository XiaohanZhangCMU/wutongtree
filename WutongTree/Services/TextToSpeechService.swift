import Foundation
import AVFoundation

class TextToSpeechService: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var audioSession = AVAudioSession.sharedInstance()
    
    @Published var isSpeaking = false
    @Published var currentSpeaker: String?
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup TTS audio session: \(error)")
        }
    }
    
    func speak(_ text: String, for speaker: String, personality: SpeechPersonality = .neutral) {
        print("TTS: 🔊 Speaking text for \(speaker): \(text)")
        print("TTS: Audio session category: \(audioSession.category)")
        print("TTS: Audio session active: \(audioSession.isOtherAudioPlaying)")
        
        // Stop any current speech
        if synthesizer.isSpeaking {
            print("TTS: Stopping current speech")
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        // Ensure audio session is properly configured for playback
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("TTS: Audio session configured for playback")
        } catch {
            print("TTS: ❌ Failed to configure audio session: \(error)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        configureUtterance(utterance, for: personality)
        
        currentSpeaker = speaker
        isSpeaking = true
        
        print("TTS: 🎤 Starting synthesis with rate: \(utterance.rate), pitch: \(utterance.pitchMultiplier), volume: \(utterance.volume)")
        synthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        currentSpeaker = nil
    }
    
    private func configureUtterance(_ utterance: AVSpeechUtterance, for personality: SpeechPersonality) {
        // Configure voice characteristics based on personality
        switch personality {
        case .aiHost:
            utterance.rate = 0.52 // Slightly slower for clarity
            utterance.pitchMultiplier = 1.1 // Slightly higher pitch
            utterance.volume = 0.8
            
        case .participant:
            utterance.rate = 0.55 // Natural speaking rate
            utterance.pitchMultiplier = 0.95 // Slightly lower pitch
            utterance.volume = 0.85
            
        case .neutral:
            utterance.rate = 0.5 // Default rate
            utterance.pitchMultiplier = 1.0
            utterance.volume = 0.8
        }
        
        // Try to use a more natural voice if available
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
    }
    
    var isCurrentlySpeaking: Bool {
        return synthesizer.isSpeaking
    }
}

// MARK: - Speech Synthesis Delegate
extension TextToSpeechService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("TTS: ✅ Speech synthesis started")
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("TTS: ✅ Speech synthesis finished")
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentSpeaker = nil
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentSpeaker = nil
        }
    }
}

enum SpeechPersonality {
    case aiHost
    case participant  
    case neutral
}