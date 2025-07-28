import Foundation
import Combine

class MatchingViewModel: ObservableObject {
    @Published var isSearching = false
    @Published var isMatched = false
    @Published var currentMatch: User?
    @Published var estimatedWaitTime: TimeInterval = 0
    @Published var errorMessage: String?
    @Published var timeLeftToJoin: Int = 300 // 5 minutes in seconds
    @Published var matchExpired = false
    
    private var searchTimer: Timer?
    private var joinTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    func findMatch() {
        isSearching = true
        isMatched = false
        estimatedWaitTime = Double.random(in: 3...8) // 3-8 seconds for testing
        
        // Simulate matching process
        searchTimer = Timer.scheduledTimer(withTimeInterval: estimatedWaitTime, repeats: false) { [weak self] _ in
            self?.completeMatch()
        }
    }
    
    private func completeMatch() {
        // Simulate finding a match
        let matchedUser = User(
            id: UUID().uuidString,
            email: "match@example.com",
            name: "Alex", // Fixed name to avoid confusion
            age: Int.random(in: 20...35),
            profileImageURL: nil,
            interests: ["Politics", "Philosophy", "Technology", "Art", "Music"].shuffled().prefix(3).map { String($0) },
            lookingFor: "Meaningful conversations",
            onboardingCompleted: true,
            subscriptionType: .premium
        )
        
        DispatchQueue.main.async {
            self.currentMatch = matchedUser
            self.isMatched = true
            self.isSearching = false
            self.startJoinTimer()
        }
    }
    
    private func startJoinTimer() {
        timeLeftToJoin = 300 // Reset to 5 minutes
        matchExpired = false
        
        joinTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.timeLeftToJoin -= 1
            
            if self.timeLeftToJoin <= 0 {
                self.joinTimer?.invalidate()
                self.joinTimer = nil
                self.matchExpired = true
                self.isMatched = false
                self.currentMatch = nil
            }
        }
    }
    
    func cancelSearch() {
        searchTimer?.invalidate()
        searchTimer = nil
        joinTimer?.invalidate()
        joinTimer = nil
        isSearching = false
        isMatched = false
        currentMatch = nil
        matchExpired = false
    }
    
    func acceptMatch() {
        // Stop the join timer when entering chat room
        joinTimer?.invalidate()
        joinTimer = nil
        print("Match accepted, proceeding to chat room")
    }
    
    func declineMatch() {
        joinTimer?.invalidate()
        joinTimer = nil
        isMatched = false
        currentMatch = nil
        matchExpired = false
    }
    
    func formatTimeLeft() -> String {
        let minutes = timeLeftToJoin / 60
        let seconds = timeLeftToJoin % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}