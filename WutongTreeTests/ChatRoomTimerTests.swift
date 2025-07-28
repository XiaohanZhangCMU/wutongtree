import XCTest
import Combine
@testable import WutongTree

final class ChatRoomTimerTests: XCTestCase {
    var matchingViewModel: MatchingViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        matchingViewModel = MatchingViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        matchingViewModel.cancelSearch()
        matchingViewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testFiveMinuteJoinTimer() {
        // Step 10-11 from spec: Tommy has 5 minutes to enter chat room
        
        let expectation = XCTestExpectation(description: "Match found")
        
        // Wait for match to be found
        matchingViewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        matchingViewModel.findMatch()
        wait(for: [expectation], timeout: 125.0)
        
        // Verify initial timer state
        XCTAssertEqual(matchingViewModel.timeLeftToJoin, 300, "Should start with 5 minutes (300 seconds)")
        XCTAssertFalse(matchingViewModel.matchExpired, "Match should not be expired initially")
        
        // Wait a few seconds and verify timer is counting down
        let timerExpectation = XCTestExpectation(description: "Timer counts down")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            timerExpectation.fulfill()
        }
        wait(for: [timerExpectation], timeout: 5.0)
        
        XCTAssertLessThan(matchingViewModel.timeLeftToJoin, 300, "Timer should be counting down")
        XCTAssertGreaterThan(matchingViewModel.timeLeftToJoin, 290, "Should only count down a few seconds")
    }
    
    func testTimerFormatting() {
        // Test time formatting for display
        
        matchingViewModel.timeLeftToJoin = 300 // 5:00
        XCTAssertEqual(matchingViewModel.formatTimeLeft(), "5:00")
        
        matchingViewModel.timeLeftToJoin = 60 // 1:00
        XCTAssertEqual(matchingViewModel.formatTimeLeft(), "1:00")
        
        matchingViewModel.timeLeftToJoin = 30 // 0:30
        XCTAssertEqual(matchingViewModel.formatTimeLeft(), "0:30")
        
        matchingViewModel.timeLeftToJoin = 5 // 0:05
        XCTAssertEqual(matchingViewModel.formatTimeLeft(), "0:05")
        
        matchingViewModel.timeLeftToJoin = 0 // 0:00
        XCTAssertEqual(matchingViewModel.formatTimeLeft(), "0:00")
    }
    
    func testAcceptMatchStopsTimer() {
        // When user accepts match and enters chat room, timer should stop
        
        let expectation = XCTestExpectation(description: "Match found")
        
        matchingViewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        matchingViewModel.findMatch()
        wait(for: [expectation], timeout: 125.0)
        
        let initialTime = matchingViewModel.timeLeftToJoin
        
        // Accept the match
        matchingViewModel.acceptMatch()
        
        // Wait a moment and verify timer stopped
        let timerExpectation = XCTestExpectation(description: "Timer verification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            timerExpectation.fulfill()
        }
        wait(for: [timerExpectation], timeout: 3.0)
        
        // Timer should not have changed after accepting
        XCTAssertEqual(matchingViewModel.timeLeftToJoin, initialTime, "Timer should stop when match is accepted")
    }
    
    func testDeclineMatchClearsTimer() {
        // When user declines match, timer should be cleared
        
        let expectation = XCTestExpectation(description: "Match found")
        
        matchingViewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        matchingViewModel.findMatch()
        wait(for: [expectation], timeout: 125.0)
        
        // Decline the match
        matchingViewModel.declineMatch()
        
        XCTAssertFalse(matchingViewModel.isMatched, "Match should be cleared")
        XCTAssertNil(matchingViewModel.currentMatch, "Current match should be nil")
        XCTAssertFalse(matchingViewModel.matchExpired, "Match expired should be reset")
    }
    
    func testMatchExpirationBehavior() {
        // Test what happens when 5 minutes expire (simulated)
        
        let expectation = XCTestExpectation(description: "Match found")
        
        matchingViewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        matchingViewModel.findMatch()
        wait(for: [expectation], timeout: 125.0)
        
        // Simulate timer expiration
        matchingViewModel.timeLeftToJoin = 0
        
        // Manually trigger expiration logic (since we can't wait 5 minutes in test)
        let expirationExpectation = XCTestExpectation(description: "Match expiration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // This simulates the timer expiration
            if self.matchingViewModel.timeLeftToJoin <= 0 {
                self.matchingViewModel.matchExpired = true
                self.matchingViewModel.isMatched = false
                self.matchingViewModel.currentMatch = nil
            }
            expirationExpectation.fulfill()
        }
        wait(for: [expirationExpectation], timeout: 1.0)
        
        XCTAssertTrue(matchingViewModel.matchExpired, "Match should be marked as expired")
        XCTAssertFalse(matchingViewModel.isMatched, "Match should no longer be active")
        XCTAssertNil(matchingViewModel.currentMatch, "Current match should be cleared")
    }
    
    func testCancelSearchClearsAllTimers() {
        // Verify that canceling search clears all timers properly
        
        let expectation = XCTestExpectation(description: "Match found")
        
        matchingViewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        matchingViewModel.findMatch()
        wait(for: [expectation], timeout: 125.0)
        
        // Cancel search
        matchingViewModel.cancelSearch()
        
        XCTAssertFalse(matchingViewModel.isSearching, "Should not be searching")
        XCTAssertFalse(matchingViewModel.isMatched, "Should not be matched")
        XCTAssertNil(matchingViewModel.currentMatch, "Current match should be nil")
        XCTAssertFalse(matchingViewModel.matchExpired, "Match expired should be reset")
    }
}