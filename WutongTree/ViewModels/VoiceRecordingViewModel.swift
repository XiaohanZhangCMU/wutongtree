import Foundation
import AVFoundation
import Combine

class VoiceRecordingViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0
    @Published var hasPermission = false
    @Published var errorMessage: String?
    @Published var recordingCompleted = false
    @Published var recordingData: Data?
    
    @Published var audioPermissionService = AudioPermissionService()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    
    private let recordingSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        setupAudioSession()
        requestPermission()
    }
    
    private func setupAudioSession() {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    func requestPermission() {
        Task {
            let granted = await audioPermissionService.requestPermission()
            DispatchQueue.main.async {
                self.hasPermission = granted
                if !granted {
                    self.errorMessage = "Microphone permission is required to use WutongTree"
                }
            }
        }
    }
    
    func startRecording() {
        guard hasPermission else {
            requestPermission()
            return
        }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            recordingDuration = 0
            
            startTimers()
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimers()
        
        processRecording()
    }
    
    private func startTimers() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
        }
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }
    
    private func stopTimers() {
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        recordingTimer = nil
        levelTimer = nil
    }
    
    private func updateAudioLevel() {
        audioRecorder?.updateMeters()
        audioLevel = audioRecorder?.averagePower(forChannel: 0) ?? 0
    }
    
    private func processRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Load the recorded data
            do {
                let data = try Data(contentsOf: audioFilename)
                DispatchQueue.main.async {
                    self.recordingData = data
                    self.recordingCompleted = true
                    print("Recording processed: \(audioFilename.path)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to process recording: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func playRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilename)
            audioPlayer?.play()
        } catch {
            errorMessage = "Failed to play recording: \(error.localizedDescription)"
        }
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
            if flag {
                self.processRecording()
            } else {
                self.errorMessage = "Recording failed to complete"
            }
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.errorMessage = "Recording encoding error: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}