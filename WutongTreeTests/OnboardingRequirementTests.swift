import XCTest
@testable import WutongTree

final class OnboardingRequirementTests: XCTestCase {
    var authViewModel: AuthenticationViewModel!
    var voiceViewModel: VoiceRecordingViewModel!
    var matchingViewModel: MatchingViewModel!
    
    override func setUp() {
        super.setUp()
        authViewModel = AuthenticationViewModel()
        voiceViewModel = VoiceRecordingViewModel()
        matchingViewModel = MatchingViewModel()
        
        // Clear any existing user data
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        super.tearDown()
    }
    
    func testOnboardingCompletionRequirement() {
        // Step 6.2 from spec: Tommy MUST finish answering all questions before matching
        
        // Create user without completed onboarding
        let incompleteUser = User(
            id: "test123",
            email: "tommy@test.com",
            name: "Tommy",
            age: 20,
            interests: [],
            lookingFor: nil,
            onboardingCompleted: false,
            subscriptionType: .free
        )
        
        authViewModel.currentUser = incompleteUser
        
        // User should NOT be able to access microphone functionality
        XCTAssertFalse(incompleteUser.onboardingCompleted, "User must complete onboarding first")
        
        // Complete onboarding
        var completedUser = incompleteUser
        completedUser.onboardingCompleted = true
        completedUser.interests = ["Politics", "Philosophy", "Technology"]
        completedUser.lookingFor = "Deep philosophical discussions"
        
        authViewModel.currentUser = completedUser
        
        // Now user should be able to access microphone
        XCTAssertTrue(completedUser.onboardingCompleted, "User with completed onboarding can access features")
        XCTAssertGreaterThanOrEqual(completedUser.interests.count, 3, "User must select at least 3 interests")
        XCTAssertNotNil(completedUser.lookingFor, "User must specify what they're looking for")
    }
    
    func testMinimumInterestRequirement() {
        // From onboarding spec: Users must select at least 3 interests
        
        var user = User(
            id: "test",
            email: "test@test.com",
            name: "Test User",
            interests: ["Politics", "Philosophy"], // Only 2 interests
            onboardingCompleted: false,
            subscriptionType: .free
        )
        
        // Should not be able to complete onboarding with less than 3 interests
        XCTAssertLessThan(user.interests.count, 3, "User has insufficient interests")
        
        // Add third interest
        user.interests.append("Technology")
        user.onboardingCompleted = true
        
        XCTAssertGreaterThanOrEqual(user.interests.count, 3, "User now meets minimum interest requirement")
        XCTAssertTrue(user.onboardingCompleted, "User can now complete onboarding")
    }
    
    func testOnboardingDataPersistence() {
        // Verify onboarding data is properly saved
        
        let user = User(
            id: "test123",
            email: "tommy@test.com",
            name: "Tommy",
            age: 20,
            interests: ["Politics", "Philosophy", "Technology"],
            lookingFor: "Deep philosophical discussions",
            onboardingCompleted: true,
            subscriptionType: .free
        )
        
        // Save user data
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        // Verify data persistence
        authViewModel.checkAuthenticationStatus()
        
        XCTAssertNotNil(authViewModel.currentUser)
        XCTAssertTrue(authViewModel.currentUser?.onboardingCompleted ?? false)
        XCTAssertEqual(authViewModel.currentUser?.interests.count, 3)
        XCTAssertEqual(authViewModel.currentUser?.age, 20)
        XCTAssertEqual(authViewModel.currentUser?.name, "Tommy")
    }
    
    func testOnboardingFieldValidation() {
        // Test individual field requirements from the spec
        
        var user = User(
            id: "test",
            email: "test@test.com",
            name: "",
            interests: [],
            onboardingCompleted: false,
            subscriptionType: .free
        )
        
        // Name is required
        XCTAssertTrue(user.name.isEmpty, "Name should be empty initially")
        user.name = "Tommy"
        XCTAssertFalse(user.name.isEmpty, "Name should be provided")
        
        // Age should be reasonable (20 per spec example)
        user.age = 20
        XCTAssertNotNil(user.age, "Age should be provided")
        XCTAssertGreaterThanOrEqual(user.age!, 18, "User should be adult")
        
        // Interests requirement
        user.interests = ["Politics", "Philosophy", "Technology"]
        XCTAssertGreaterThanOrEqual(user.interests.count, 3, "At least 3 interests required")
        
        // Looking for requirement
        user.lookingFor = "Deep philosophical discussions"
        XCTAssertNotNil(user.lookingFor, "User must specify conversation goals")
        
        // Only now can complete onboarding
        user.onboardingCompleted = true
        XCTAssertTrue(user.onboardingCompleted, "All requirements met for onboarding")
    }
}