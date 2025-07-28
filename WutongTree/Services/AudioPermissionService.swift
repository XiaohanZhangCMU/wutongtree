import Foundation
import AVFoundation

class AudioPermissionService: ObservableObject {
    @Published var permissionStatus: AVAudioSession.RecordPermission = .undetermined
    @Published var isPermissionDenied = false
    
    init() {
        checkPermissionStatus()
    }
    
    func checkPermissionStatus() {
        permissionStatus = AVAudioSession.sharedInstance().recordPermission
        isPermissionDenied = permissionStatus == .denied
    }
    
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.permissionStatus = granted ? .granted : .denied
                    self.isPermissionDenied = !granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    var hasPermission: Bool {
        return permissionStatus == .granted
    }
    
    var needsPermission: Bool {
        return permissionStatus == .undetermined
    }
}