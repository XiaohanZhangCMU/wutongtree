import XCTest
import Combine
@testable import WutongTree

final class AuthenticationViewModelTests: XCTestCase {
    var viewModel: AuthenticationViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = AuthenticationViewModel()
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing user data
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        UserDefaults.standard.removeObject(forKey: "currentUser")
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testCheckAuthenticationStatusWithNoStoredUser() {
        viewModel.checkAuthenticationStatus()
        
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
    }
    
    func testCheckAuthenticationStatusWithStoredUser() {
        // Store a mock user
        let mockUser = User(
            id: "test123",
            email: "test@example.com",
            name: "Test User",
            interests: ["Technology"],
            onboardingCompleted: true,
            subscriptionType: .free
        )
        
        if let userData = try? JSONEncoder().encode(mockUser) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        viewModel.checkAuthenticationStatus()
        
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.email, "test@example.com")
    }
    
    func testSignInWithGoogle() {
        let expectation = XCTestExpectation(description: "Sign in completes")
        
        viewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.signInWithGoogle()
        
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.email, "user@gmail.com")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testSignInWithFacebook() {
        let expectation = XCTestExpectation(description: "Sign in completes")
        
        viewModel.$isAuthenticated
            .dropFirst()
            .sink { isAuthenticated in
                if isAuthenticated {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.signInWithFacebook()
        
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.email, "user@facebook.com")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testSignOut() {
        // First sign in
        viewModel.signInWithGoogle()
        
        // Wait for sign in to complete
        let signInExpectation = XCTestExpectation(description: "Sign in completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            signInExpectation.fulfill()
        }
        wait(for: [signInExpectation], timeout: 2.0)
        
        // Then sign out
        viewModel.signOut()
        
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertNil(UserDefaults.standard.data(forKey: "currentUser"))
    }
    
    func testUserDefaultsPersistence() {
        viewModel.signInWithGoogle()
        
        // Wait for sign in to complete
        let expectation = XCTestExpectation(description: "Sign in completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Verify user is stored in UserDefaults
        let userData = UserDefaults.standard.data(forKey: "currentUser")
        XCTAssertNotNil(userData)
        
        if let userData = userData,
           let storedUser = try? JSONDecoder().decode(User.self, from: userData) {
            XCTAssertEqual(storedUser.email, "user@gmail.com")
        } else {
            XCTFail("Failed to decode stored user")
        }
    }
}