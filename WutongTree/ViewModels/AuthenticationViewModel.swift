import Foundation
import Combine

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        // Mock Apple Sign-In for personal developer accounts
        // Real Apple Sign-In requires paid Apple Developer Program membership
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let mockUser = User(
                id: UUID().uuidString,
                email: "apple@user.com",
                name: "Apple User",
                interests: [],
                onboardingCompleted: false,
                subscriptionType: .free
            )
            self.saveUserAndAuthenticate(user: mockUser)
        }
    }
    
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let mockUser = User(
                id: UUID().uuidString,
                email: "user@gmail.com",
                name: "Test User",
                interests: [],
                onboardingCompleted: false,
                subscriptionType: .free
            )
            self.saveUserAndAuthenticate(user: mockUser)
        }
    }
    
    func signInWithFacebook() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let mockUser = User(
                id: UUID().uuidString,
                email: "user@facebook.com",
                name: "Test User",
                interests: [],
                onboardingCompleted: false,
                subscriptionType: .free
            )
            self.saveUserAndAuthenticate(user: mockUser)
        }
    }
    
    private func saveUserAndAuthenticate(user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        DispatchQueue.main.async {
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        currentUser = nil
        isAuthenticated = false
    }
}