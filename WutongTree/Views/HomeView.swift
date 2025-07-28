import SwiftUI

struct HomeView: View {
    @EnvironmentObject var voiceViewModel: VoiceRecordingViewModel
    @EnvironmentObject var matchingViewModel: MatchingViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingOnboarding = false
    @State private var showingChatRoom = false
    @State private var showingFeedback = false
    @State private var completedConversation: ConversationRecord?
    
    private var currentUser: User {
        return authViewModel.currentUser ?? User(
            id: "temp",
            email: "",
            name: "User",
            interests: [],
            onboardingCompleted: false,
            subscriptionType: .free
        )
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                headerView
                
                Spacer()
                
                if !currentUser.onboardingCompleted {
                    onboardingPrompt
                } else if matchingViewModel.matchExpired {
                    matchExpiredView
                } else if matchingViewModel.isMatched {
                    chatRoomButton
                } else {
                    microphoneButton
                }
                
                Spacer()
                
                statusText
            }
            .padding()
            .navigationTitle("WutongTree")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(user: Binding(
                    get: { currentUser },
                    set: { updatedUser in
                        authViewModel.currentUser = updatedUser
                        if let userData = try? JSONEncoder().encode(updatedUser) {
                            UserDefaults.standard.set(userData, forKey: "currentUser")
                        }
                    }
                ))
            }
            .sheet(isPresented: $showingChatRoom, onDismiss: {
                // Create conversation record for feedback
                if let match = matchingViewModel.currentMatch {
                    completedConversation = ConversationRecord(
                        id: UUID().uuidString,
                        partnerName: match.name,
                        topic: match.lookingFor ?? "General conversation",
                        duration: Int.random(in: 600...2400), // Simulate conversation duration
                        date: Date(),
                        rating: 0,
                        hasRecording: Bool.random() // Simulate recording state
                    )
                    showingFeedback = true
                }
                // Reset matching state when chat room is dismissed
                matchingViewModel.cancelSearch()
            }) {
                if let match = matchingViewModel.currentMatch {
                    ChatRoomView(chatRoom: ChatRoom(
                        id: UUID().uuidString,
                        participants: [currentUser, match],
                        aiHost: AIHost(personality: .friendly),
                        isActive: true,
                        startTime: Date(),
                        recordingEnabled: false
                    ))
                }
            }
            .onReceive(voiceViewModel.$recordingCompleted) { completed in
                if completed && voiceViewModel.recordingData != nil {
                    // Recording completed successfully, start matching
                    matchingViewModel.findMatch()
                }
            }
            .sheet(isPresented: $showingFeedback) {
                if let conversation = completedConversation {
                    FeedbackView(conversationRecord: conversation)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 10) {
            Text("Welcome back, \(currentUser.name)!")
                .font(.title2)
                .fontWeight(.semibold)
            
            if currentUser.subscriptionType == .free {
                Text("Free trial: 7 days remaining")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var onboardingPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Complete Your Profile")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Answer a few questions to get matched with the perfect conversation partner")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Start Onboarding") {
                showingOnboarding = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var microphoneButton: some View {
        VStack(spacing: 20) {
            Button(action: {
                if voiceViewModel.isRecording {
                    voiceViewModel.stopRecording()
                } else {
                    voiceViewModel.recordingCompleted = false
                    voiceViewModel.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(voiceViewModel.isRecording ? Color.red : Color.green)
                        .frame(width: 200, height: 200)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 8)
                        )
                        .scaleEffect(voiceViewModel.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: voiceViewModel.isRecording)
                    
                    Image(systemName: voiceViewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
            }
            .disabled(matchingViewModel.isSearching)
            .accessibilityIdentifier("microphone_button")
            
            Text(voiceViewModel.isRecording ? "Tap to stop recording" : "Tap to start talking")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private var chatRoomButton: some View {
        VStack(spacing: 20) {
            Text("Match Found! 🎉")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Button("Enter Chat Room") {
                matchingViewModel.acceptMatch()
                showingChatRoom = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.headline)
            
            Text("Time left: \(matchingViewModel.formatTimeLeft())")
                .font(.caption)
                .foregroundColor(matchingViewModel.timeLeftToJoin < 60 ? .red : .orange)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var matchExpiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Match Expired")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
            
            Text("You didn't join the chat room within 5 minutes. Try finding a new match!")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Find New Match") {
                matchingViewModel.cancelSearch()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var statusText: some View {
        VStack(spacing: 8) {
            if matchingViewModel.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finding your perfect match...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else if voiceViewModel.isRecording {
                Text("Tell me what you'd like to talk about today...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if currentUser.onboardingCompleted {
                Text("Ready to start a conversation?")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(VoiceRecordingViewModel())
        .environmentObject(MatchingViewModel())
        .environmentObject(AuthenticationViewModel())
}