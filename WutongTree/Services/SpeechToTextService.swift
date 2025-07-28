import Foundation
import Speech
import AVFoundation

class SpeechToTextService: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioSession = AVAudioSession.sharedInstance()
    
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var isSpeechAvailable = false
    
    override init() {
        super.init()
        setupSpeechRecognizer()
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isSpeechAvailable = true
                    print("STT: Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    self?.isSpeechAvailable = false
                    print("STT: Speech recognition not authorized: \(authStatus)")
                @unknown default:
                    self?.isSpeechAvailable = false
                    print("STT: Unknown authorization status")
                }
            }
        }
    }
    
    func startListening() {
        guard isSpeechAvailable else {
            print("STT: Speech recognition not available")
            return
        }
        
        // Cancel any previous task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        setupAudioSession()
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            print("STT: Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self?.transcribedText = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
                print("STT: \(isFinal ? "Final" : "Partial") result: \(result.bestTranscription.formattedString)")
            }
            
            if error != nil || isFinal {
                print("STT: Recognition ended - Error: \(error?.localizedDescription ?? "None"), Final: \(isFinal)")
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self?.isListening = false
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
                self.transcribedText = ""
            }
            print("STT: Started listening")
        } catch {
            print("STT: Could not start audio engine: \(error)")
        }
    }
    
    func stopListening() {
        print("STT: Stopping listening")
        audioEngine.stop()
        recognitionRequest?.endAudio()
        
        DispatchQueue.main.async {
            self.isListening = false
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("STT: Failed to setup audio session: \(error)")
        }
    }
    
    func resetTranscription() {
        transcribedText = ""
    }
}

// MARK: - SFSpeechRecognizerDelegate
extension SpeechToTextService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            self.isSpeechAvailable = available
        }
        print("STT: Speech recognizer availability changed: \(available)")
    }
}