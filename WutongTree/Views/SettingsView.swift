import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var voiceQuality = "High"
    @State private var autoRecord = false
    @State private var darkMode = false
    @State private var showingSubscription = false
    @State private var showingSupport = false
    
    private let voiceQualityOptions = ["Low", "Medium", "High"]
    
    var body: some View {
        NavigationView {
            List {
                subscriptionSection
                
                notificationSection
                
                audioSection
                
                privacySection
                
                supportSection
                
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
        .sheet(isPresented: $showingSupport) {
            SupportView()
        }
    }
    
    private var subscriptionSection: some View {
        Section {
            Button(action: {
                showingSubscription = true
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading) {
                        Text("Upgrade to Premium")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Unlimited conversations • Advanced features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var notificationSection: some View {
        Section("Notifications") {
            Toggle("Push Notifications", isOn: $notificationsEnabled)
            
            NavigationLink("Notification Preferences") {
                NotificationPreferencesView()
            }
        }
    }
    
    private var audioSection: some View {
        Section("Audio & Voice") {
            Picker("Voice Quality", selection: $voiceQuality) {
                ForEach(voiceQualityOptions, id: \.self) { quality in
                    Text(quality).tag(quality)
                }
            }
            
            Toggle("Auto-record Conversations", isOn: $autoRecord)
            
            NavigationLink("Voice Settings") {
                VoiceSettingsView()
            }
        }
    }
    
    private var privacySection: some View {
        Section("Privacy & Safety") {
            NavigationLink("Privacy Policy") {
                WebView(url: "https://wutongtree.com/privacy")
            }
            
            NavigationLink("Data Management") {
                DataManagementView()
            }
            
            NavigationLink("Blocked Users") {
                BlockedUsersView()
            }
        }
    }
    
    private var supportSection: some View {
        Section("Support") {
            Button("Help Center") {
                showingSupport = true
            }
            
            NavigationLink("Contact Us") {
                ContactView()
            }
            
            NavigationLink("Report a Problem") {
                ReportView()
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            
            NavigationLink("Terms of Service") {
                WebView(url: "https://wutongtree.com/terms")
            }
            
            NavigationLink("Open Source Licenses") {
                LicensesView()
            }
            
            Button("Sign Out") {
                // Handle sign out
            }
            .foregroundColor(.red)
        }
    }
}

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .monthly
    
    enum SubscriptionPlan: CaseIterable {
        case monthly
        case annual
        
        var title: String {
            switch self {
            case .monthly:
                return "Monthly"
            case .annual:
                return "Annual"
            }
        }
        
        var price: String {
            switch self {
            case .monthly:
                return "$10/month"
            case .annual:
                return "$120/year"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly:
                return nil
            case .annual:
                return "Save 25%"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                headerView
                
                featuresView
                
                planSelector
                
                Spacer()
                
                subscribeButton
            }
            .padding()
            .navigationTitle("WutongTree Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 15) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Unlock Premium Features")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Get unlimited conversations and exclusive features")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 15) {
            FeatureRow(icon: "infinity", title: "Unlimited Conversations", description: "No daily limits")
            FeatureRow(icon: "mic.badge.plus", title: "Advanced Voice Analysis", description: "Better personality matching")
            FeatureRow(icon: "star.fill", title: "Priority Matching", description: "Faster match times")
            FeatureRow(icon: "cloud.fill", title: "Cloud Recording", description: "Save conversations forever")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var planSelector: some View {
        VStack(spacing: 10) {
            Text("Choose Your Plan")
                .font(.headline)
                .fontWeight(.medium)
            
            ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                Button(action: {
                    selectedPlan = plan
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.title)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            if let savings = plan.savings {
                                Text(savings)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                        
                        Text(plan.price)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Image(systemName: selectedPlan == plan ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedPlan == plan ? .green : .gray)
                    }
                    .padding()
                    .background(selectedPlan == plan ? Color.green.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedPlan == plan ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    private var subscribeButton: some View {
        VStack(spacing: 15) {
            Button("Start Premium") {
                // Handle subscription
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            
            Text("7-day free trial • Cancel anytime")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// Placeholder views for navigation
struct NotificationPreferencesView: View {
    var body: some View {
        Text("Notification Preferences")
            .navigationTitle("Notifications")
    }
}

struct VoiceSettingsView: View {
    var body: some View {
        Text("Voice Settings")
            .navigationTitle("Voice Settings")
    }
}

struct WebView: View {
    let url: String
    
    var body: some View {
        Text("Web content for: \(url)")
            .navigationTitle("Web View")
    }
}

struct DataManagementView: View {
    var body: some View {
        Text("Data Management")
            .navigationTitle("Data Management")
    }
}

struct BlockedUsersView: View {
    var body: some View {
        Text("Blocked Users")
            .navigationTitle("Blocked Users")
    }
}

struct ContactView: View {
    var body: some View {
        Text("Contact Us")
            .navigationTitle("Contact")
    }
}

struct ReportView: View {
    var body: some View {
        Text("Report a Problem")
            .navigationTitle("Report")
    }
}

struct LicensesView: View {
    var body: some View {
        Text("Open Source Licenses")
            .navigationTitle("Licenses")
    }
}

struct SupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Text("Help Center")
                .navigationTitle("Support")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    SettingsView()
}