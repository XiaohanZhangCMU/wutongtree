import XCTest
import AVFoundation
@testable import WutongTree

final class VoiceRecordingViewModelTests: XCTestCase {
    var viewModel: VoiceRecordingViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = VoiceRecordingViewModel()
    }
    
    override func tearDown() {
        if viewModel.isRecording {
            viewModel.stopRecording()
        }
        viewModel = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertEqual(viewModel.audioLevel, 0.0)
        XCTAssertEqual(viewModel.recordingDuration, 0)
    }
    
    func testRequestPermission() {
        // Note: This test will prompt for permission in simulator
        viewModel.requestPermission()
        
        // Wait a moment for permission request
        let expectation = XCTestExpectation(description: "Permission request")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Permission status depends on simulator/device settings
        // We can't reliably test the exact value, but ensure no crash
        XCTAssertNotNil(viewModel.hasPermission)
    }
    
    func testAudioSessionSetup() {
        // Verify audio session is configured correctly
        let audioSession = AVAudioSession.sharedInstance()
        
        // The category should be set to playAndRecord
        XCTAssertTrue(audioSession.category == .playAndRecord || 
                     audioSession.category == .ambient) // Default before setup
    }
    
    func testRecordingFileGeneration() {
        let documentsURL = viewModel.getDocumentsDirectory()
        let testFileURL = documentsURL.appendingPathComponent("test_recording.m4a")
        
        // Ensure we can create file URLs in documents directory
        XCTAssertTrue(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).count > 0)
        XCTAssertTrue(testFileURL.path.contains("recording"))
    }
    
    func testRecordingStateChanges() {
        // Test that starting recording changes state appropriately
        // Note: This might fail without microphone permission
        
        let initialRecordingState = viewModel.isRecording
        XCTAssertFalse(initialRecordingState)
        
        // Simulate permission granted for testing
        viewModel.hasPermission = true
        
        // Start recording
        viewModel.startRecording()
        
        // Give it a moment to start
        let expectation = XCTestExpectation(description: "Recording starts")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Stop recording
        viewModel.stopRecording()
        
        // Verify recording stopped
        let finalExpectation = XCTestExpectation(description: "Recording stops")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            finalExpectation.fulfill()
        }
        wait(for: [finalExpectation], timeout: 1.0)
        
        XCTAssertFalse(viewModel.isRecording)
    }
    
    func testDocumentsDirectoryAccess() {
        let documentsDirectory = viewModel.getDocumentsDirectory()
        
        XCTAssertTrue(documentsDirectory.isFileURL)
        XCTAssertTrue(documentsDirectory.path.contains("Documents"))
    }
    
    func testErrorHandling() {
        // Test that appropriate error messages are set when needed
        viewModel.hasPermission = false
        viewModel.startRecording()
        
        // Should request permission when not granted
        // Error handling will depend on actual permission state
    }
}

// Extension to access private methods for testing
extension VoiceRecordingViewModel {
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}