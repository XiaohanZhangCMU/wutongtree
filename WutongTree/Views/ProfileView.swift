import SwiftUI

struct ProfileView: View {
    @State private var user = User(
        id: "test",
        email: "test@example.com",
        name: "Test User",
        age: 25,
        interests: ["Technology", "Philosophy", "Music"],
        lookingFor: "Deep philosophical discussions",
        onboardingCompleted: true,
        subscriptionType: .free
    )
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    
                    subscriptionCard
                    
                    profileDetails
                    
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(user: $user)
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 15) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                )
            
            VStack(spacing: 5) {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let age = user.age {
                    Text("\(age) years old")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var subscriptionCard: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: user.subscriptionType == .premium ? "crown.fill" : "gift.fill")
                    .foregroundColor(user.subscriptionType == .premium ? .yellow : .orange)
                
                Text(user.subscriptionType.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            if user.subscriptionType == .free {
                HStack {
                    Text("Upgrade to Premium for unlimited conversations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Upgrade") {
                        // Handle upgrade
                    }
                    .font(.caption)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var profileDetails: some View {
        VStack(spacing: 20) {
            DetailSection(title: "Interests", content: user.interests.joined(separator: ", "))
            
            if let lookingFor = user.lookingFor {
                DetailSection(title: "Looking For", content: lookingFor)
            }
            
            DetailSection(title: "Member Since", content: "January 2024")
            
            DetailSection(title: "Conversations", content: "12 completed")
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button("View Conversation History") {
                // Navigate to history
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            Button("Share Profile") {
                // Share profile
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            Button("Sign Out") {
                // Sign out
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
        }
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EditProfileView: View {
    @Binding var user: User
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var age: String
    @State private var interests: Set<String>
    @State private var lookingFor: String
    
    init(user: Binding<User>) {
        self._user = user
        self._name = State(initialValue: user.wrappedValue.name)
        self._age = State(initialValue: String(user.wrappedValue.age ?? 0))
        self._interests = State(initialValue: Set(user.wrappedValue.interests))
        self._lookingFor = State(initialValue: user.wrappedValue.lookingFor ?? "")
    }
    
    private let availableInterests = [
        "Politics", "Philosophy", "Technology", "Art", "Music", "Sports",
        "Science", "Literature", "Travel", "Food", "Movies", "Gaming"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                }
                
                Section("Interests") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(availableInterests, id: \.self) { interest in
                            InterestTag(
                                title: interest,
                                isSelected: interests.contains(interest)
                            ) {
                                if interests.contains(interest) {
                                    interests.remove(interest)
                                } else {
                                    interests.insert(interest)
                                }
                            }
                        }
                    }
                }
                
                Section("Looking For") {
                    TextField("What type of conversations do you enjoy?", text: $lookingFor, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        user.name = name
        user.age = Int(age)
        user.interests = Array(interests)
        user.lookingFor = lookingFor
    }
}

#Preview {
    ProfileView()
}