import Foundation

struct User: Codable, Identifiable {
    let id: String
    var email: String
    var name: String
    var age: Int?
    var profileImageURL: String?
    var interests: [String]
    var lookingFor: String?
    var onboardingCompleted: Bool
    var subscriptionType: SubscriptionType
    
    enum SubscriptionType: String, Codable, CaseIterable {
        case free = "free"
        case premium = "premium"
        
        var displayName: String {
            switch self {
            case .free:
                return "Free (7 days)"
            case .premium:
                return "Premium ($10/month)"
            }
        }
    }
}

struct UserProfile: Codable {
    var bio: String?
    var relationshipGoals: [String]
    var personalityTraits: [String]
    var voiceAnalysisCompleted: Bool
    var matchPreferences: MatchPreferences
}

struct MatchPreferences: Codable {
    var ageRange: ClosedRange<Int>
    var maxDistance: Double
    var interests: [String]
    var conversationTopics: [String]
}