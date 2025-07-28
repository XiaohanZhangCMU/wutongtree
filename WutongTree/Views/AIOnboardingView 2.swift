import SwiftUI

struct AIOnboardingView: View {
    @Binding var user: User
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = OnboardingInterviewViewModel()
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    Text("🌳 Welcome to WutongTree")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Let's get to know you through a quick chat with MoMo")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Chat Area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isTyping {
                                TypingIndicatorView()
                                    .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isTyping) { isTyping in
                        if isTyping {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area
                if !viewModel.isComplete {
                    VStack(spacing: 12) {
                        // Photo upload for first question
                        if viewModel.currentQuestionIndex == 0 && !viewModel.messages.isEmpty {
                            photoUploadSection
                        }
                        
                        inputSection
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 1, y: -1)
                } else {
                    completionSection
                }
            }
            .navigationTitle("AI Interview")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        skipToTraditionalOnboarding()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $profileImage)
        }
    }
    
    private var photoUploadSection: some View {
        VStack(spacing: 12) {
            Text("📸 Add your photo (optional)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingImagePicker = true
            }) {
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.green, lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }
    
    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Type your response...", text: $viewModel.currentUserInput, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...3)
                .disabled(viewModel.isTyping)
            
            Button(action: {
                viewModel.submitResponse()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(canSend ? .green : .gray)
            }
            .disabled(!canSend || viewModel.isTyping)
        }
    }
    
    private var completionSection: some View {
        VStack(spacing: 20) {
            Text("🎉 Interview Complete!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your profile is ready! Let's start finding great conversations for you.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Continue to WutongTree") {
                completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var canSend: Bool {
        !viewModel.currentUserInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func completeOnboarding() {
        let userData = viewModel.extractUserData()
        
        user.name = userData.name
        user.age = userData.age
        user.interests = userData.interests
        user.lookingFor = userData.lookingFor
        user.onboardingCompleted = true
        
        dismiss()
    }
    
    private func skipToTraditionalOnboarding() {
        // For now, just skip completely
        // Could navigate to traditional onboarding if desired
        user.onboardingCompleted = true
        dismiss()
    }
}

struct MessageBubbleView: View {
    let message: OnboardingMessage
    
    var body: some View {
        HStack {
            if message.isFromAI {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Text("MoMo")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                    
                    Text(message.content)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("You")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Text(message.content)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    Text("MoMo")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
                
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                            .scaleEffect(animationAmount)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animationAmount
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(16)
            }
            Spacer()
        }
        .onAppear {
            animationAmount = 1.0
        }
    }
}

#Preview {
    AIOnboardingView(user: .constant(User(
        id: "test",
        email: "test@test.com",
        name: "Test",
        interests: [],
        onboardingCompleted: false,
        subscriptionType: .free
    )))
}