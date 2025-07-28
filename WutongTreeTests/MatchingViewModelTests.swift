import XCTest
import Combine
@testable import WutongTree

final class MatchingViewModelTests: XCTestCase {
    var viewModel: MatchingViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = MatchingViewModel()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel.cancelSearch()
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertFalse(viewModel.isMatched)
        XCTAssertNil(viewModel.currentMatch)
        XCTAssertEqual(viewModel.estimatedWaitTime, 0)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testFindMatchStartsSearch() {
        viewModel.findMatch()
        
        XCTAssertTrue(viewModel.isSearching)
        XCTAssertFalse(viewModel.isMatched)
        XCTAssertNil(viewModel.currentMatch)
        XCTAssertGreaterThan(viewModel.estimatedWaitTime, 0)
        XCTAssertLessThanOrEqual(viewModel.estimatedWaitTime, 120) // Max 2 minutes as per spec
        XCTAssertGreaterThanOrEqual(viewModel.estimatedWaitTime, 30) // Min 30 seconds as per spec
    }
    
    func testMatchingCompletes() {
        let expectation = XCTestExpectation(description: "Matching completes")
        
        // Subscribe to matching completion
        viewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.findMatch()
        
        // Wait for match to complete (max wait time + buffer)
        wait(for: [expectation], timeout: 125.0)
        
        XCTAssertTrue(viewModel.isMatched)
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertNotNil(viewModel.currentMatch)
        
        // Verify matched user properties
        let match = viewModel.currentMatch!
        XCTAssertFalse(match.id.isEmpty)
        XCTAssertFalse(match.name.isEmpty)
        XCTAssertTrue(match.onboardingCompleted)
        XCTAssertGreaterThan(match.interests.count, 0)
    }
    
    func testCancelSearch() {
        viewModel.findMatch()
        
        XCTAssertTrue(viewModel.isSearching)
        
        viewModel.cancelSearch()
        
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertFalse(viewModel.isMatched)
        XCTAssertNil(viewModel.currentMatch)
    }
    
    func testAcceptMatch() {
        // First complete a match
        let matchExpectation = XCTestExpectation(description: "Match found")
        
        viewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched {
                    matchExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.findMatch()
        wait(for: [matchExpectation], timeout: 125.0)
        
        // Then accept the match
        viewModel.acceptMatch()
        
        // Verify match is still active (user proceeds to chat room)
        XCTAssertTrue(viewModel.isMatched)
        XCTAssertNotNil(viewModel.currentMatch)
    }
    
    func testDeclineMatch() {
        // First complete a match
        let matchExpectation = XCTestExpectation(description: "Match found")
        
        viewModel.$isMatched
            .dropFirst()
            .sink { isMatched in
                if isMatched {
                    matchExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.findMatch()
        wait(for: [matchExpectation], timeout: 125.0)
        
        // Then decline the match
        viewModel.declineMatch()
        
        // Verify match is cleared
        XCTAssertFalse(viewModel.isMatched)
        XCTAssertNil(viewModel.currentMatch)
    }
    
    func testMultipleMatchAttempts() {
        // Test that we can search multiple times
        viewModel.findMatch()
        XCTAssertTrue(viewModel.isSearching)
        
        viewModel.cancelSearch()
        XCTAssertFalse(viewModel.isSearching)
        
        viewModel.findMatch()
        XCTAssertTrue(viewModel.isSearching)
        
        viewModel.cancelSearch()
    }
    
    func testMatchQuality() {
        let expectation = XCTestExpectation(description: "Match quality check")
        
        viewModel.$currentMatch
            .compactMap { $0 }
            .sink { match in
                // Verify match meets quality requirements from spec
                XCTAssertTrue(match.age ?? 0 >= 18, "Matched user should be adult")
                XCTAssertGreaterThan(match.interests.count, 0, "Matched user should have interests")
                XCTAssertNotNil(match.lookingFor, "Matched user should have conversation goals")
                XCTAssertTrue(match.onboardingCompleted, "Matched user should have completed onboarding")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.findMatch()
        wait(for: [expectation], timeout: 125.0)
    }
}