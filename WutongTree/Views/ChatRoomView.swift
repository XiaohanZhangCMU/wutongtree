import SwiftUI
import AVFoundation

struct ChatRoomView: View {
    @StateObject private var chatRoomViewModel = ChatRoomViewModel()
    @State private var isRecording = false
    @State private var showingEndDialog = false
    @Environment(\.dismiss) private var dismiss
    
    let chatRoom: ChatRoom
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                participantsHeader
                
                messagesArea
                
                audioControls
            }
            .navigationTitle("WutongTree Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Leave") {
                        showingEndDialog = true
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(chatRoom.recordingEnabled ? "Stop Recording" : "Start Recording") {
                        chatRoomViewModel.toggleRecording()
                    }
                    .foregroundColor(chatRoom.recordingEnabled ? .red : .green)
                }
            }
            .alert("End Conversation?", isPresented: $showingEndDialog) {
                Button("Cancel", role: .cancel) { }
                Button("End", role: .destructive) {
                    chatRoomViewModel.endConversation()
                    dismiss()
                }
            } message: {
                Text("This will end the conversation for all participants.")
            }
        }
        .onAppear {
            chatRoomViewModel.setup(chatRoom: chatRoom)
        }
    }
    
    private var participantsHeader: some View {
        HStack(spacing: 15) {
            ForEach(chatRoom.participants, id: \.id) { participant in
                ParticipantView(
                    participant: participant,
                    isSpeaking: chatRoomViewModel.speakingParticipants.contains(participant.id),
                    audioLevel: chatRoomViewModel.audioLevels[participant.id] ?? 0
                )
            }
            
            // AI Host (MoMo)
            ParticipantView(
                participant: User(
                    id: chatRoom.aiHost.id,
                    email: "",
                    name: chatRoom.aiHost.name,
                    interests: [],
                    onboardingCompleted: true,
                    subscriptionType: .premium
                ),
                isSpeaking: chatRoomViewModel.speakingParticipants.contains(chatRoom.aiHost.id),
                audioLevel: chatRoomViewModel.audioLevels[chatRoom.aiHost.id] ?? 0,
                isAI: true
            )
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(chatRoomViewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: chatRoomViewModel.messages.count) { _ in
                if let lastMessage = chatRoomViewModel.messages.last {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var audioControls: some View {
        VStack(spacing: 15) {
            if chatRoom.recordingEnabled {
                HStack {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    
                    Text("Recording in progress")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    Text(formatDuration(chatRoomViewModel.recordingDuration))
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 30) {
                // Mute button
                Button(action: {
                    chatRoomViewModel.toggleMute()
                }) {
                    Image(systemName: chatRoomViewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.title)
                        .foregroundColor(chatRoomViewModel.isMuted ? .red : .primary)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color(.systemGray5)))
                }
                
                // Speaker button
                Button(action: {
                    chatRoomViewModel.toggleSpeaker()
                }) {
                    Image(systemName: chatRoomViewModel.speakerOn ? "speaker.wave.3.fill" : "speaker.fill")
                        .font(.title)
                        .foregroundColor(.primary)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color(.systemGray5)))
                }
                
                // Volume indicator
                VStack {
                    Text("Volume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VolumeIndicator(level: chatRoomViewModel.currentVolumeLevel)
                        .frame(width: 60, height: 30)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct ParticipantView: View {
    let participant: User
    let isSpeaking: Bool
    let audioLevel: Float
    let isAI: Bool
    
    init(participant: User, isSpeaking: Bool, audioLevel: Float, isAI: Bool = false) {
        self.participant = participant
        self.isSpeaking = isSpeaking
        self.audioLevel = audioLevel
        self.isAI = isAI
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isAI ? Color.purple.opacity(0.3) : Color.blue.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(isSpeaking ? Color.green : Color.clear, lineWidth: 4)
                            .scaleEffect(isSpeaking ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSpeaking)
                    )
                
                if isAI {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                } else {
                    Text(String(participant.name.prefix(1)))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            Text(participant.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            if isSpeaking {
                AudioWaveform(level: audioLevel)
                    .frame(width: 40, height: 8)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 40, height: 8)
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.senderID != "current_user" {
                Spacer()
            }
            
            VStack(alignment: message.senderID == "current_user" ? .trailing : .leading, spacing: 4) {
                if message.senderID != "current_user" {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(bubbleColor)
                    )
                    .foregroundColor(textColor)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.senderID == "current_user" {
                Spacer()
            }
        }
    }
    
    private var bubbleColor: Color {
        switch message.messageType {
        case .aiGenerated:
            return Color.purple.opacity(0.2)
        case .system:
            return Color.gray.opacity(0.2)
        default:
            return message.senderID == "current_user" ? Color.blue : Color.gray.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        switch message.messageType {
        case .system:
            return .secondary
        default:
            return message.senderID == "current_user" ? .white : .primary
        }
    }
}

struct AudioWaveform: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.green)
                    .frame(width: 3, height: CGFloat(level * 8 * Float(index + 1) / 5))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
}

struct VolumeIndicator: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<10, id: \.self) { index in
                    Rectangle()
                        .fill(index < Int(level * 10) ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: (geometry.size.width - 18) / 10, height: geometry.size.height)
                }
            }
        }
    }
}

#Preview {
    ChatRoomView(chatRoom: ChatRoom(
        id: "test",
        participants: [
            User(id: "1", email: "user1@test.com", name: "Alice", interests: [], onboardingCompleted: true, subscriptionType: .free),
            User(id: "2", email: "user2@test.com", name: "Bob", interests: [], onboardingCompleted: true, subscriptionType: .premium)
        ],
        aiHost: AIHost(personality: .friendly),
        isActive: true,
        startTime: Date(),
        recordingEnabled: false
    ))
}