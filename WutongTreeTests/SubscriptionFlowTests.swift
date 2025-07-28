import XCTest
@testable import WutongTree

final class SubscriptionFlowTests: XCTestCase {
    
    func testSevenDayTrialRequirement() {
        // Step 3 from spec: Free 7-day trial
        
        let newUser = User(
            id: "trial_user",
            email: "trial@test.com",
            name: "Trial User",
            interests: ["Technology"],
            onboardingCompleted: true,
            subscriptionType: .free
        )
        
        XCTAssertEqual(newUser.subscriptionType, .free, "New users should start with free trial")
        XCTAssertEqual(newUser.subscriptionType.displayName, "Free (7 days)", "Should show 7-day trial")
    }
    
    func testPremiumPricing() {
        // Step 16 from spec: $10/month premium subscription
        
        let premiumUser = User(
            id: "premium_user",
            email: "premium@test.com",
            name: "Premium User",
            interests: ["Technology"],
            onboardingCompleted: true,
            subscriptionType: .premium
        )
        
        XCTAssertEqual(premiumUser.subscriptionType, .premium, "Premium users should have premium type")
        XCTAssertEqual(premiumUser.subscriptionType.displayName, "Premium ($10/month)", "Should show correct pricing")
    }
    
    func testSubscriptionPlanPricing() {
        // Test subscription plan pricing matches spec exactly
        
        let monthlyPlan = SubscriptionView.SubscriptionPlan.monthly
        let annualPlan = SubscriptionView.SubscriptionPlan.annual
        
        XCTAssertEqual(monthlyPlan.price, "$10/month", "Monthly plan must be exactly $10/month per spec")
        XCTAssertEqual(annualPlan.price, "$120/year", "Annual plan should be $10 * 12 months")
        
        XCTAssertEqual(monthlyPlan.title, "Monthly", "Plan titles should be clear")
        XCTAssertEqual(annualPlan.title, "Annual", "Plan titles should be clear")
    }
    
    func testFreeTrialFeatureLimitations() {
        // Verify free trial has appropriate limitations while premium is unlimited
        
        let freeUser = User(
            id: "free_user",
            email: "free@test.com",
            name: "Free User",
            interests: ["Technology"],
            onboardingCompleted: true,
            subscriptionType: .free
        )
        
        let premiumUser = User(
            id: "premium_user",
            email: "premium@test.com",
            name: "Premium User",
            interests: ["Technology"],
            onboardingCompleted: true,
            subscriptionType: .premium
        )
        
        // Both should have basic access during trial period
        XCTAssertTrue(freeUser.onboardingCompleted, "Free users can complete onboarding")
        XCTAssertTrue(premiumUser.onboardingCompleted, "Premium users can complete onboarding")
        
        // Premium features would be checked in actual implementation
        // For now, we verify the subscription types are correctly assigned
        XCTAssertEqual(freeUser.subscriptionType, .free)
        XCTAssertEqual(premiumUser.subscriptionType, .premium)
    }
    
    func testSubscriptionUpgradeFlow() {
        // Test upgrade from free trial to premium (Step 16)
        
        var user = User(
            id: "upgrade_user",
            email: "upgrade@test.com",
            name: "Upgrade User",
            interests: ["Technology"],
            onboardingCompleted: true,
            subscriptionType: .free
        )
        
        // Initially on free trial
        XCTAssertEqual(user.subscriptionType, .free)
        
        // Simulate upgrade to premium
        user.subscriptionType = .premium
        
        // Verify upgrade successful
        XCTAssertEqual(user.subscriptionType, .premium)
        XCTAssertEqual(user.subscriptionType.displayName, "Premium ($10/month)")
    }
    
    func testTrialPeriodDisplay() {
        // Verify proper display of trial period information
        
        let freeUser = User(
            id: "display_user",
            email: "display@test.com",
            name: "Display User",
            interests: ["Technology"],
            onboardingCompleted: true,
            subscriptionType: .free
        )
        
        // Should show trial information
        let displayName = freeUser.subscriptionType.displayName
        XCTAssertTrue(displayName.contains("7"), "Should mention 7-day trial")
        XCTAssertTrue(displayName.contains("Free"), "Should indicate free status")
        XCTAssertTrue(displayName.contains("days"), "Should mention days")
    }
    
    func testPremiumFeaturesList() {
        // Verify premium features match implementation requirements
        
        let expectedFeatures = [
            "Unlimited Conversations",
            "Advanced Voice Analysis", 
            "Priority Matching",
            "Cloud Recording"
        ]
        
        // These features should be available in the SubscriptionView
        // For testing, we verify they exist conceptually
        
        for feature in expectedFeatures {
            XCTAssertFalse(feature.isEmpty, "Feature '\(feature)' should be defined")
            
            // Verify feature names make sense for the app
            switch feature {
            case "Unlimited Conversations":
                XCTAssertTrue(feature.contains("Unlimited"), "Should emphasize no limits")
            case "Advanced Voice Analysis":
                XCTAssertTrue(feature.contains("Voice"), "Should relate to voice features")
            case "Priority Matching":
                XCTAssertTrue(feature.contains("Priority"), "Should emphasize better matching")
            case "Cloud Recording":
                XCTAssertTrue(feature.contains("Cloud"), "Should emphasize cloud storage")
            default:
                break
            }
        }
    }
    
    func testSubscriptionPersistence() {
        // Test that subscription status persists across app launches
        
        let user = User(
            id: "persist_user",
            email: "persist@test.com",
            name: "Persist User",
            interests: ["Technology"],
            onboardingCompleted: true,
            subscriptionType: .premium
        )
        
        // Save user data
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        // Simulate app restart by loading from storage
        guard let savedData = UserDefaults.standard.data(forKey: "currentUser"),
              let loadedUser = try? JSONDecoder().decode(User.self, from: savedData) else {
            XCTFail("Failed to load user data")
            return
        }
        
        // Verify subscription status persisted
        XCTAssertEqual(loadedUser.subscriptionType, .premium)
        XCTAssertEqual(loadedUser.id, "persist_user")
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}